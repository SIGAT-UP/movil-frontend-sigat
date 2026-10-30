import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'image_metadata.dart';
import 'models/photo_file.dart';

/// Origen desde el que se obtiene una foto.
enum PhotoSource { camara, galeria }

/// Toma o elige fotos y las VALIDA antes de devolverlas.
/// Lo usan por igual el perfil (M13-T) y las evidencias de lectura (M05-T):
/// hay un solo flujo de selección y validación en todo el proyecto.
///
/// Lanza [PhotoException] con un mensaje listo para mostrar.
/// Devuelve null si la persona cancela (no es un error).
class PhotoService {
  PhotoService._();
  static final instance = PhotoService._();

  final ImagePicker _picker = ImagePicker();

  /// En web no existe "galería" del sistema: el navegador abre el selector de
  /// archivos en ambos casos, y algunos navegadores no dan acceso a la cámara.
  bool get cameraIsFilePickerOnWeb => kIsWeb;

  Future<PhotoFile?> pick(PhotoSource source) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == PhotoSource.camara ? ImageSource.camera : ImageSource.gallery,
        imageQuality: PhotoRules.quality,
        maxWidth: PhotoRules.maxDimension,
        maxHeight: PhotoRules.maxDimension,
      );
    } on Exception catch (e) {
      throw PhotoException(_sourceError(source, e));
    }
    if (file == null) return null; // el usuario canceló
    return validate(file);
  }

  /// Lee el archivo, comprueba contenido, tipo real y tamaño, y quita los metadatos.
  Future<PhotoFile> validate(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on Exception {
      throw const PhotoException(
        'No pudimos leer la imagen. Intenta tomarla o elegirla de nuevo.',
        rejection: PhotoRejection.ilegible,
      );
    }

    if (bytes.isEmpty) {
      throw const PhotoException('El archivo está vacío.', rejection: PhotoRejection.vacio);
    }

    // El tipo se deduce del contenido, no de la extensión del nombre.
    final mime = PhotoRules.sniffMimeType(bytes);
    if (mime == null || !PhotoRules.allowedMimeTypes.contains(mime)) {
      throw PhotoException(
        'El archivo no es una imagen válida. Usa ${PhotoRules.allowedLabel}.',
        rejection: PhotoRejection.formato,
      );
    }

    if (bytes.lengthInBytes > PhotoRules.maxBytes) {
      throw PhotoException(
        'La imagen pesa ${PhotoRules.sizeLabel(bytes.lengthInBytes)} y el máximo es '
        '${PhotoRules.sizeLabel(PhotoRules.maxBytes)}.',
        rejection: PhotoRejection.tamano,
      );
    }

    // PRIVACIDAD: quita EXIF (ubicación GPS, equipo, fecha) y demás metadatos sin recodificar la
    // imagen. Si la estructura del archivo no es válida, se rechaza: puede estar dañado o manipulado.
    final limpia = ImageMetadata.strip(bytes, mime);
    if (limpia == null) {
      throw const PhotoException(
        'No pudimos procesar la imagen. Intenta tomarla o elegirla de nuevo.',
        rejection: PhotoRejection.formato,
      );
    }

    // Se devuelven los bytes SIN metadatos. `path` apunta al archivo original del selector: para
    // enviar o guardar la foto use siempre `bytes`, nunca vuelva a leer `path`.
    return PhotoFile(
      path: file.path,
      bytes: limpia,
      mimeType: mime,
      sizeBytes: limpia.lengthInBytes,
      pickedAt: DateTime.now(),
      originalName: file.name,
    );
  }

  String _sourceError(PhotoSource source, Object e) {
    final texto = e.toString().toLowerCase();
    final esPermiso = texto.contains('permission') || texto.contains('denied') || texto.contains('access');
    if (source == PhotoSource.camara) {
      return esPermiso
          ? 'La app no tiene permiso para usar la cámara. Actívalo en los ajustes del dispositivo.'
          : 'No se pudo abrir la cámara en este dispositivo.';
    }
    return esPermiso
        ? 'La app no tiene permiso para ver tus fotos. Actívalo en los ajustes del dispositivo.'
        : 'No se pudo abrir la galería en este dispositivo.';
  }
}

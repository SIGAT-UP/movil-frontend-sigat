import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'models/planning.dart';
import 'photo_service.dart';

/// Error controlado al elegir un documento. `message` ya está en español y se
/// puede mostrar tal cual.
class DocumentException implements Exception {
  const DocumentException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reglas de los documentos de instrucciones. Un solo lugar para todo el proyecto.
class DocumentRules {
  DocumentRules._();

  /// Tamaño máximo aceptado por el frontend. Ajustable según lo que exija el backend.
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB

  static const String allowedLabel = 'PDF o Word (.doc, .docx)';

  static String sizeLabel(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB'
      : '${(bytes / 1024).round()} KB';

  /// Detecta el tipo REAL leyendo el contenido. No se confía en la extensión.
  /// Devuelve null si no es un PDF ni un documento de Word.
  static DocKind? sniff(Uint8List b, String fileName) {
    if (b.length < 8) return null;
    final name = fileName.toLowerCase();

    // PDF: empieza por "%PDF-".
    if (_startsWith(b, const [0x25, 0x50, 0x44, 0x46, 0x2D])) return DocKind.pdf;

    // Word 97-2003 (.doc): contenedor OLE2. El mismo contenedor usan .xls y
    // .ppt, así que además se exige la extensión .doc.
    if (_startsWith(b, const [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]) &&
        name.endsWith('.doc')) {
      return DocKind.word;
    }

    // Word moderno (.docx): un ZIP que contiene la carpeta "word/".
    // Un .xlsx o un .zip cualquiera no la tienen.
    if (_startsWith(b, const [0x50, 0x4B, 0x03, 0x04]) && _contains(b, _wordFolder)) {
      return DocKind.word;
    }
    return null;
  }

  /// Cuenta las páginas de un PDF buscando sus objetos "/Type /Page".
  /// Es una estimación: si el PDF comprime sus objetos no se pueden contar y
  /// devuelve null (la app muestra entonces solo "PDF").
  static int? countPdfPages(Uint8List b) {
    final text = latin1.decode(b, allowInvalid: true);
    final n = RegExp(r'/Type\s*/Page(?![a-zA-Z])').allMatches(text).length;
    return n == 0 ? null : n;
  }

  static final List<int> _wordFolder = ascii.encode('word/');

  static bool _startsWith(Uint8List b, List<int> prefix) {
    if (b.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (b[i] != prefix[i]) return false;
    }
    return true;
  }

  static bool _contains(Uint8List b, List<int> needle) {
    final last = b.length - needle.length;
    for (var i = 0; i <= last; i++) {
      var ok = true;
      for (var j = 0; j < needle.length; j++) {
        if (b[i + j] != needle[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }
}

/// Elige el documento de instrucciones de la planificación.
///
/// Dos orígenes, y ninguno abre la cámara:
///  * [pickDocument]: un PDF o un Word desde los archivos del dispositivo.
///  * [pickImage]: una imagen de la galería.
///
/// Devuelve null si la persona cancela. Lanza [DocumentException] o
/// `PhotoException` con un mensaje listo para mostrar si el archivo no sirve.
class DocumentService {
  DocumentService._();
  static final instance = DocumentService._();

  static const _documentos = XTypeGroup(
    label: 'Documentos PDF o Word',
    extensions: <String>['pdf', 'doc', 'docx'],
    mimeTypes: <String>[
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
    // iOS y macOS filtran por identificador de tipo, no por extensión.
    uniformTypeIdentifiers: <String>[
      'com.adobe.pdf',
      'com.microsoft.word.doc',
      'org.openxmlformats.wordprocessingml.document',
    ],
  );

  Future<PlanningDoc?> pickDocument() async {
    XFile? archivo;
    try {
      archivo = await openFile(acceptedTypeGroups: const <XTypeGroup>[_documentos]);
    } catch (_) {
      throw const DocumentException('No se pudo abrir el selector de archivos del dispositivo.');
    }
    if (archivo == null) return null; // canceló

    Uint8List bytes;
    try {
      bytes = await archivo.readAsBytes();
    } catch (_) {
      throw const DocumentException('No se pudo leer el archivo. Elige otro.');
    }

    if (bytes.isEmpty) throw const DocumentException('El archivo está vacío.');
    if (bytes.length > DocumentRules.maxBytes) {
      throw DocumentException(
        'El archivo pesa ${DocumentRules.sizeLabel(bytes.length)}. '
        'El máximo es ${DocumentRules.sizeLabel(DocumentRules.maxBytes)}.',
      );
    }

    final tipo = DocumentRules.sniff(bytes, archivo.name);
    if (tipo == null) {
      throw const DocumentException(
        'El archivo no es un PDF ni un documento de Word válido, aunque su nombre lo diga.',
      );
    }

    return PlanningDoc(
      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
      fileName: archivo.name,
      sizeBytes: bytes.length,
      pages: tipo == DocKind.pdf ? DocumentRules.countPdfPages(bytes) : null,
      kind: tipo,
      mimeType: tipo == DocKind.pdf
          ? 'application/pdf'
          : (archivo.name.toLowerCase().endsWith('.doc')
              ? 'application/msword'
              : DocKind.word.defaultMime),
      bytes: bytes,
    );
  }

  /// Imagen de la galería, con las mismas validaciones que las evidencias
  /// (tipo por el contenido, máximo 8 MB).
  Future<PlanningDoc?> pickImage() async {
    final foto = await PhotoService.instance.pick(PhotoSource.galeria);
    if (foto == null) return null; // canceló
    return PlanningDoc(
      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
      fileName: foto.originalName ?? 'instrucciones.${foto.mimeType.split('/').last}',
      sizeBytes: foto.sizeBytes,
      pages: 1,
      kind: DocKind.imagen,
      mimeType: foto.mimeType,
      bytes: foto.bytes,
    );
  }
}

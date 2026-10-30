import 'dart:typed_data';

/// Estado de un archivo respecto al servidor.
/// La UI lo traduce a un badge; aquí no se usan widgets.
enum UploadStatus {
  /// Guardado solo en el dispositivo, todavía no se intentó enviar.
  local,

  /// Enviándose en este momento.
  uploading,

  /// El servidor confirmó que lo recibió.
  uploaded,

  /// Falló el envío; se puede reintentar.
  failed,
}

/// Motivo por el que una imagen fue rechazada.
enum PhotoRejection { formato, tamano, vacio, ilegible }

/// Error controlado al tomar o elegir una foto. `message` ya está en español
/// y es apto para mostrarse tal cual al usuario.
class PhotoException implements Exception {
  const PhotoException(this.message, {this.rejection});
  final String message;
  final PhotoRejection? rejection;
  @override
  String toString() => message;
}

/// Reglas de validación de imágenes. Un solo lugar para todo el proyecto.
class PhotoRules {
  PhotoRules._();

  /// Tamaño máximo aceptado por el frontend. Ajustable según lo que exija el backend.
  static const int maxBytes = 8 * 1024 * 1024; // 8 MB

  /// Lado mayor al que se reduce la foto al capturarla. Se conserva detalle
  /// suficiente para observar las condiciones fitosanitarias.
  static const double maxDimension = 1600;

  /// Calidad de compresión JPEG (0-100).
  static const int quality = 85;

  static const Set<String> allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  static String get allowedLabel => 'JPG, PNG o WebP';

  static String sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    return '${(bytes / 1024).round()} KB';
  }

  /// Detecta el tipo real leyendo los primeros bytes (firma del archivo).
  /// NO se confía en la extensión del nombre.
  /// Devuelve null si el contenido no corresponde a una imagen admitida.
  static String? sniffMimeType(Uint8List bytes) {
    if (bytes.length < 12) return null;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'image/jpeg';
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (_startsWith(bytes, png)) return 'image/png';
    // WebP: "RIFF" .... "WEBP"
    const riff = [0x52, 0x49, 0x46, 0x46];
    const webp = [0x57, 0x45, 0x42, 0x50];
    if (_startsWith(bytes, riff) &&
        bytes[8] == webp[0] &&
        bytes[9] == webp[1] &&
        bytes[10] == webp[2] &&
        bytes[11] == webp[3]) {
      return 'image/webp';
    }
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}

/// Imagen ya elegida y VALIDADA en el frontend, lista para previsualizar.
/// `path` es la ruta que entregó la cámara o la galería: en móvil suele ser
/// temporal, así que NO sirve como referencia permanente. La referencia
/// definitiva la asigna el almacenamiento local o el backend.
class PhotoFile {
  const PhotoFile({
    required this.path,
    required this.bytes,
    required this.mimeType,
    required this.sizeBytes,
    required this.pickedAt,
    this.originalName,
  });

  final String path;
  final Uint8List bytes;
  final String mimeType;
  final int sizeBytes;
  final DateTime pickedAt;
  final String? originalName;

  String get sizeLabel => PhotoRules.sizeLabel(sizeBytes);
}

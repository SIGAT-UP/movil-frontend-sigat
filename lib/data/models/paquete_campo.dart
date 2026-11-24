/// Versión vigente del paquete de campo de un predio (`PaqueteCampoInfo` del contrato).
/// Solo trae metadatos: el contenido (incluido el mapa) no se modela en esta clase.
class PaqueteCampo {
  const PaqueteCampo({
    required this.version,
    required this.hash,
    required this.generadoEn,
    this.invalidadoEn,
    this.tamanoBytes,
  });

  final int version;

  /// SHA-256 del contenido. El servidor lo usa como ETag.
  final String hash;
  final DateTime generadoEn;

  /// Momento en que el paquete dejó de ser válido (cambio de configuración). null = vigente.
  final DateTime? invalidadoEn;
  final int? tamanoBytes;

  bool get vigente => invalidadoEn == null;

  factory PaqueteCampo.fromApi(Map<String, dynamic> j) => PaqueteCampo(
        version: j['paqu_version'] as int,
        hash: j['paqu_hash'] as String,
        generadoEn: DateTime.parse(j['generado_en'] as String),
        invalidadoEn: j['invalidado_en'] == null
            ? null
            : DateTime.parse(j['invalidado_en'] as String),
        tamanoBytes: j['tamano_bytes'] as int?,
      );
}

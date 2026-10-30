import 'dart:typed_data';

import 'photo_file.dart';

enum TrapCondition {
  buenEstado('En buen estado'),
  danada('Dañada'),
  caida('Caída'),
  sinAtrayente('Sin atrayente'),
  noEncontrada('No encontrada');

  const TrapCondition(this.label);
  final String label;

  /// La BD solo conoce dos condiciones (`condicion_trampa`): 1 = Normal, 2 = Dañada.
  /// Caída y sin atrayente son daños de la trampa; el detalle va en las observaciones.
  /// "No encontrada" no es una condición: es una trampa NO LEÍDA (`lect_leida = false`)
  /// y la BD exige su justificación (`lect_justificacion`).
  int get dbCondId => this == buenEstado ? 1 : 2;

  /// ¿Se pudo leer la trampa? Falso solo cuando no se encontró.
  bool get wasRead => this != noEncontrada;
}

/// Fotografía de evidencia asociada a una lectura.
///
/// `localPath` es la ruta que entregó la cámara o la galería. En móvil suele
/// ser TEMPORAL, así que no sirve como referencia permanente: cuando exista
/// almacenamiento local propio, el archivo debe copiarse a una carpeta de la
/// app y guardarse esa ruta. `remoteRef` es la referencia que devolverá el
/// backend; hoy siempre es null porque todavía no hay servidor.
class Evidence {
  const Evidence({
    required this.id,
    required this.observation,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.capturedAt,
    this.bytes,
    this.readingId,
    this.trapId,
    this.lotId,
    this.userId,
    this.remoteRef,
    this.uploadStatus = UploadStatus.local,
    this.lat,
    this.lng,
  });

  final String id;
  final String observation;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final DateTime capturedAt;

  /// Contenido en memoria, para previsualizar en móvil y web sin usar dart:io.
  final Uint8List? bytes;

  // --- Relación con el registro al que pertenece ---
  final String? readingId;
  final String? trapId;
  final String? lotId;
  final String? userId;

  /// Referencia que devuelve el backend (id o URL). Null = todavía no se envió.
  final String? remoteRef;
  final UploadStatus uploadStatus;

  final double? lat;
  final double? lng;

  /// Crea una evidencia a partir de una foto ya validada.
  factory Evidence.fromPhoto(PhotoFile photo, {required String id, required String observation}) => Evidence(
        id: id,
        observation: observation,
        localPath: photo.path,
        mimeType: photo.mimeType,
        sizeBytes: photo.sizeBytes,
        capturedAt: photo.pickedAt,
        bytes: photo.bytes,
      );

  /// Completa la relación con la lectura en el momento de guardar.
  Evidence attachTo({required String readingId, required String trapId, required String lotId, String? userId}) =>
      Evidence(
        id: id,
        observation: observation,
        localPath: localPath,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        capturedAt: capturedAt,
        bytes: bytes,
        readingId: readingId,
        trapId: trapId,
        lotId: lotId,
        userId: userId,
        remoteRef: remoteRef,
        uploadStatus: uploadStatus,
        lat: lat,
        lng: lng,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reading_id': readingId,
        'trap_id': trapId,
        'lot_id': lotId,
        'user_id': userId,
        'observation': observation,
        'local_path': localPath,
        'remote_ref': remoteRef,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'captured_at': capturedAt.toIso8601String(),
        'upload_status': uploadStatus.name,
        'lat': lat,
        'lng': lng,
      };

  /// Reconstruye la evidencia guardada en el teléfono. Los bytes NO se guardan en la
  /// cola local (pesan mucho): la vista previa vuelve a leerse de [localPath].
  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        id: j['id'] as String,
        observation: j['observation'] as String? ?? '',
        localPath: j['local_path'] as String? ?? '',
        mimeType: j['mime_type'] as String? ?? 'image/jpeg',
        sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
        capturedAt: DateTime.parse(j['captured_at'] as String),
        readingId: j['reading_id'] as String?,
        trapId: j['trap_id'] as String?,
        lotId: j['lot_id'] as String?,
        userId: j['user_id'] as String?,
        remoteRef: j['remote_ref'] as String?,
        uploadStatus: UploadStatus.values.firstWhere((s) => s.name == j['upload_status'],
            orElse: () => UploadStatus.local),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}

/// Lectura de una trampa. Se guarda local primero y luego se sincroniza.
class Reading {
  const Reading({
    required this.id,
    required this.trapId,
    required this.trapLabel,
    required this.lotId,
    required this.observedAt,
    required this.specimens,
    required this.condition,
    this.bodyChangeDate,
    this.attractantChangeDate,
    this.observations,
    this.evidence = const [],
    this.synced = false,
  });

  final String id;
  final String trapId;
  final String trapLabel;
  final String lotId;
  final DateTime observedAt;
  final int specimens;
  final TrapCondition condition;
  final DateTime? bodyChangeDate;
  final DateTime? attractantChangeDate;
  final String? observations;
  final List<Evidence> evidence;
  final bool synced;

  /// Carga útil para `POST /sync/batch` (entidad `lectura_trampa`), con los NOMBRES DE
  /// COLUMNA de la BD. El backend completa `usua_id`, `disp_id`, `oper_id` y
  /// `lect_t_sincronizacion`; el teléfono solo aporta lo que observó.
  /// [visitId] es la visita a la que pertenece (`visi_id`).
  Map<String, dynamic> toSyncPayload({required String visitId}) => {
        'lect_registro_id': id,
        'lect_version': 1,
        'visi_id': visitId,
        'tram_id': trapId,
        'lect_leida': condition.wasRead,
        'lect_especimenes': condition.wasRead ? specimens : null,
        'lect_justificacion': condition.wasRead ? null : (observations ?? ''),
        'cond_id': condition.dbCondId,
        'lect_fecha_cambio_cuerpo': bodyChangeDate?.toIso8601String().substring(0, 10),
        'lect_fecha_cambio_atrayente': attractantChangeDate?.toIso8601String().substring(0, 10),
        'lect_observaciones': observations,
        'lect_t_observacion': observedAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'trap_id': trapId,
        'trap_label': trapLabel,
        'lot_id': lotId,
        'observed_at': observedAt.toIso8601String(),
        'specimens': specimens,
        'condition': condition.name,
        'body_change_date': bodyChangeDate?.toIso8601String(),
        'attractant_change_date': attractantChangeDate?.toIso8601String(),
        'observations': observations,
        'evidence': evidence.map((e) => e.toJson()).toList(),
      };

  /// Lectura guardada en el teléfono (cola de pendientes). [synced] siempre es false:
  /// solo el servidor puede confirmar que la recibió.
  factory Reading.fromJson(Map<String, dynamic> j) {
    DateTime? fecha(dynamic v) => v == null ? null : DateTime.parse(v as String);
    return Reading(
      id: j['id'] as String,
      trapId: j['trap_id'] as String,
      trapLabel: j['trap_label'] as String? ?? '',
      lotId: j['lot_id'] as String,
      observedAt: DateTime.parse(j['observed_at'] as String),
      specimens: (j['specimens'] as num?)?.toInt() ?? 0,
      condition: TrapCondition.values.firstWhere((c) => c.name == j['condition'],
          orElse: () => TrapCondition.buenEstado),
      bodyChangeDate: fecha(j['body_change_date']),
      attractantChangeDate: fecha(j['attractant_change_date']),
      observations: j['observations'] as String?,
      evidence: [
        for (final e in (j['evidence'] as List? ?? const []))
          Evidence.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}

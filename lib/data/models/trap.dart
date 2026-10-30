/// Trampa Jackson ubicada en un lote.
class Trap {
  const Trap({
    required this.id,
    required this.icaCode,
    required this.label,
    required this.lotId,
    required this.type,
    required this.lat,
    required this.lng,
    this.gridCell,
    this.lastReadingDate,
    this.lastCaptures,
    this.active = true,
  });

  final String id;
  final String icaCode; // 54518-602-5 (BD: tram_codigo, el que trae el QR)
  final String label; // ICA-005 (nombre corto)
  final String lotId;
  final String type; // Jackson (impar) o McPhail (par)
  final double lat;
  final double lng;
  final String? gridCell; // C3
  final DateTime? lastReadingDate;
  final int? lastCaptures;
  final bool active;

  factory Trap.fromJson(Map<String, dynamic> j) => Trap(
        id: j['id'].toString(),
        icaCode: j['ica_code'] as String,
        label: j['label'] as String,
        lotId: j['lot_id'].toString(),
        type: j['type'] as String? ?? 'Jackson',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        gridCell: j['grid_cell'] as String?,
        lastReadingDate: j['last_reading_date'] == null ? null : DateTime.parse(j['last_reading_date'] as String),
        lastCaptures: j['last_captures'] as int?,
        active: j['active'] as bool? ?? true,
      );
}

/// Resultado de buscar una trampa por código (QR o manual) con sus validaciones.
/// Construye una Trap desde una fila de `v_trampa_app` (lo que devuelve `GET /traps`).
/// `tram_codigo` es el código oficial (`54518-602-5`); la etiqueta corta se deriva del número.
Trap trapFromApi(Map<String, dynamic> j) {
  final codigo = j['tram_codigo'].toString();
  final numero = codigo.split('-').last.padLeft(3, '0');
  return Trap(
    id: j['tram_id'].toString(),
    icaCode: codigo,
    label: 'ICA-$numero',
    lotId: j['lote_id'].toString(),
    type: j['tipo'] as String? ?? 'Jackson',
    lat: (j['latitud'] as num).toDouble(),
    lng: (j['longitud'] as num).toDouble(),
    gridCell: j['celda'] as String?,
    lastReadingDate: j['ultima_lectura'] == null ? null : DateTime.parse(j['ultima_lectura'] as String),
    lastCaptures: (j['ultima_lectura_especimenes'] as num?)?.toInt(),
    active: (j['estado'] as String? ?? 'activo') == 'activo',
  );
}

class TrapLookup {
  const TrapLookup({
    required this.trap,
    required this.belongsToActiveLot,
    required this.insideLot,
    required this.inCatalog,
  });

  final Trap trap;
  final bool belongsToActiveLot;

  /// Ubicación del dispositivo dentro del lote (GPS). null = no verificado.
  final bool? insideLot;
  final bool inCatalog;

  bool get allValid => belongsToActiveLot && (insideLot ?? false) && inCatalog;
}

/// Estado de cada trampa durante la visita del lote.
enum TrapVisitState { pendiente, registrada, justificada }

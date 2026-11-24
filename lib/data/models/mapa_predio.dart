/// Una geometría GeoJSON con sus propiedades (`FeatureGeoJson` del contrato).
/// La geometría se conserva tal cual para MapLibre; este sprint no la dibuja.
class FeatureGeo {
  const FeatureGeo({
    required this.id,
    required this.properties,
    required this.geometry,
  });

  final Object? id;
  final Map<String, dynamic> properties;

  /// Objeto de geometría GeoJSON (`type` y `coordinates`), o null si no tiene.
  final Map<String, dynamic>? geometry;

  factory FeatureGeo.fromJson(Map<String, dynamic> j) => FeatureGeo(
        id: j['id'],
        properties:
            Map<String, dynamic>.from(j['properties'] as Map? ?? const {}),
        geometry: j['geometry'] == null
            ? null
            : Map<String, dynamic>.from(j['geometry'] as Map),
      );
}

/// Colección de geometrías (`ColeccionGeoJson` del contrato).
class ColeccionGeo {
  const ColeccionGeo(this.features);

  final List<FeatureGeo> features;

  factory ColeccionGeo.fromJson(Map<String, dynamic> j) => ColeccionGeo([
        for (final f in (j['features'] as List? ?? const []))
          FeatureGeo.fromJson(Map<String, dynamic>.from(f as Map)),
      ]);
}

/// Capas del predio para MapLibre (`MapaPredio` del contrato). Todo en EPSG:4326.
class MapaPredio {
  const MapaPredio({
    required this.predio,
    required this.lotes,
    required this.celdas,
    required this.trampas,
  });

  final FeatureGeo predio;
  final ColeccionGeo lotes;
  final ColeccionGeo celdas;
  final ColeccionGeo trampas;

  factory MapaPredio.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> de(String clave) =>
        Map<String, dynamic>.from(j[clave] as Map);
    return MapaPredio(
      predio: FeatureGeo.fromJson(de('predio')),
      lotes: ColeccionGeo.fromJson(de('lotes')),
      celdas: ColeccionGeo.fromJson(de('celdas')),
      trampas: ColeccionGeo.fromJson(de('trampas')),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/core/utils/canonical_json.dart';

const _algoritmo = {'canonicalizacion': 'RFC 8785 (JCS)', 'hash': 'sha256'};

const _vectores = <Map<String, dynamic>>[
  {
    'nombre': 'lectura simple',
    'contenido': {
      'entidad': 'lectura_trampa',
      'accion': 'crear',
      'registro_id': '0190f5b0-0000-7000-8000-0000000000b1',
      'version': 1,
      'linaje': 'inspeccion_oficial',
      't_observacion': '2026-03-01T13:15:30.250Z',
      'datos': {
        'visi_id': '0190f5b0-0000-7000-8000-0000000000a0',
        'tram_id': 11,
        'cond_id': 1,
        'lect_leida': true,
        'lect_especimenes': 4,
        'lect_justificacion': null,
      },
    },
    'hash': '43a8396af58e26b1e8f5bd6bbad24f830ab04566cb03da4d7221d28a26849731',
  },
  {
    'nombre': 'visita con varios lotes y nulos',
    'contenido': {
      'entidad': 'visita',
      'accion': 'crear',
      'registro_id': '0190f5b0-0000-7000-8000-0000000000a0',
      'version': 1,
      'linaje': null,
      't_observacion': '2026-03-02T09:00:00.000Z',
      'datos': {
        'pred_id': 3,
        'lote_ids': [42, 43],
        'ruta_id': null,
        'visi_t_inicio_obs': '2026-03-02T08:40:00.000Z',
        'visi_t_fin_obs': '2026-03-02T09:00:00.000Z',
      },
    },
    'hash': '6f5dcb27b553cba96ebb9e737cbb97920f0aa407565fc55dc64d9a26ca70bb79',
  },
  {
    'nombre': 'decimales, unicode y orden de claves',
    'contenido': {
      't_observacion': '2026-03-03T08:30:15.500Z',
      'datos': {
        'zona': 'Trampa «A» ñ',
        'lect_precision_m': 1.0,
        'lect_observaciones': 'Borde del lote — revisar',
        'atra_id': 2,
        'lect_leida': false,
        'lect_especimenes': null,
        'lect_justificacion': 'Cebo seco',
        'smalls': 1e-06,
        'tiny': 1e-07,
      },
      'linaje': 'inspeccion_oficial',
      'version': 1,
      'registro_id': '0190f5b0-0000-7000-8000-0000000000b2',
      'accion': 'crear',
      'entidad': 'lectura_trampa',
    },
    'hash': 'ed5e8f45ca91fa5fda6a0b75bfa5b45e95994101d4652f049b0f6d0d9366fcab',
  },
  {
    'nombre': 'corrección de versión 2',
    'contenido': {
      'entidad': 'lectura_trampa',
      'accion': 'corregir',
      'registro_id': '0190f5b0-0000-7000-8000-0000000000b3',
      'version': 2,
      'linaje': 'inspeccion_oficial',
      't_observacion': '2026-03-04T17:00:00.000Z',
      'datos': {
        'visi_id': '0190f5b0-0000-7000-8000-0000000000a0',
        'tram_id': 12,
        'cond_id': 2,
        'lect_leida': true,
        'lect_especimenes': 0,
        'lect_motivo_correccion': 'Se contaron de nuevo',
      },
    },
    'hash': '21321e345e5614768d7e4c48c07eba2cbb1b3f186cf7bc112ac49c6bdf45b49a',
  },
  {
    'nombre': 'anulación',
    'contenido': {
      'entidad': 'lectura_trampa',
      'accion': 'anular',
      'registro_id': '0190f5b0-0000-7000-8000-0000000000b4',
      'version': 3,
      'linaje': 'inspeccion_oficial',
      't_observacion': '2026-03-05T06:45:00.000Z',
      'datos': {
        'visi_id': '0190f5b0-0000-7000-8000-0000000000a0',
        'tram_id': 13,
        'cond_id': 1,
        'lect_leida': true,
        'lect_especimenes': 7,
        'lect_motivo_anulacion': 'Trampa mal identificada',
      },
    },
    'hash': 'afada6776cce04197e4749d3a58b329ce223370bc3791ef4e332ccce9db7e40f',
  },
];

const _normalizacion = <Map<String, String>>[
  {
    'entrada': '2026-03-01T08:15:30.250-05:00',
    'canonica': '2026-03-01T13:15:30.250Z'
  },
  {
    'entrada': '2026-03-03T10:30:15.500+02:00',
    'canonica': '2026-03-03T08:30:15.500Z'
  },
  {
    'entrada': '2026-03-02T09:00:00.000Z',
    'canonica': '2026-03-02T09:00:00.000Z'
  },
  {
    'entrada': '2026-03-02T04:00:00.123456Z',
    'canonica': '2026-03-02T04:00:00.123Z'
  },
];

void main() {
  test('los vectores declaran el algoritmo acordado', () {
    expect(_algoritmo['canonicalizacion'], 'RFC 8785 (JCS)');
    expect(_algoritmo['hash'], 'sha256');
    expect(_vectores, hasLength(greaterThanOrEqualTo(5)));
  });

  for (final vector in _vectores) {
    test('huella: ${vector['nombre']}', () {
      expect(
        CanonicalJson.sha256Hex(vector['contenido']),
        vector['hash'],
        reason: 'El texto canónico del móvil no coincide con el del backend.',
      );
    });
  }

  for (final vector in _normalizacion) {
    test('instante canónico: ${vector['entrada']}', () {
      final entrada = DateTime.parse(vector['entrada'] as String);
      expect(CanonicalJson.instanteCanonico(entrada), vector['canonica']);
    });
  }

  test('el orden de las claves no cambia la huella', () {
    final a = {
      'b': 2,
      'a': 1,
      'c': {'z': true, 'y': null}
    };
    final b = {
      'c': {'y': null, 'z': true},
      'a': 1,
      'b': 2
    };
    expect(CanonicalJson.serialize(a), CanonicalJson.serialize(b));
    expect(CanonicalJson.serialize(a), '{"a":1,"b":2,"c":{"y":null,"z":true}}');
  });

  test('los números siguen el formato de ECMAScript (JCS)', () {
    expect(CanonicalJson.serialize(1.0), '1');
    expect(CanonicalJson.serialize(1.5), '1.5');
    expect(CanonicalJson.serialize(0.000001), '0.000001');
    expect(CanonicalJson.serialize(1e-7), '1e-7');
    expect(CanonicalJson.serialize(1e21), '1e+21');
    expect(CanonicalJson.serialize(-0.0), '0');
    expect(CanonicalJson.serialize(2.5e-8), '2.5e-8');
  });

  test('las cadenas conservan Unicode y escapan solo lo que exige JSON', () {
    expect(
      CanonicalJson.serialize({'zona': 'Trampa «A» ñ', 'l': 'Borde — revisar'}),
      '{"l":"Borde — revisar","zona":"Trampa «A» ñ"}',
    );
  });

  test('uuidDesdeSemilla es estable y tiene forma de UUID', () {
    final primera = CanonicalJson.uuidDesdeSemilla('visita:abc:predio:3');
    final segunda = CanonicalJson.uuidDesdeSemilla('visita:abc:predio:3');
    final otra = CanonicalJson.uuidDesdeSemilla('visita:abc:predio:4');
    final forma = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

    expect(primera, segunda);
    expect(primera, isNot(otra));
    expect(forma.hasMatch(primera), isTrue, reason: primera);
  });

  test('generarUuidV4 produce valores distintos con versión 4', () {
    final forma = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final valores = {
      for (var i = 0; i < 50; i++) CanonicalJson.generarUuidV4()
    };
    expect(valores, hasLength(50));
    expect(valores.every(forma.hasMatch), isTrue);
  });
}

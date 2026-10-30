import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ningún módulo de la app trae datos de demostración, usuarios ficticios ni contraseñas.
/// Revisa el código fuente de `lib/`.
void main() {
  final fuentes = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('hay código que revisar', () => expect(fuentes.length, greaterThan(50)));

  const prohibidos = <String, String>{
    r'MockDb|Mock[A-Z]\w*Repository|DemoSeed|demo_seed': 'repositorios o datos de demostración',
    r"'lot-[a-z]'|'predio-\d'": 'identificadores de lote o predio quemados',
    r'Sigat2026|durazno123|demo-token': 'contraseñas o tokens de prueba',
    r'@ica\.gov\.co|@sigat\.test': 'correos institucionales o cuentas de prueba',
    r'[Dd]atos? de demostraci[oó]n|DATO DE DEMOSTRACIÓN|isDemo': 'rótulos de demostración',
  };

  for (final e in prohibidos.entries) {
    test('sin ${e.value}', () {
      final patron = RegExp(e.key);
      final hallazgos = [
        for (final f in fuentes)
          for (final (i, linea) in f.readAsLinesSync().indexed)
            if (patron.hasMatch(linea)) '${f.path}:${i + 1}: ${linea.trim()}',
      ];
      expect(hallazgos, isEmpty, reason: hallazgos.join('\n'));
    });
  }

  test('ya no existen los archivos de demostración', () {
    expect(File('lib/data/demo/demo_seed.dart').existsSync(), isFalse);
    expect(File('lib/data/repositories/mock_db.dart').existsSync(), isFalse);
    expect(Directory('lib/data/repositories').listSync().where((f) => f.path.contains('mock_')), isEmpty);
  });

  test('todos los repositorios de la app son los que hablan con el backend', () {
    final servicios = File('lib/data/app_services.dart').readAsStringSync();
    expect(RegExp(r'= Api\w+Repository\(').allMatches(servicios).length, greaterThanOrEqualTo(13));
    expect(servicios.contains('Mock'), isFalse);
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/data/local/lot_summary_cache.dart';

/// La última copia del resumen sobrevive a cerrar la app y es de un solo usuario.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda y lee la copia del lote con su fecha', () async {
    final cache = LotSummaryCache();
    await cache.save('5', 'L1', {'lote_id': 'L1', 'mtd': 1.5});

    final leido = await cache.read('5', 'L1');
    expect(leido, isNotNull);
    expect(leido!.datos['mtd'], 1.5);
    expect(DateTime.now().difference(leido.guardadoEn).inMinutes, lessThan(1));
  });

  test('una cuenta no ve la copia de otra ni de otro lote', () async {
    final cache = LotSummaryCache();
    await cache.save('5', 'L1', {'lote_id': 'L1'});

    expect(await cache.read('6', 'L1'), isNull);
    expect(await cache.read('5', 'L2'), isNull);
  });

  test('un valor dañado no bloquea la app', () async {
    SharedPreferences.setMockInitialValues(
        {'sigat.resumen_lote.v1': '{no es json'});
    expect(await LotSummaryCache().read('5', 'L1'), isNull);
  });
}

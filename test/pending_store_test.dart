import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';

/// La cola de pendientes SOBREVIVE a cerrar la app (shared_preferences).
void main() {
  PendingRecord registro(String id, {String owner = '5'}) => PendingRecord(
        id: id,
        ownerId: owner,
        kind: PendingKind.lectura,
        label: 'ICA-001 · 2 moscas',
        observedAt: DateTime(2026, 10, 29, 8),
        payload: {'id': id, 'trap_id': '1'},
        lotId: '10',
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lo guardado se lee desde otra instancia (como al reabrir la app)', () async {
    await SharedPrefsPendingStore().put(registro('a'));
    final leidos = await SharedPrefsPendingStore().forOwner('5');
    expect(leidos.single.id, 'a');
    expect(leidos.single.kind, PendingKind.lectura);
    expect(leidos.single.payload['trap_id'], '1');
  });

  test('reemplaza por id y solo se quita explícitamente', () async {
    final s = SharedPrefsPendingStore();
    await s.put(registro('a'));
    await s.put(registro('a').withError('Sin conexión.'));
    expect((await s.forOwner('5')).single.lastError, 'Sin conexión.');
    await s.remove('a');
    expect(await s.forOwner('5'), isEmpty);
  });

  test('un valor dañado no bloquea la app y se conserva aparte', () async {
    SharedPreferences.setMockInitialValues({'sigat.pendientes.v1': '{no es json'});
    expect(await SharedPrefsPendingStore().forOwner('5'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().any((k) => k.startsWith('sigat.pendientes.v1.danado.')), isTrue);
  });
}

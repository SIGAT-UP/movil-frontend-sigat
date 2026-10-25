import 'package:flutter_test/flutter_test.dart';
import 'package:sigat_mobile/app/app.dart';

void main() {
  testWidgets('la aplicación arranca y muestra el título', (tester) async {
    await tester.pumpWidget(const SigatApp());

    expect(find.text('SIGAT · Durazno'), findsOneWidget);
    expect(find.text('Monitoreo fitosanitario'), findsOneWidget);
  });
}

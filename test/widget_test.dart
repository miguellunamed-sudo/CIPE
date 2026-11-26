import 'package:flutter_test/flutter_test.dart';
import 'package:papeleria_app/main.dart';

void main() {
  testWidgets('Arranque inicial de Papelería CIPE', (WidgetTester tester) async {
    await tester.pumpWidget(const PapeleriaApp());
    expect(find.text('Acceso al Sistema'), findsOneWidget);
  });
}
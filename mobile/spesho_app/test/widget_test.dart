import 'package:flutter_test/flutter_test.dart';
import 'package:spesho_app/main.dart';

void main() {
  testWidgets('Spesho app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeshoApp());
    expect(find.byType(SpeshoApp), findsOneWidget);
  });
}

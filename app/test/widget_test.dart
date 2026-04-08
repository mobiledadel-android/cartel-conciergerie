import 'package:flutter_test/flutter_test.dart';
import 'package:cartel_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CartelApp());
    expect(find.text('Bienvenue'), findsOneWidget);
  });
}

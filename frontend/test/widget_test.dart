import 'package:flutter_test/flutter_test.dart';
import 'package:flavorlog/main.dart';

void main() {
  testWidgets('FlavorLog app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlavorLogApp());
    await tester.pump();

    expect(find.byType(FlavorLogApp), findsOneWidget);
  });
}

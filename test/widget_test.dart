import 'package:flutter_test/flutter_test.dart';
import 'package:cadence/main.dart';

void main() {
  testWidgets('Cadence smoke test', (WidgetTester tester) async {
    // Build Cadence app
    await tester.pumpWidget(const CadenceApp());
    expect(find.byType(CadenceApp), findsOneWidget);
  });
}

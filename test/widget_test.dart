import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cadence/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Cadence smoke test', (WidgetTester tester) async {
    // Build Cadence app
    await tester.pumpWidget(const CadenceApp());
    expect(find.byType(CadenceApp), findsOneWidget);
  });
}

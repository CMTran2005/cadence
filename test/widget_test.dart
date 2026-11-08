import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cadence/main.dart';
import 'package:cadence/core/services/settings_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await SettingsService.instance.init();
  });

  testWidgets('Cadence smoke test', (WidgetTester tester) async {
    // Build Cadence app
    await tester.pumpWidget(const CadenceApp());
    await tester.pump();
    expect(find.byType(CadenceApp), findsOneWidget);
  });
}

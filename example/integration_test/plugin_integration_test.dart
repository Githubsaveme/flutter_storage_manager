import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_storage_manager/flutter_storage_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getCapabilities test', (WidgetTester tester) async {
    final manager = FlutterStorageManager.instance;
    final capabilities = await manager.getCapabilities();

    expect(capabilities.canAnalyze, true);
    expect(capabilities.canClearCache, true);
  });
}

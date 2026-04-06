import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:learning_app/features/theme/providers/app_theme_provider.dart';
import 'package:learning_app/main.dart';
import 'package:learning_app/routes/app_routes.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.reset();

    final appThemeProvider = AppThemeProvider();
    await appThemeProvider.init();
    Get.put(appThemeProvider, permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('App renders choose option screen in test mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(initialRoute: AppRoutes.choose),
    );
    await tester.pump();

    expect(find.text('Choose Your Option'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });
}

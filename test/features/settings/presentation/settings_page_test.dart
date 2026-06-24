import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('SettingsPage shows title and setting items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: SettingsPage(onLocaleChanged: (locale) {}),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Privacy'), findsNothing);
  });
}

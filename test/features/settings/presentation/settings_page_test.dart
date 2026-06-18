import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('SettingsPage shows title and setting items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

void main() {
  group('ProviderConfigPage', () {
    testWidgets('OpenAI preset auto-fills Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      expect(find.text('https://api.openai.com/v1'), findsOneWidget);
    });

    testWidgets('Custom Provider allows editing name and Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      // Name field should have "Custom Provider" and be editable
      final nameField = find.widgetWithText(TextFormField, 'Custom Provider');
      expect(nameField, findsOneWidget);

      // Base URL field should be empty and editable
      final urlField = find.widgetWithText(TextFormField, 'Base URL');
      expect(urlField, findsOneWidget);
    });

    testWidgets('Empty name shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom (name is editable)

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      // Clear the name field
      final nameField = find.widgetWithText(TextFormField, 'Custom Provider');
      await tester.enterText(nameField, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('Invalid Base URL shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom (URL is editable)

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      // Enter invalid URL
      final urlField = find.widgetWithText(TextFormField, 'Base URL');
      await tester.enterText(urlField, 'not-a-url');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid HTTP or HTTPS URL'), findsOneWidget);
    });

    testWidgets('API Key is obscured by default', (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      final apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isTrue);
    });

    testWidgets('Toggle button switches API Key visibility',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(preset: preset),
        ),
      );

      // Initially obscured
      var apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isTrue);

      // Tap toggle button
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Now visible
      apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isFalse);
    });

    testWidgets('Valid form submission returns with SnackBar',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderConfigPage(preset: preset),
                    ),
                  );
                },
                child: const Text('Open Config'),
              ),
            ),
          ),
        ),
      );

      // Open config page
      await tester.tap(find.text('Open Config'));
      await tester.pumpAndSettle();

      // Fill in API Key
      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'test-api-key',
      );

      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should be back on previous page
      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(find.text('Provider configuration is ready'), findsOneWidget);
    });
  });
}

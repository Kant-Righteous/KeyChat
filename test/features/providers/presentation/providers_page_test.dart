import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import '../data/fake_api_key_store.dart';
import '../data/fake_provider_config_store.dart';
import '../data/fake_provider_connection_tester.dart';

void main() {
  group('ProvidersPage', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
    });

    testWidgets('shows 4 provider presets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Providers'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('DeepSeek'), findsOneWidget);
      expect(find.text('OpenRouter'), findsOneWidget);
      expect(find.text('Custom Provider'), findsOneWidget);
    });

    testWidgets('shows Not configured when no key exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not configured'), findsNWidgets(4));
    });

    testWidgets('shows Configured when key exists',
        (WidgetTester tester) async {
      await apiKeyStore.saveKey('openai', 'sk-test');

      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configured'), findsOneWidget);
      expect(find.text('Not configured'), findsNWidgets(3));
    });

    testWidgets('tapping OpenAI opens config page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
    });

    testWidgets('shows saved display name for custom provider',
        (WidgetTester tester) async {
      await configStore.saveConfig(
        ProviderConfigData(
          providerId: 'custom',
          displayName: 'My Custom AI',
          baseUrl: 'https://custom.example.com/v1',
          updatedAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Custom AI'), findsOneWidget);
    });

    testWidgets('ProvidersPage refreshes after returning from config page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Provider'), findsOneWidget);
      expect(find.text('Not configured'), findsNWidgets(4));

      await tester.tap(find.text('Custom Provider'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider Name'),
        'My Custom AI',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Base URL'),
        'https://custom.example.com/v1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'test-key-123',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProvidersPage), findsOneWidget);
      expect(find.text('My Custom AI'), findsOneWidget);
      expect(find.text('Configured'), findsOneWidget);
    });

    testWidgets('passes connectionTester to config page',
        (WidgetTester tester) async {
      final connTester = FakeProviderConnectionTester();

      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            connectionTester: connTester,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      final configPage = tester.widget<ProviderConfigPage>(
        find.byType(ProviderConfigPage),
      );
      expect(configPage.connectionTester, connTester);
    });
  });
}

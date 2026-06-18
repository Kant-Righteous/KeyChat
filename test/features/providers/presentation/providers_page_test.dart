import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import '../data/fake_api_key_store.dart';

void main() {
  group('ProvidersPage', () {
    late FakeApiKeyStore store;

    setUp(() {
      store = FakeApiKeyStore();
    });

    testWidgets('shows 4 provider presets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(apiKeyStore: store),
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
          home: ProvidersPage(apiKeyStore: store),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not configured'), findsNWidgets(4));
    });

    testWidgets('shows Configured when key exists',
        (WidgetTester tester) async {
      await store.saveKey('openai', 'sk-test');

      await tester.pumpWidget(
        MaterialApp(
          home: ProvidersPage(apiKeyStore: store),
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
          home: ProvidersPage(apiKeyStore: store),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'features/providers/data/fake_api_key_store.dart';
import 'features/providers/data/fake_provider_config_store.dart';

class _FakeChatClient implements ChatCompletionClient {
  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    dynamic cancelToken,
  }) async {
    return const ChatCompletionResult.failure(
      errorType: ChatCompletionErrorType.unknown,
      userMessage: 'Not implemented',
    );
  }
}

void main() {
  testWidgets('ChatPage shows empty state when no provider',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          chatClient: _FakeChatClient(),
          apiKeyStore: FakeApiKeyStore(),
          configStore: FakeProviderConfigStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KeyChat'), findsOneWidget);
    expect(find.text('No ready provider'), findsOneWidget);
  });

  testWidgets('ProvidersPage shows presets', (WidgetTester tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    await tester.pumpWidget(
      MaterialApp(
        home: ProvidersPage(
          apiKeyStore: apiKeyStore,
          configStore: configStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    expect(find.text('Custom Provider'), findsOneWidget);
  });

  testWidgets('SettingsPage shows setting items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import 'fake_chat_completion_client.dart';

void main() {
  group('DefaultChatClientResolver', () {
    late FakeChatCompletionClient openAiClient;
    late DefaultChatClientResolver resolver;

    setUp(() {
      openAiClient = FakeChatCompletionClient();
      resolver = DefaultChatClientResolver(
        openAiCompatibleClient: openAiClient,
      );
    });

    test('openAiCompatible returns existing client', () {
      final client = resolver.resolve(ProviderProtocol.openAiCompatible);
      expect(client, same(openAiClient));
    });

    test('anthropicMessages returns null', () {
      final client = resolver.resolve(ProviderProtocol.anthropicMessages);
      expect(client, isNull);
    });

    test('geminiGenerateContent returns null', () {
      final client = resolver.resolve(ProviderProtocol.geminiGenerateContent);
      expect(client, isNull);
    });

    test('supports openAiCompatible', () {
      expect(resolver.supports(ProviderProtocol.openAiCompatible), isTrue);
    });

    test('does not support anthropicMessages', () {
      expect(resolver.supports(ProviderProtocol.anthropicMessages), isFalse);
    });

    test('does not support geminiGenerateContent', () {
      expect(
          resolver.supports(ProviderProtocol.geminiGenerateContent), isFalse);
    });

    test('does not create new client on multiple resolves', () {
      final client1 = resolver.resolve(ProviderProtocol.openAiCompatible);
      final client2 = resolver.resolve(ProviderProtocol.openAiCompatible);
      expect(identical(client1, client2), isTrue);
    });
  });
}

import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

abstract interface class ChatClientResolver {
  ChatCompletionClient? resolve(ProviderProtocol protocol);
  bool supports(ProviderProtocol protocol);
}

final class DefaultChatClientResolver implements ChatClientResolver {
  final Map<ProviderProtocol, ChatCompletionClient> _clients;

  DefaultChatClientResolver({
    required ChatCompletionClient openAiCompatibleClient,
  }) : _clients = {
          ProviderProtocol.openAiCompatible: openAiCompatibleClient,
        };

  @override
  ChatCompletionClient? resolve(ProviderProtocol protocol) {
    return _clients[protocol];
  }

  @override
  bool supports(ProviderProtocol protocol) {
    return _clients.containsKey(protocol);
  }
}

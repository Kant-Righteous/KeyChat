import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

class FakeChatClientResolver implements ChatClientResolver {
  final Map<ProviderProtocol, ChatCompletionClient> _clients;

  FakeChatClientResolver({required ChatCompletionClient openAiCompatibleClient})
      : _clients = {
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

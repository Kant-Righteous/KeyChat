import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

abstract interface class ConnectionTesterResolver {
  ProviderConnectionTester? resolve(ProviderProtocol protocol);
  bool supports(ProviderProtocol protocol);
}

final class DefaultConnectionTesterResolver
    implements ConnectionTesterResolver {
  final Map<ProviderProtocol, ProviderConnectionTester> _testers;

  DefaultConnectionTesterResolver({
    required ProviderConnectionTester openAiCompatibleTester,
  }) : _testers = {
          ProviderProtocol.openAiCompatible: openAiCompatibleTester,
        };

  @override
  ProviderConnectionTester? resolve(ProviderProtocol protocol) {
    return _testers[protocol];
  }

  @override
  bool supports(ProviderProtocol protocol) {
    return _testers.containsKey(protocol);
  }
}

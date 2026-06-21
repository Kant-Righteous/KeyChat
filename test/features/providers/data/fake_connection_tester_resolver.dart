import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

class FakeConnectionTesterResolver implements ConnectionTesterResolver {
  final Map<ProviderProtocol, ProviderConnectionTester> _testers;

  FakeConnectionTesterResolver({
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

import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import 'fake_provider_connection_tester.dart';

void main() {
  group('DefaultConnectionTesterResolver', () {
    late FakeProviderConnectionTester openAiTester;
    late DefaultConnectionTesterResolver resolver;

    setUp(() {
      openAiTester = FakeProviderConnectionTester();
      resolver = DefaultConnectionTesterResolver(
        openAiCompatibleTester: openAiTester,
      );
    });

    test('openAiCompatible returns existing tester', () {
      final tester = resolver.resolve(ProviderProtocol.openAiCompatible);
      expect(tester, same(openAiTester));
    });

    test('anthropicMessages returns null', () {
      final tester = resolver.resolve(ProviderProtocol.anthropicMessages);
      expect(tester, isNull);
    });

    test('geminiGenerateContent returns null', () {
      final tester = resolver.resolve(ProviderProtocol.geminiGenerateContent);
      expect(tester, isNull);
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

    test('does not create new tester on multiple resolves', () {
      final tester1 = resolver.resolve(ProviderProtocol.openAiCompatible);
      final tester2 = resolver.resolve(ProviderProtocol.openAiCompatible);
      expect(identical(tester1, tester2), isTrue);
    });

    test('unsupported protocol does not fall back to openAiCompatible', () {
      final tester = resolver.resolve(ProviderProtocol.anthropicMessages);
      expect(tester, isNull);
    });
  });
}

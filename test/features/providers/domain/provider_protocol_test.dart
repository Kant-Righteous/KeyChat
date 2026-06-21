import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

void main() {
  group('ProviderProtocol storageValue', () {
    test('openAiCompatible returns openai_compatible', () {
      expect(
        ProviderProtocol.openAiCompatible.storageValue,
        'openai_compatible',
      );
    });

    test('anthropicMessages returns anthropic_messages', () {
      expect(
        ProviderProtocol.anthropicMessages.storageValue,
        'anthropic_messages',
      );
    });

    test('geminiGenerateContent returns gemini_generate_content', () {
      expect(
        ProviderProtocol.geminiGenerateContent.storageValue,
        'gemini_generate_content',
      );
    });
  });

  group('ProviderProtocol.tryParse', () {
    test('openai_compatible returns openAiCompatible', () {
      expect(
        ProviderProtocol.tryParse('openai_compatible'),
        ProviderProtocol.openAiCompatible,
      );
    });

    test('anthropic_messages returns anthropicMessages', () {
      expect(
        ProviderProtocol.tryParse('anthropic_messages'),
        ProviderProtocol.anthropicMessages,
      );
    });

    test('gemini_generate_content returns geminiGenerateContent', () {
      expect(
        ProviderProtocol.tryParse('gemini_generate_content'),
        ProviderProtocol.geminiGenerateContent,
      );
    });

    test('unknown value returns null', () {
      expect(ProviderProtocol.tryParse('unknown_protocol'), isNull);
    });

    test('empty string returns null', () {
      expect(ProviderProtocol.tryParse(''), isNull);
    });

    test('enum name does not work as storage value', () {
      expect(ProviderProtocol.tryParse('openAiCompatible'), isNull);
    });
  });

  group('ProviderProtocol round-trip', () {
    test('openAiCompatible round-trips through storage', () {
      final original = ProviderProtocol.openAiCompatible;
      final parsed = ProviderProtocol.tryParse(original.storageValue);
      expect(parsed, original);
    });

    test('anthropicMessages round-trips through storage', () {
      final original = ProviderProtocol.anthropicMessages;
      final parsed = ProviderProtocol.tryParse(original.storageValue);
      expect(parsed, original);
    });

    test('geminiGenerateContent round-trips through storage', () {
      final original = ProviderProtocol.geminiGenerateContent;
      final parsed = ProviderProtocol.tryParse(original.storageValue);
      expect(parsed, original);
    });
  });

  group('ProviderProtocol unknown value handling', () {
    test('unknown value returns null, not openAiCompatible', () {
      final result = ProviderProtocol.tryParse('some_random_protocol');
      expect(result, isNull);
      expect(result, isNot(ProviderProtocol.openAiCompatible));
    });

    test('SQL injection attempt returns null', () {
      expect(ProviderProtocol.tryParse("'; DROP TABLE--"), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(ProviderProtocol.tryParse('   '), isNull);
    });

    test('case-sensitive - OpenAI_Compatible returns null', () {
      expect(ProviderProtocol.tryParse('OpenAI_Compatible'), isNull);
    });

    test('partial match returns null', () {
      expect(ProviderProtocol.tryParse('openai'), isNull);
    });
  });
}

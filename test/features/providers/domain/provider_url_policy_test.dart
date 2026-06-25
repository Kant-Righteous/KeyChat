import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';

void main() {
  group('ProviderUrlPolicy', () {
    group('isHttps', () {
      test('standard HTTPS is valid', () {
        expect(ProviderUrlPolicy.isHttps('https://api.example.com/v1'), isTrue);
      });

      test('HTTPS with trailing slash is valid', () {
        expect(ProviderUrlPolicy.isHttps('https://api.openai.com/v1/'), isTrue);
      });

      test('HTTPS with custom port is valid', () {
        expect(ProviderUrlPolicy.isHttps('https://api.example.com:8443/v1'), isTrue);
      });

      test('HTTPS with IP is valid', () {
        expect(ProviderUrlPolicy.isHttps('https://192.168.1.1:8080'), isTrue);
      });

      test('HTTPS localhost is valid', () {
        expect(ProviderUrlPolicy.isHttps('https://localhost:8080'), isTrue);
      });

      test('HTTP is invalid', () {
        expect(ProviderUrlPolicy.isHttps('http://api.example.com/v1'), isFalse);
      });

      test('empty string is invalid', () {
        expect(ProviderUrlPolicy.isHttps(''), isFalse);
      });

      test('ftp is invalid', () {
        expect(ProviderUrlPolicy.isHttps('ftp://example.com'), isFalse);
      });

      test('javascript is invalid', () {
        expect(ProviderUrlPolicy.isHttps('javascript:alert(1)'), isFalse);
      });

      test('file is invalid', () {
        expect(ProviderUrlPolicy.isHttps('file:///etc/passwd'), isFalse);
      });

      test('data is invalid', () {
        expect(ProviderUrlPolicy.isHttps('data:text/html,<h1>test</h1>'), isFalse);
      });
    });

    group('validateUrl', () {
      test('standard HTTPS is valid', () {
        expect(ProviderUrlPolicy.validateUrl('https://api.example.com/v1'), isNull);
      });

      test('HTTPS with trailing slash is valid', () {
        expect(ProviderUrlPolicy.validateUrl('https://api.openai.com/v1/'), isNull);
      });

      test('HTTPS with custom port is valid', () {
        expect(ProviderUrlPolicy.validateUrl('https://api.example.com:8443/v1'), isNull);
      });

      test('HTTPS with IP is valid', () {
        expect(ProviderUrlPolicy.validateUrl('https://192.168.1.1:8080'), isNull);
      });

      test('HTTPS localhost is valid', () {
        expect(ProviderUrlPolicy.validateUrl('https://localhost:8080'), isNull);
      });

      test('HTTP returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('http://api.example.com/v1');
        expect(error, equals(UrlValidationError.httpsOnly));
      });

      test('empty string returns empty error', () {
        final error = ProviderUrlPolicy.validateUrl('');
        expect(error, equals(UrlValidationError.empty));
      });

      test('null returns empty error', () {
        final error = ProviderUrlPolicy.validateUrl(null);
        expect(error, equals(UrlValidationError.empty));
      });

      test('no scheme returns invalidFormat error', () {
        final error = ProviderUrlPolicy.validateUrl('api.example.com/v1');
        expect(error, equals(UrlValidationError.invalidFormat));
      });

      test('javascript returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('javascript:alert(1)');
        expect(error, equals(UrlValidationError.httpsOnly));
      });

      test('file returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('file:///etc/passwd');
        expect(error, equals(UrlValidationError.httpsOnly));
      });

      test('data returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('data:text/html,test');
        expect(error, equals(UrlValidationError.httpsOnly));
      });

      test('ftp returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('ftp://example.com');
        expect(error, equals(UrlValidationError.httpsOnly));
      });

      test('URL with username returns userInfoNotAllowed error', () {
        final error = ProviderUrlPolicy.validateUrl('https://user@api.example.com');
        expect(error, equals(UrlValidationError.userInfoNotAllowed));
      });

      test('URL with password returns userInfoNotAllowed error', () {
        final error = ProviderUrlPolicy.validateUrl('https://user:pass@api.example.com');
        expect(error, equals(UrlValidationError.userInfoNotAllowed));
      });

      test('URL with empty host returns missingHost error', () {
        final error = ProviderUrlPolicy.validateUrl('https://');
        expect(error, equals(UrlValidationError.missingHost));
      });

      test('HTTP with sensitive query returns httpsOnly error', () {
        final error = ProviderUrlPolicy.validateUrl('http://api.example.com?key=secret123');
        expect(error, equals(UrlValidationError.httpsOnly));
      });
    });

    group('isAllowedForRequest', () {
      test('HTTPS is allowed', () {
        expect(ProviderUrlPolicy.isAllowedForRequest('https://api.example.com'), isTrue);
      });

      test('HTTP is not allowed', () {
        expect(ProviderUrlPolicy.isAllowedForRequest('http://api.example.com'), isFalse);
      });

      test('ftp is not allowed', () {
        expect(ProviderUrlPolicy.isAllowedForRequest('ftp://example.com'), isFalse);
      });

      test('javascript is not allowed', () {
        expect(ProviderUrlPolicy.isAllowedForRequest('javascript:alert(1)'), isFalse);
      });

      test('empty is not allowed', () {
        expect(ProviderUrlPolicy.isAllowedForRequest(''), isFalse);
      });
    });

    group('consistency', () {
      test('isHttps and isAllowedForRequest are consistent', () {
        final testUrls = [
          'https://api.example.com',
          'http://api.example.com',
          'ftp://example.com',
          'javascript:alert(1)',
          '',
          'https://localhost:8080',
        ];

        for (final url in testUrls) {
          expect(ProviderUrlPolicy.isHttps(url),
              equals(ProviderUrlPolicy.isAllowedForRequest(url)));
        }
      });

      test('validateUrl returns null only when isHttps is true', () {
        final testUrls = [
          'https://api.example.com',
          'http://api.example.com',
          'ftp://example.com',
          '',
          'https://localhost:8080',
        ];

        for (final url in testUrls) {
          final isValid = ProviderUrlPolicy.validateUrl(url) == null;
          expect(isValid, equals(ProviderUrlPolicy.isHttps(url)));
        }
      });
    });
  });
}

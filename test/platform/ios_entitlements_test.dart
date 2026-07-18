import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS Entitlements', () {
    test('DebugProfile.entitlements exists', () {
      final file = File('ios/Runner/DebugProfile.entitlements');
      expect(file.existsSync(), isTrue);
    });

    test('Release.entitlements exists', () {
      final file = File('ios/Runner/Release.entitlements');
      expect(file.existsSync(), isTrue);
    });

    test('DebugProfile contains keychain-access-groups', () {
      final content =
          File('ios/Runner/DebugProfile.entitlements').readAsStringSync();
      expect(content, contains('keychain-access-groups'));
    });

    test('Release contains keychain-access-groups', () {
      final content =
          File('ios/Runner/Release.entitlements').readAsStringSync();
      expect(content, contains('keychain-access-groups'));
    });

    test('Debug config references DebugProfile', () {
      final pbxproj =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      // Find Debug configuration for Runner target
      final debugSection = pbxproj.substring(
          pbxproj.indexOf('97C147061CF9000F007C117D'),
          pbxproj.indexOf(
              'name = Debug;', pbxproj.indexOf('97C147061CF9000F007C117D')));
      expect(
          debugSection,
          contains(
              'CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements'));
    });

    test('Profile config references DebugProfile', () {
      final pbxproj =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      // Find Profile configuration for Runner target
      final profileSection = pbxproj.substring(
          pbxproj.indexOf('249021D4217E4FDB00AE95B9'),
          pbxproj.indexOf(
              'name = Profile;', pbxproj.indexOf('249021D4217E4FDB00AE95B9')));
      expect(
          profileSection,
          contains(
              'CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements'));
    });

    test('Release config references Release entitlements', () {
      final pbxproj =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      // Find Release configuration for Runner target
      final releaseSection = pbxproj.substring(
          pbxproj.indexOf('97C147071CF9000F007C117D'),
          pbxproj.indexOf(
              'name = Release;', pbxproj.indexOf('97C147071CF9000F007C117D')));
      expect(releaseSection,
          contains('CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements'));
    });

    test('no hardcoded Team ID', () {
      final debugContent =
          File('ios/Runner/DebugProfile.entitlements').readAsStringSync();
      final releaseContent =
          File('ios/Runner/Release.entitlements').readAsStringSync();
      // Team IDs are typically 10 alphanumeric characters
      expect(debugContent, isNot(contains('DEVELOPMENT_TEAM')));
      expect(releaseContent, isNot(contains('DEVELOPMENT_TEAM')));
    });

    test('no hardcoded AppIdentifierPrefix', () {
      final debugContent =
          File('ios/Runner/DebugProfile.entitlements').readAsStringSync();
      final releaseContent =
          File('ios/Runner/Release.entitlements').readAsStringSync();
      expect(debugContent, isNot(contains('AppIdentifierPrefix')));
      expect(releaseContent, isNot(contains('AppIdentifierPrefix')));
    });
  });
}

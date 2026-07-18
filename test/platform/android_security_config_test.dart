import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Security Config', () {
    test('main Manifest contains INTERNET permission', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android.permission.INTERNET'));
    });

    test('main Manifest declares background generation permissions', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android.permission.FOREGROUND_SERVICE'));
      expect(manifest,
          contains('android.permission.FOREGROUND_SERVICE_DATA_SYNC'));
    });

    test('main Manifest registers dataSync generation service', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:name=".KeyChatApplication"'));
      expect(manifest, contains('android:name=".BackgroundGenerationService"'));
      expect(manifest, contains('android:foregroundServiceType="dataSync"'));
    });

    test('main Manifest has allowBackup=false', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
    });

    test('main Manifest references backup_rules', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
          manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    });

    test('main Manifest references data_extraction_rules', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest,
          contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    });

    test('main Manifest references network_security_config', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
          manifest,
          contains(
              'android:networkSecurityConfig="@xml/network_security_config"'));
    });

    test('main Manifest does not have usesCleartextTraffic=true', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    });

    test('network_security_config has cleartextTrafficPermitted=false', () {
      final config =
          File('android/app/src/main/res/xml/network_security_config.xml')
              .readAsStringSync();
      expect(config, contains('cleartextTrafficPermitted="false"'));
    });

    test('backup_rules.xml exists', () {
      final file = File('android/app/src/main/res/xml/backup_rules.xml');
      expect(file.existsSync(), isTrue);
    });

    test('data_extraction_rules.xml exists', () {
      final file =
          File('android/app/src/main/res/xml/data_extraction_rules.xml');
      expect(file.existsSync(), isTrue);
    });

    test('backup_rules has no include', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      expect(content, isNot(contains('<include ')));
    });

    test('data_extraction_rules has no include', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      expect(content, isNot(contains('<include ')));
    });

    test('backup_rules has exactly 9 exclude elements', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      final excludeCount = RegExp(r'<exclude\s').allMatches(content).length;
      expect(excludeCount, equals(9));
    });

    test('backup_rules all excludes have domain and path', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      final excludePattern =
          RegExp(r'<exclude\s+domain="[^"]+"\s+path="[^"]+"\s*/>');
      final matches = excludePattern.allMatches(content).length;
      expect(matches, equals(9));
    });

    test('backup_rules all excludes have path="./"', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      final pathPattern = RegExp(r'path="\./"');
      final matches = pathPattern.allMatches(content).length;
      expect(matches, equals(9));
    });

    test('backup_rules excludes all standard domains', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      final requiredDomains = [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
        'device_root',
        'device_file',
        'device_database',
        'device_sharedpref'
      ];
      for (final domain in requiredDomains) {
        expect(content, contains('domain="$domain"'));
      }
    });

    test('data_extraction_rules has cloud-backup section', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      expect(content, contains('<cloud-backup>'));
      expect(content, contains('</cloud-backup>'));
    });

    test('data_extraction_rules has device-transfer section', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      expect(content, contains('<device-transfer>'));
      expect(content, contains('</device-transfer>'));
    });

    test('cloud-backup has exactly 9 exclude elements', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final cloudBackupSection = content.substring(
          content.indexOf('<cloud-backup>'),
          content.indexOf('</cloud-backup>'));
      final excludeCount =
          RegExp(r'<exclude\s').allMatches(cloudBackupSection).length;
      expect(excludeCount, equals(9));
    });

    test('cloud-backup all excludes have domain and path', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final cloudBackupSection = content.substring(
          content.indexOf('<cloud-backup>'),
          content.indexOf('</cloud-backup>'));
      final excludePattern =
          RegExp(r'<exclude\s+domain="[^"]+"\s+path="[^"]+"\s*/>');
      final matches = excludePattern.allMatches(cloudBackupSection).length;
      expect(matches, equals(9));
    });

    test('cloud-backup all excludes have path="./"', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final cloudBackupSection = content.substring(
          content.indexOf('<cloud-backup>'),
          content.indexOf('</cloud-backup>'));
      final pathPattern = RegExp(r'path="\./"');
      final matches = pathPattern.allMatches(cloudBackupSection).length;
      expect(matches, equals(9));
    });

    test('cloud-backup excludes all standard domains', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final cloudBackupSection = content.substring(
          content.indexOf('<cloud-backup>'),
          content.indexOf('</cloud-backup>'));
      final requiredDomains = [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
        'device_root',
        'device_file',
        'device_database',
        'device_sharedpref'
      ];
      for (final domain in requiredDomains) {
        expect(cloudBackupSection, contains('domain="$domain"'));
      }
    });

    test('device-transfer has exactly 9 exclude elements', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final deviceTransferSection = content.substring(
          content.indexOf('<device-transfer>'),
          content.indexOf('</device-transfer>'));
      final excludeCount =
          RegExp(r'<exclude\s').allMatches(deviceTransferSection).length;
      expect(excludeCount, equals(9));
    });

    test('device-transfer all excludes have domain and path', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final deviceTransferSection = content.substring(
          content.indexOf('<device-transfer>'),
          content.indexOf('</device-transfer>'));
      final excludePattern =
          RegExp(r'<exclude\s+domain="[^"]+"\s+path="[^"]+"\s*/>');
      final matches = excludePattern.allMatches(deviceTransferSection).length;
      expect(matches, equals(9));
    });

    test('device-transfer all excludes have path="./"', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final deviceTransferSection = content.substring(
          content.indexOf('<device-transfer>'),
          content.indexOf('</device-transfer>'));
      final pathPattern = RegExp(r'path="\./"');
      final matches = pathPattern.allMatches(deviceTransferSection).length;
      expect(matches, equals(9));
    });

    test('device-transfer excludes all standard domains', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final deviceTransferSection = content.substring(
          content.indexOf('<device-transfer>'),
          content.indexOf('</device-transfer>'));
      final requiredDomains = [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
        'device_root',
        'device_file',
        'device_database',
        'device_sharedpref'
      ];
      for (final domain in requiredDomains) {
        expect(deviceTransferSection, contains('domain="$domain"'));
      }
    });

    test('no duplicate domains in backup_rules', () {
      final content = File('android/app/src/main/res/xml/backup_rules.xml')
          .readAsStringSync();
      final domainPattern = RegExp(r'domain="([^"]+)"');
      final domains =
          domainPattern.allMatches(content).map((m) => m.group(1)).toList();
      expect(domains.length, equals(domains.toSet().length));
    });

    test('no duplicate domains in cloud-backup', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final cloudBackupSection = content.substring(
          content.indexOf('<cloud-backup>'),
          content.indexOf('</cloud-backup>'));
      final domainPattern = RegExp(r'domain="([^"]+)"');
      final domains = domainPattern
          .allMatches(cloudBackupSection)
          .map((m) => m.group(1))
          .toList();
      expect(domains.length, equals(domains.toSet().length));
    });

    test('no duplicate domains in device-transfer', () {
      final content =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      final deviceTransferSection = content.substring(
          content.indexOf('<device-transfer>'),
          content.indexOf('</device-transfer>'));
      final domainPattern = RegExp(r'domain="([^"]+)"');
      final domains = domainPattern
          .allMatches(deviceTransferSection)
          .map((m) => m.group(1))
          .toList();
      expect(domains.length, equals(domains.toSet().length));
    });
  });
}

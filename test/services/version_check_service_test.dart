import 'package:cafe_bda/models/app_config.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/services/version_check_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// Note: package_info_plus usually requires platform channel mocking

import '../mocks.mocks.dart';

void main() {
  late VersionCheckService service;
  late MockGoogleSheetsService mockSheetsService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockSheetsService = MockGoogleSheetsService();
    service = VersionCheckService(mockSheetsService);

    // Mock PackageInfo via MethodChannel
    // The channel name for package_info_plus is usually 'dev.fluttercommunity.plus/package_info'
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'CafeBDA',
            'packageName': 'com.example.cafe_bda',
            'version': '1.5.0', // Local version for testing
            'buildNumber': '1'
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('VersionCheckService - Schema Compliance (Application Sheet)', () {
    test('Returns updateRequired when local version < minCompatible', () async {
      // Config: Min = 2.0.0, Local is 1.5.0
      final config = AppConfig(
        latestVersion: '2.1.0',
        minCompatibleVersion: '2.0.0',
        downloadUrl: 'http://update.com'
      );
      
      when(mockSheetsService.getAppConfig()).thenAnswer((_) async => config);

      final result = await service.checkVersion();

      expect(result.status, VersionStatus.updateRequired);
      expect(result.downloadUrl, 'http://update.com');
    });

    test('Returns updateAvailable when local < latest but >= minCompatible', () async {
      // Config: Min = 1.0.0, Latest = 1.6.0, Local is 1.5.0
      final config = AppConfig(
        latestVersion: '1.6.0',
        minCompatibleVersion: '1.0.0',
        downloadUrl: 'http://update.com'
      );
      
      when(mockSheetsService.getAppConfig()).thenAnswer((_) async => config);

      final result = await service.checkVersion();

      expect(result.status, VersionStatus.updateAvailable);
    });

    test('Returns upToDate when local == latest', () async {
      // Config: Latest = 1.5.0, Local is 1.5.0
      final config = AppConfig(
        latestVersion: '1.5.0',
        minCompatibleVersion: '1.0.0',
        downloadUrl: 'http://update.com'
      );
      
      when(mockSheetsService.getAppConfig()).thenAnswer((_) async => config);

      final result = await service.checkVersion();

      expect(result.status, VersionStatus.upToDate);
    });
    
    test('Returns upToDate when local > latest', () async {
      // Config: Latest = 1.0.0, Local is 1.5.0 (Dev build?)
      final config = AppConfig(
        latestVersion: '1.0.0',
        minCompatibleVersion: '1.0.0',
        downloadUrl: 'http://update.com'
      );
      
      when(mockSheetsService.getAppConfig()).thenAnswer((_) async => config);

      final result = await service.checkVersion();

      expect(result.status, VersionStatus.upToDate);
    });

    test('Returns unknown if config is null', () async {
      when(mockSheetsService.getAppConfig()).thenAnswer((_) async => null);

      final result = await service.checkVersion();

      expect(result.status, VersionStatus.unknown);
    });
  });
}

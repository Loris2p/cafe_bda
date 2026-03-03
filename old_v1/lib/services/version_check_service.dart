import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum VersionStatus {
  upToDate,
  updateAvailable,
  updateRequired,
  unknown,
}

class VersionCheckResult {
  final VersionStatus status;
  final String? localVersion;
  final String? latestVersion;
  final String? downloadUrl;

  VersionCheckResult({
    required this.status,
    this.localVersion,
    this.latestVersion,
    this.downloadUrl,
  });
}

class VersionCheckService {
  final GoogleSheetsService _sheetsService;

  VersionCheckService(this._sheetsService);

  Future<VersionCheckResult> checkVersion() async {
    try {
      // 1. Récupérer la version locale
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersionStr = packageInfo.version; // Ex: 1.0.0

      // 2. Récupérer la config distante
      final config = await _sheetsService.getAppConfig();
      if (config == null) {
        return VersionCheckResult(status: VersionStatus.unknown);
      }

      // 3. Comparer les versions
      final localVersion = _parseVersion(localVersionStr);
      final latestVersion = _parseVersion(config.latestVersion);
      final minVersion = _parseVersion(config.minCompatibleVersion);

      if (_isVersionLower(localVersion, minVersion)) {
        return VersionCheckResult(
          status: VersionStatus.updateRequired,
          localVersion: localVersionStr,
          latestVersion: config.latestVersion,
          downloadUrl: config.downloadUrl,
        );
      } else if (_isVersionLower(localVersion, latestVersion)) {
        return VersionCheckResult(
          status: VersionStatus.updateAvailable,
          localVersion: localVersionStr,
          latestVersion: config.latestVersion,
          downloadUrl: config.downloadUrl,
        );
      } else {
        return VersionCheckResult(
          status: VersionStatus.upToDate,
          localVersion: localVersionStr,
          latestVersion: config.latestVersion,
          downloadUrl: config.downloadUrl,
        );
      }
    } catch (e) {
      print('Erreur lors de la vérification de version: $e');
      return VersionCheckResult(status: VersionStatus.unknown);
    }
  }

  /// Parse "1.2.3" -> [1, 2, 3]
  List<int> _parseVersion(String version) {
    try {
      // Enlever le suffixe de build (+1) si présent
      final cleanVersion = version.split('+')[0]; 
      return cleanVersion.split('.').map((e) => int.parse(e)).toList();
    } catch (e) {
      return [0, 0, 0];
    }
  }

  /// Retourne true si v1 < v2
  bool _isVersionLower(List<int> v1, List<int> v2) {
    for (int i = 0; i < v1.length && i < v2.length; i++) {
      if (v1[i] < v2[i]) return true;
      if (v1[i] > v2[i]) return false;
    }
    // Si longueurs différentes (ex: 1.0 vs 1.0.1)
    if (v1.length < v2.length) return true;
    return false;
  }
}

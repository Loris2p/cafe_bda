class AppConfig {
  final String latestVersion;
  final String minCompatibleVersion;
  final String downloadUrl;

  AppConfig({
    required this.latestVersion,
    required this.minCompatibleVersion,
    required this.downloadUrl,
  });

  factory AppConfig.fromMap(Map<String, String> map) {
    return AppConfig(
      latestVersion: map['latest_version'] ?? '1.0.0',
      minCompatibleVersion: map['min_compatible_version'] ?? '1.0.0',
      downloadUrl: map['download_url'] ?? '',
    );
  }
}

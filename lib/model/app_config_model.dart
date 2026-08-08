class AppConfigModel {
  final String latestVersion;
  final List<int> supportedVersions;
  final bool forceUpdate;
  final String playStoreUrl;
  final String appStoreUrl;
  final String privacyPolicyUrl;

  AppConfigModel({
    required this.latestVersion,
    required this.supportedVersions,
    required this.forceUpdate,
    required this.playStoreUrl,
    required this.appStoreUrl,
    required this.privacyPolicyUrl,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final appVersion = json['app_version'] ?? {};
    final urls = json['urls'] ?? {};

    return AppConfigModel(
      latestVersion: appVersion['latest_version'] ?? '1.0.0',
      supportedVersions: List<int>.from(appVersion['supported_versions'] ?? [1]),
      forceUpdate: appVersion['force_update'] ?? false,
      playStoreUrl: urls['play_store'] ?? '',
      appStoreUrl: urls['app_store'] ?? '',
      privacyPolicyUrl: urls['privacy_policy'] ?? '',
    );
  }
}
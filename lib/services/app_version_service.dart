import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionPolicy {
  const AppVersionPolicy({
    required this.minimumVersion,
    required this.latestVersion,
    required this.androidUrl,
    required this.iosUrl,
    required this.message,
  });

  final String minimumVersion;
  final String latestVersion;
  final String androidUrl;
  final String iosUrl;
  final String message;

  String get updateUrl => androidUrl.isNotEmpty ? androidUrl : iosUrl;
}

class AppVersionService {
  AppVersionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = String.fromEnvironment('API_URL');

  Future<({String installedVersion, AppVersionPolicy policy, bool isBlocked})>
  checkVersion() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/app/version'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Não foi possível consultar a versão do aplicativo.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final policy = AppVersionPolicy(
      minimumVersion: data['minimum_version'] as String,
      latestVersion: data['latest_version'] as String,
      androidUrl: data['android_url'] as String? ?? '',
      iosUrl: data['ios_url'] as String? ?? '',
      message: data['message'] as String? ?? 'Atualize o aplicativo para continuar.',
    );
    final packageInfo = await PackageInfo.fromPlatform();
    return (
      installedVersion: packageInfo.version,
      policy: policy,
      isBlocked: _compareVersions(packageInfo.version, policy.minimumVersion) < 0,
    );
  }

  static int _compareVersions(String current, String minimum) {
    final currentParts = current.split('.').map((part) => int.tryParse(part) ?? 0);
    final minimumParts = minimum.split('.').map((part) => int.tryParse(part) ?? 0);
    final currentList = currentParts.toList();
    final minimumList = minimumParts.toList();
    final length = currentList.length > minimumList.length
        ? currentList.length
        : minimumList.length;
    for (var i = 0; i < length; i++) {
      final a = i < currentList.length ? currentList[i] : 0;
      final b = i < minimumList.length ? minimumList[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }
}

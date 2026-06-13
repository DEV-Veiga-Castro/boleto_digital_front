import 'dart:convert';

import 'package:boleto_digital/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientStorage {
  User? _user;

  User? get user => _user;

  Future<void> setTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<bool> isLoggedIn() async {
    String? accessToken = await getAccessToken();

    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Verifica se o access token ainda é válido (decodifica o payload JWT e checa o `exp`).
  Future<bool> isAccessTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      // Normaliza e decodifica base64Url
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded);

      if (payloadMap is! Map) return false;

      if (!payloadMap.containsKey('exp')) return false;

      final expVal = payloadMap['exp'];
      final exp = expVal is int ? expVal : int.tryParse(expVal.toString());
      if (exp == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  Future<User?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? userProfileString = prefs.getString('user_profile');
    
    if (userProfileString != null) {
      _user = User.fromJson(jsonDecode(userProfileString));
      return _user;
    }

    return null;
  }

  Future<void> setUserProfile(User userProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(userProfile.toJson()));
    _user = userProfile;
  }
}

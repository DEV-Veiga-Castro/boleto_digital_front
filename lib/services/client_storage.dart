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

  Future<void> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? userProfileString = prefs.getString('user_profile');
    if (userProfileString != null) {
      _user = User.fromJson(jsonDecode(userProfileString));
    }
  }

  Future<void> setUserProfile(User userProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(userProfile.toJson()));
    _user = userProfile;
  }
}

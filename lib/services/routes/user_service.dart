import 'dart:convert';

import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:http/http.dart' as http;

class UserService {
  var baseUrl = const String.fromEnvironment('API_URL');

  Future<User?> getUserProfile({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/user/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        return User.fromJson(jsonDecode(response.body));
      }

      if (response.statusCode == 401) {
        await AuthService().logout();
        return null;
      }

      return null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }
}

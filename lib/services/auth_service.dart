import 'dart:convert';

import 'package:boleto_digital/services/client_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  var baseUrl = const String.fromEnvironment('API_URL');

  Future<bool> login(String username, String password) async {
    print("URL API:$baseUrl");
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'login': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        print(accessToken);

        if (accessToken != null && refreshToken != null) {
          await ClientStorage().setTokens(accessToken, refreshToken);
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Error logging in: $e");
      return false;
    }
  }
}

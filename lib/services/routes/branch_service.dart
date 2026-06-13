import 'dart:convert';

import 'package:boleto_digital/models/branch_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:http/http.dart' as http;

class BranchService {
  var baseURL = const String.fromEnvironment('API_URL');

  Future<List<Branch>?> listBranch({
    required String accessToken,
  }) async {
    final url = Uri.parse("$baseURL/branch/");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // print(data);
        final branches = (data as List)
            .map((item) => Branch.fromJson(item))
            .toList();

        return branches;
      }

      if (response.statusCode == 401) {
        AuthService().logout();
        // return
      }

      return null;
    } catch (e) {
      print("Erro ao listar filiais: $e");
      return null;
    }
  }
}

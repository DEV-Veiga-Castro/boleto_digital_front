import 'dart:convert';

import 'package:boleto_digital/services/auth_service.dart';
import 'package:http/http.dart' as http;

class DigitalTransferService {
  var baseURL = const String.fromEnvironment('API_URL');

  Future<int> countMovimentacoes({
    required String accessToken,
    required String status,
  }) async {
    // Contagem de movimentações com status "PENDENTE/EM TRANSITO" ou "RECEBIDA"
    final url = Uri.parse('$baseURL/dt/in?status_transfer=$status');

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

        return data['count'] as int;
      } else if (response.statusCode == 401) {
        // Se o token for inválido ou expirado, desloga o usuário
        await AuthService().logout();
      }

      return 0;
    } catch (e) {
      print("Error fetching movimentacoes: $e");
      return 0;
    }
  }

  Future<int> createMovimentacao({required String accessToken}) async {
    final url = Uri.parse('$baseURL/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return data['transfer_id'] as int;
      }
    } catch (e) {
      print("Erro ao salvar movimentação: $e");
      return 0;
    }

    return 0;
  }
}

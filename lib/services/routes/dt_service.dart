import 'dart:convert';

import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  Future<int> createMovimentacao({
    required String accessToken,
    required DigitalTransfer digitalTransfer,
  }) async {
    final url = Uri.parse('$baseURL/dt/');

    try {
      // print(digitalTransfer.runtimeType);

      // print(digitalTransfer.toJson());

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(digitalTransfer.toJson()),
      );

      print("STATUS: ${response.statusCode}");
      print("DETAIL BODY: ${response.body}");

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

  Future<String> updateMovimentacaoItems({
    required String accessToken,
    required int transferID,
    required List<DigitalTransferItems> digitalItems,
  }) async {
    final url = Uri.parse("$baseURL/dt/update/itens/$transferID");

    try {
      final body = jsonEncode({
        'items': digitalItems.map((e) => e.toJson()).toList(),
      });

      print(body);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      print("STATUS: ${response.statusCode}");
      print("DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['message'];
      } else {
        final data = jsonDecode(response.body);

        return data['detail'];
      }
    } catch (e) {
      print(e);
      return "Ocorreu um erro ao atualizar os itens: $e";
    }
  }

  Future<List<DigitalTransfer>?> listMovimentacoes({
    required String accessToken,
    int limit = 50,
    int offset = 0,
  }) async {
    final url = Uri.parse('$baseURL/dt/?limit=$limit&offset=$offset');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY:: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final history = (data as List)
            .map((item) => DigitalTransfer.fromJson(item))
            .toList();

        return history;
      }

      if (response.statusCode == 401) {
        AuthService().logout();
      }

      return null;
    } catch (e) {
      print('Erro ao listar Movimentações: $e');

      return null;
    }
  }

  Future<String> updateTransferStatus({
    required String accessToken,
    required int transferID,
    required String status,
  }) async {
    final url = Uri.parse('$baseURL/dt/update/status/$transferID');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"status": status}),
      );

      print("BODY:: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'];
      } else {
        return data['detail'];
      }
    } catch (e) {
      return "Ocorreu um erro: {$e}";
    }
  }

  Future<List<dynamic>?> listFilteredMovimentacoes({
    required String accessToken,
    required int branchPDV,
    int? transferID,
    int? nfNumber,
    String? status,
    int? productCode,
    List<dynamic>? period,
  }) async {
    String search_url = "branch_id=$branchPDV";

    if (transferID != null) {
      search_url = "$search_url&id_transf=$transferID";
    }

    if (nfNumber != null) {
      search_url = "$search_url&nf_number=$nfNumber";
    }

    if (status != null) {
      search_url = "$search_url&status_transfer=$status";
    }

    if (productCode != null) {
      search_url = "$search_url&product_code=$productCode";
    }

    if (period != null) {
      String _inicio = DateFormat('yyyy-MM-dd').format(period[0]);
      String _final = DateFormat('yyyy-MM-dd').format(period[1]);

      search_url =
          "$search_url&transfer_period=$_inicio&transfer_period=$_final";
    }

    final url = Uri.parse('$baseURL/dt/search?$search_url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("BODY:: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final history = (data as List)
            .map((item) => DigitalTransfer.fromJson(item))
            .toList();

        return history;
      } else {
        return (data as List);
      }
    } catch (e) {
      return ["Ocorreu um erro: $e"];
    }
  }
}

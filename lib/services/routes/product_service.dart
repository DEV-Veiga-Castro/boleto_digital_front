import 'dart:convert';

import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ProductService {
  var baseURL = const String.fromEnvironment('API_URL');

  Future<List<ProductModel>?> listProducts({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseURL/product/?return_size=100000');

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

        final products = (data as List)
            .map((item) => ProductModel.fromJson(item))
            .toList();

        return products;
      }

      if (response.statusCode == 401) {
        AuthService().logout();
      }

      return null;
    } catch (e) {
      print("Erro ao listar produtos: $e");
      return null;
    }
  }

  Future<List<ProductModel>?> searchProduct({
    required String accessToken,
    required String product,
  }) async {
    final url = Uri.parse('$baseURL/product/search?q=$product');

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

        final products = (data as List)
            .map((item) => ProductModel.fromJson(item))
            .toList();

        return products;
      }

      if (response.statusCode == 401) {
        AuthService().logout();
      }

      return null;
    } catch (e) {
      print("Erro ao buscar produto: $e");
      return null;
    }
  }
}

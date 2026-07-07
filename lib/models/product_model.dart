import 'package:boleto_digital/services/routes/product_service.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  int? id;
  String? name;
  int? percentualDesconto;

  CategoryModel({required this.id, this.name, this.percentualDesconto});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as int?,
    name: json['name'] as String?,
    percentualDesconto: json['percentual_desconto'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'percentual_desconto': percentualDesconto,
  };
}

class ProductModel {
  int? codProduct;
  String? description;
  double? price;
  CategoryModel? category;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  ProductModel({
    required this.codProduct,
    required this.description,
    this.price,
    this.category,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    codProduct: json['cod_product'] as int?,
    description: json['description'] as String?,
    category: json['category'] != null
        ? CategoryModel.fromJson(json['category'])
        : null,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    isActive: json['is_active'] ?? true,
    updatedAt: json['updated_at'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'cod_product': codProduct,
    'description': description,
    'category': category,
    'price': price,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  bool get hasProducts => _products.isNotEmpty;

  void setProducts(List<ProductModel> products) {
    _products = products;
    notifyListeners();
  }

  Future<List<ProductModel>?> searchProduct(
    {
      String? token, 
      String? product
    }) async {
    if (_products.isEmpty) return Future.value(null);

    final data = await _service.searchProduct(accessToken: token!, product: product!);

    if (data != null && data.isNotEmpty) {
      return data;
    }

    return Future.value(null);
  }

  Future<void> loadProducts(String? token) async {
    final data = await _service.listProducts(accessToken: token!);

    if (data != null) {
      _products = data;
      notifyListeners();
    }
  }

  bool searchProducts(int? productCode) {
    if (_products.isEmpty) return false;

    final index = _products.indexWhere(
      (item) => item.codProduct == productCode,
    );

    if (index != -1) {
      return true;
    } else {
      return false;
    }
  }

  String getDescription(int productID) {
    if (_products.isEmpty) return 'Descrição';

    final index = _products.indexWhere((item) => item.codProduct == productID);

    if (index != -1) {
      return _products[index].description ?? 'Descrição';
    } else {
      return 'Descrição';
    }
  }

  void clearProducts() {
    _products.clear();
    notifyListeners();
  }
}

import 'package:boleto_digital/services/routes/branch_service.dart';
import 'package:flutter/material.dart';

class Branch {
  String? name;
  int? pdv;
  String? address;
  String? phone;
  String? city;
  String? state;
  String? cnpj;
  bool? isActive;

  Branch({
    required this.name,
    required this.pdv,
    required this.address,
    this.phone,
    required this.city,
    required this.state,
    required this.cnpj,
    this.isActive,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    pdv: json['pdv'] as int?,
    name: json['name'] as String?,
    address: json['address'] as String?,
    phone: json['phone'] ?? '' as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    cnpj: json['cnpj'] as String?,
    isActive: json['is_active'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'pdv': pdv,
    'name': name,
    'address': address,
    'phone': phone,
    'city': city,
    'state': state,
    'cnpj': cnpj,
    'is_active': isActive,
  };
}

class BranchProvider extends ChangeNotifier {
  final BranchService _service = BranchService();

  List<Branch> _branches = [];

  List<Branch> get branches => _branches;

  bool get hasBranches => _branches.isNotEmpty;

  void setBranches(List<Branch> branches) {
    _branches = branches;
    notifyListeners();
  }

  Future<void> loadBranches(String? token) async {
    final data = await _service.listBranch(accessToken: token!);

    if (data != null) {
      _branches = data;
      notifyListeners();
    }
  }

  void clearBranches() {
    _branches.clear();
    notifyListeners();
  }
}

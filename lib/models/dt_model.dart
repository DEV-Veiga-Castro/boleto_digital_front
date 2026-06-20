import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:flutter/material.dart';

class DigitalTransferItems {
  int? id;
  int? productID;
  int? quantitySent;
  int? quantityReceived;

  DigitalTransferItems({
    this.id,
    required this.productID,
    required this.quantitySent,
    this.quantityReceived,
  });

  factory DigitalTransferItems.fromJson(Map<String, dynamic> json) =>
      DigitalTransferItems(
        id: json['digital_transfer_id'] as int?,
        productID: json['product_id'] as int?,
        quantitySent: json['quantity_sent'] as int?,
        quantityReceived: json['quantity_received'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'digital_transfer_id': id,
    'product_id': productID,
    'quantity_sent': quantitySent,
    'quantity_received': quantityReceived,
  };
}

class DigitalTransfer {
  int? id;
  int? lojaOrigem;
  int? lojaDestino;
  String? tipoTransferencia;
  int? sendedBy;
  int? receivedBy;
  String? nfNumber;
  String? comments;
  String? status;
  // List<Map<String, dynamic>> items;
  List<DigitalTransferItems> items;
  String? createdAt;

  DigitalTransfer({
    this.id,
    required this.lojaOrigem,
    required this.lojaDestino,
    required this.tipoTransferencia,
    required this.sendedBy,
    this.receivedBy,
    this.nfNumber,
    this.comments,
    this.status,
    required this.items,
    this.createdAt
  });

  factory DigitalTransfer.fromJson(Map<String, dynamic> json) =>
      DigitalTransfer(
        id: json['id'] as int?,
        lojaOrigem: json['loja_origem'] as int?,
        lojaDestino: json['loja_destino'] as int?,
        tipoTransferencia: json['tipo_transferencia'] as String?,
        sendedBy: json['sended_by'] as int?,
        receivedBy: json['received_by'] as int?,
        nfNumber: json['nf_number'] as String?,
        comments: json['comments'] as String?,
        status: json['status'] as String? ?? "em_andamento",
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => DigitalTransferItems.fromJson(item))
            .toList(),
        createdAt: json['created_at'] as String?
      );

  Map<String, dynamic> toJson() => {
    'loja_origem': lojaOrigem,
    'loja_destino': lojaDestino,
    'tipo_transferencia': tipoTransferencia,
    'sended_by': sendedBy,
    'received_by': receivedBy,
    'nf_number': nfNumber,
    'comments': comments,
    'status': status,
    'items': items.map(((e) => e.toJson())).toList(),
    'created_at': createdAt
  };
}

class TransferProvider extends ChangeNotifier {
  DigitalTransfer? _transfer;

  DigitalTransfer? get transfer => _transfer;

  Future<void> setTransfer(DigitalTransfer value, String accessToken) async {
    print("TRANFER ATUAL:: $transfer");
    if (transfer != null) return;

    _transfer = value;

    final transferID = await DigitalTransferService().createMovimentacao(
      accessToken: accessToken,
      digitalTransfer: _transfer!,
    );

    if (transferID != 0) {
      value.id = transferID;
    }

    notifyListeners();
  }

  void addItem(int productID) {
    if (_transfer == null) return;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      _transfer!.items[index].quantitySent =
          (_transfer!.items[index].quantitySent ?? 0) + 1;
    } else {
      _transfer!.items.add(
        DigitalTransferItems(
          id: _transfer!.id,
          productID: productID,
          quantitySent: 1,
          quantityReceived: 0,
        ),
      );
    }

    notifyListeners();
  }

  void subItem(int productID) {
    if (_transfer == null) return;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      _transfer!.items[index].quantitySent =
          (_transfer!.items[index].quantitySent ?? 0) - 1;
    }

    notifyListeners();
  }

  bool removeItem(int productID) {
    if (_transfer == null) return false;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      _transfer!.items.removeAt(index);
    } else {
      return false;
    }

    return false;
  }

  int getQuantitySent(int productID) {
    if (_transfer == null) return 0;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      return _transfer!.items[index].quantitySent!;
    }

    return 0;
  }

  int getTotalQuantitySent() {
    if (_transfer == null) return 0;

    int total = 0;
    final length = _transfer!.items.length;

    for (int i = 0; i < length; i++) {
      total += _transfer!.items[i].quantitySent!;
    }

    return total;
  }

  void clear() {
    _transfer = null;
    notifyListeners();
  }
}

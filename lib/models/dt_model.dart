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
    'id': id,
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
  int? nfNumber;
  String? comments;
  String? status;
  // List<Map<String, dynamic>> items;
  List<DigitalTransferItems> items;

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
  });

  factory DigitalTransfer.fromJson(Map<String, dynamic> json) =>
      DigitalTransfer(
        id: json['id'] as int?,
        lojaOrigem: json['loja_origem'] as int?,
        lojaDestino: json['loja_destino'] as int?,
        tipoTransferencia: json['tipo_transferencia'] as String?,
        sendedBy: json['sended_by'] as int?,
        receivedBy: json['received_by'] as int?,
        nfNumber: json['nf_number'] as int?,
        comments: json['comments'] as String?,
        status: json['status'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => DigitalTransferItems.fromJson(item))
            .toList(),
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
  };
}

class TransferProvider extends ChangeNotifier {
  DigitalTransfer? _transfer;

  DigitalTransfer? get transfer => _transfer;

  Future<void> setTransfer(DigitalTransfer value, String accessToken) async {
    if (transfer != null) return;

    final int transferID = await DigitalTransferService().createMovimentacao(
      accessToken: accessToken,
    );

    value.id = transferID;

    _transfer = value;

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
          productID: productID,
          quantitySent: 1,
          quantityReceived: 0,
        ),
      );
    }

    notifyListeners();
  }

  void clear() {
    _transfer = null;
    notifyListeners();
  }
}

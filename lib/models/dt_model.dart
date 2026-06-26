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
  int? uuid;
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
    this.uuid,
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
    this.createdAt,
  });

  factory DigitalTransfer.fromJson(Map<String, dynamic> json) =>
      DigitalTransfer(
        uuid: json['uuid'] as int?,
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
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'id': id,
    'loja_origem': lojaOrigem,
    'loja_destino': lojaDestino,
    'tipo_transferencia': tipoTransferencia,
    'sended_by': sendedBy,
    'received_by': receivedBy,
    'nf_number': nfNumber,
    'comments': comments,
    'status': status,
    'items': items.map(((e) => e.toJson())).toList(),
    'created_at': createdAt,
  };
}

class TransferProvider extends ChangeNotifier {
  DigitalTransfer? _transfer;

  DigitalTransfer? get transfer => _transfer;

  void setReceiveTransfer(DigitalTransfer value) {
    if (transfer != null) {
      clear();
      notifyListeners();
    }

    _transfer = value;

    notifyListeners();
  }

  Future<void> setTransfer(
    DigitalTransfer value,
    String accessToken,
    int branchID,
  ) async {
    print("TRANFER ATUAL:: $transfer");
    if (transfer != null) return;

    _transfer = value;

    final data = await DigitalTransferService().listLastMovimentacao(
      accessToken: accessToken,
      branchID: branchID,
    );

    int _transferID = data["transfer_id"];
    int _transferUUID = data["transfer_uuid"];

    if (_transferUUID != -1) {
      value.id = _transferID + 1;
      value.uuid = _transferUUID + 1;
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
          id: _transfer!.uuid,
          productID: productID,
          quantitySent: 1,
          quantityReceived: 0,
        ),
      );
    }

    notifyListeners();
  }

  String addReceivedItem(int productID) {
    if (_transfer == null) return "";

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      _transfer!.items[index].quantityReceived =
          (_transfer!.items[index].quantityReceived ?? 0) + 1;
    } else {
      return "Produto não encontrado no envio!";
    }

    return "";
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

  void subReceivedItem(int productID) {
    if (_transfer == null) return;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      _transfer!.items[index].quantityReceived =
          (_transfer!.items[index].quantityReceived ?? 0) - 1;
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

  int getQuantityReceived(int productID) {
    if (_transfer == null) return 0;

    final index = _transfer!.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (index != -1) {
      return _transfer!.items[index].quantityReceived!;
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

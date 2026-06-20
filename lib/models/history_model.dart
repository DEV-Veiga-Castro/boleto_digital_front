import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:flutter/material.dart';

class DigitalTransferHistory {
  List<DigitalTransfer> digitalTransfer;

  DigitalTransferHistory({required this.digitalTransfer});

  factory DigitalTransferHistory.fromJson(Map<String, dynamic> json) =>
      DigitalTransferHistory(
        digitalTransfer: (json['digital_transfer'] as List<dynamic>? ?? [])
            .map((item) => DigitalTransfer.fromJson(item))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'digital_transfer': digitalTransfer.map(((e) => e.toJson())).toList(),
  };
}

class TransferHistoryProvider extends ChangeNotifier {
  final DigitalTransferService _service = DigitalTransferService();

  List<DigitalTransfer> _transfers = [];

  List<DigitalTransfer> get transfers => _transfers;

  Future<void> setHistory(List<DigitalTransfer> data) async {
    try {
      _transfers = data;

      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> getHistory(String accessToken, int actualBranch, List<dynamic> period) async {
    if (_transfers.isNotEmpty) return;

    final transfers = await DigitalTransferService().listFilteredMovimentacoes(
      accessToken: accessToken,
      branchPDV: actualBranch,
      period: period,
    );

    if (transfers != null && transfers is List<DigitalTransfer>) {
      _transfers = transfers;
    }

    notifyListeners();
  }

  void clear() {
    _transfers.clear();
    notifyListeners();
  }
}

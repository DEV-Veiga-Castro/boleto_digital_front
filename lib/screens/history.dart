import 'package:boleto_digital/models/branch_model.dart';
import 'package:boleto_digital/services/printer/print_bf.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';

import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/history_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:boleto_digital/theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = ClientStorage();

  String typeHistory = "Enviadas";

  DateTime? dataInicial = DateTime.now().subtract(Duration(days: 30)).toLocal();

  DateTime? dataFinal = DateTime.now();

  String? status;
  String? statusView;
  String? macAddress;

  TextEditingController numeroNF = TextEditingController();

  TextEditingController codigoProduto = TextEditingController();

  TextEditingController filterTransferID = TextEditingController();

  // Isso é pra tentar integrar um scroll lateral da página (para Enviadas e Recebidas)
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();

    debugPrint("Estou carregando a página HISTORY");
    _preLoadTransfers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> conectarImpressora() async {
    List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma impressora encontrada.")),
      );
      return;
    }

    // Escolhe a primeira impressora pareada
    macAddress = devices.first.macAdress;

    bool conectado = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(conectado ? "Impressora conectada" : "Falha ao conectar"),
      ),
    );
  }

  Future<bool> requestBluetooth() async {
    if (await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted) {
      return true;
    }

    return false;
  }

  Future<void> imprimir({DigitalTransfer? transfer}) async {
    bool isPermited = await requestBluetooth();

    if (!isPermited) return;

    if (macAddress == null) {
      await conectarImpressora();
    }

    bool conectado = await PrintBluetoothThermal.connectionStatus;

    if (!conectado) {
      return;
    }

    imprimirBoleto(
      transferID: transfer!.id,
      transferUUID: transfer.uuid,
      lojaOrigem: transfer.lojaOrigem,
      lojaDestino: transfer.lojaDestino,
      itens: transfer.items,
    );
  }

  Future<void> _updateTransferStatus({required int transferID}) async {
    bool hasAT = await _storage.isAccessTokenValid();

    if (!mounted) return;

    if (!hasAT) {
      AuthService().logout();
      setState(() {});
    }

    String? accessToken = await _storage.getAccessToken();

    String response = await DigitalTransferService().updateTransferStatus(
      accessToken: accessToken!,
      transferID: transferID,
      status: "cancelada",
      model: "send",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response, style: TextStyle(color: Colors.black)),
      ),
    );

    Navigator.pop(context);

    Navigator.pop(context);

    await _refreshTransfer();

    setState(() {});
  }

  Future<void> _showPopupModal({required int transferID}) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Cancelar Movimentação",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  "Tem certeza que deseja cancelar essa movimentação?",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Voltar",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                _updateTransferStatus(transferID: transferID);
              },
              child: const Text(
                "Confirmar",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTransferModal(
    BuildContext context,
    DigitalTransfer transfer,
  ) async {
    final productProvider = context.read<ProductProvider>();
    final filiais = context.watch<BranchProvider>().branches;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Consumer<TransferProvider>(
          builder: (context, transferProvider, child) {
            return Container(
              height: 350,
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.cinzaContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "VC-${transfer.id}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                spacing: 12,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await imprimir(transfer: transfer);
                                    },
                                    icon: Icon(
                                      Icons.print_outlined,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showPopupModal(
                                        transferID: transfer.uuid!,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete_outline_outlined,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Divider(color: Colors.grey.withAlpha(100)),
                        ),
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "Destino: ",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${transfer.lojaDestino} - ${filiais.firstWhere(
                                      (e) => e.pdv == transfer.lojaDestino,
                                      orElse: () => Branch(pdv: -1, name: "Loja não encontrada", address: "", city: "", cnpj: "", state: ""),
                                    ).name}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "Origem: ",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${transfer.lojaOrigem}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Divider(color: Colors.grey.withAlpha(100)),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: Text(
                            "ITENS",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = transfer.items[index];

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cinzaContainer.withAlpha(100),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.verdeBoti,
                                    blurRadius: 2,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: AppColors.cinzaContainer,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  leading: Text(
                                    '${item.productID}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  title: Text(
                                    productProvider.getDescription(
                                      item.productID!,
                                    ),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${item.quantitySent}x',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: transfer.items.length),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFilterModal(BuildContext context, double? viewWidth) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final Map<String, String> statusList = {
      "em_andamento": "EM ANDAMENTO",
      "em_conferencia": "EM CONFERÊNCIA",
      "conferida": "CONFERIDA",
      "nf_lancada": "NF LANÇADA",
      "finalizada": "FINALIZADA",
      "cancelada": "CANCELADA",
    };

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 450,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cinzaContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.transparent)],
              ),
              child: SizedBox(
                width: viewWidth! * 0.9,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "FILTRAGEM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Icon(
                              Icons.filter_list_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final selectedDate = await _selectedDate();

                                if (selectedDate != null) {
                                  if (selectedDate.isAfter(dataFinal!)) {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "A Data Inicial não pode ser maior que a Data Final!",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        backgroundColor: Colors.amber,
                                      ),
                                    );
                                  } else {
                                    dataInicial = selectedDate;
                                  }
                                }

                                await _refreshTransfer();

                                setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cinzaContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 2,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  spacing: 12,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Data Inicial",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${dataInicial!.day.toString().length < 2 ? '0${dataInicial!.day}' : '${dataInicial!.day}'}/${dataInicial!.month.toString().length < 2 ? '0${dataInicial!.month}' : '${dataInicial!.month}'}/${dataInicial!.year}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final selectedDate = await _selectedDate();

                                if (selectedDate != null) {
                                  if (selectedDate.isBefore(dataInicial!)) {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "A Data Final não pode ser menor que a Data Inicial!",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        backgroundColor: Colors.amber,
                                      ),
                                    );
                                  } else {
                                    dataFinal = selectedDate;
                                  }
                                }

                                setModalState(() {});

                                await _refreshTransfer();
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cinzaContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 2,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  spacing: 12,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Data Final",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${dataFinal!.day.toString().length < 2 ? '0${dataFinal!.day}' : '${dataFinal!.day}'}/${dataFinal!.month.toString().length < 2 ? '0${dataFinal!.month}' : '${dataFinal!.month}'}/${dataFinal!.year}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: viewWidth * 0.78,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Status da Movimentação:",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    statusView ?? "",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              MenuAnchor(
                                // alignmentOffset: Offset(dx, dy),
                                style: MenuStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Colors.white,
                                  ),
                                  elevation: WidgetStatePropertyAll(2),
                                  shadowColor: WidgetStatePropertyAll(
                                    Colors.grey,
                                  ),
                                ),
                                builder: (context, controller, child) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();

                                        setState(() {});
                                      } else {
                                        controller.open();

                                        setState(() {});
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 30,
                                      color: AppColors.verdeBoti,
                                    ),
                                  );
                                },
                                menuChildren: statusList.entries.map((item) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      setModalState(() {
                                        status = item.key;
                                        statusView = item.value;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size(120, 60),
                                    ),
                                    child: Text(
                                      item.value,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: viewWidth * 0.78,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: codigoProduto,
                            keyboardType: TextInputType.numberWithOptions(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Código do Produto",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: viewWidth * 0.78,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: numeroNF,
                            keyboardType: TextInputType.numberWithOptions(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Número da NF",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await _refreshTransfer();

                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.verdeBoti,
                            shadowColor: Colors.white,
                            maximumSize: Size(viewWidth * 0.78, 60),
                          ),
                          child: Row(
                            spacing: 2,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "FILTRAR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_right,
                                size: 30,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectedDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dataFinal!,
      firstDate: DateTime.now().subtract(Duration(days: 90)),
      lastDate: DateTime.now(),
    );

    return pickedDate;
  }

  Future<void> _refreshTransfer() async {
    if (!mounted) return;

    List<dynamic>? data;
    String? accessToken = await _storage.getAccessToken();
    final user = context.read<UserProvider>().user;

    // print("TESTE ${user!.actualBranch}");

    if (filterTransferID.text.isNotEmpty) {
      data = await DigitalTransferService().listFilteredMovimentacoes(
        accessToken: accessToken!,
        branchPDV: user!.actualBranch!,
        transferID: int.parse(filterTransferID.text),
      );
    } else if (codigoProduto.text.isNotEmpty) {
      data = await DigitalTransferService().listFilteredMovimentacoes(
        accessToken: accessToken!,
        branchPDV: user!.actualBranch!,
        productCode: int.parse(codigoProduto.text),
      );
    } else if (numeroNF.text.isNotEmpty) {
      data = await DigitalTransferService().listFilteredMovimentacoes(
        accessToken: accessToken!,
        branchPDV: user!.actualBranch!,
        nfNumber: int.parse(numeroNF.text),
      );
    } else {
      data = await DigitalTransferService().listFilteredMovimentacoes(
        accessToken: accessToken!,
        branchPDV: user!.actualBranch!,
        period: [dataInicial, dataFinal],
        status: status,
      );
    }

    if (data is List<DigitalTransfer>) {
      context.read<TransferHistoryProvider>().setHistory(data);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${data!.first()}")));
    }

    filterTransferID.clear();
    codigoProduto.clear();
    numeroNF.clear();
    status = "";

    setState(() {});
  }

  Future<void> _preLoadTransfers() async {
    if (!mounted) return;

    final provider = context.read<TransferHistoryProvider>();

    bool hasAT = await _storage.isAccessTokenValid();

    if (!hasAT) {
      AuthService().logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sessão expirada, faça login novamente!")),
      );

      Navigator.canPop(context) ? Navigator.pop(context) : null;

      setState(() {});

      return;
    }

    String? accessToken = await _storage.getAccessToken();
    User? user = context.read<UserProvider>().user;

    await provider.getHistory(accessToken!, user!.actualBranch!, [
      dataInicial,
      dataFinal,
    ]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    Intl.defaultLocale = 'pt_BR';

    final history = context.read<TransferHistoryProvider>().transfers;
    final filiais = context.watch<BranchProvider>().branches;

    final itens = history;

    final containersIcons = {
      "em_andamento": Icon(
        Icons.hourglass_empty_rounded,
        color: AppColors.verdeBoti,
        size: 30,
      ),
      "cancelada": Icon(Icons.cancel_sharp, color: Colors.red, size: 30),
      "conferida": Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.blue,
        size: 30,
      ),
      "nf_lancada": Icon(
        Icons.description_outlined,
        color: Colors.orange,
        size: 30,
      ),
    };

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 3,
        shadowColor: Colors.white.withAlpha(150),
        toolbarHeight: viewHeight * 0.1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                // Color.fromARGB(255, 113, 113, 133),
                Color.fromARGB(255, 33, 33, 33),
                Color.fromARGB(255, 18, 18, 18),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Histórico $typeHistory", style: TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.only(right: 16),
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshTransfer();
              },
              color: AppColors.verdeBoti,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 30)),
                  SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final selectedDate = await _selectedDate();

                            if (selectedDate != null) {
                              dataInicial = selectedDate;
                            }

                            await _refreshTransfer();

                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            width: viewWidth * 0.4,
                            decoration: BoxDecoration(
                              color: AppColors.cinzaContainer,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              spacing: 12,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Data Inicial",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${dataInicial!.day.toString().length < 2 ? '0${dataInicial!.day}' : '${dataInicial!.day}'}/${dataInicial!.month.toString().length < 2 ? '0${dataInicial!.month}' : '${dataInicial!.month}'}/${dataInicial!.year}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final selectedDate = await _selectedDate();

                            if (selectedDate != null) {
                              dataFinal = selectedDate;
                            }

                            await _refreshTransfer();

                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            width: viewWidth * 0.4,
                            decoration: BoxDecoration(
                              color: AppColors.cinzaContainer,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              spacing: 12,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Data Final",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${dataFinal!.day.toString().length < 2 ? '0${dataFinal!.day}' : '${dataFinal!.day}'}/${dataFinal!.month.toString().length < 2 ? '0${dataFinal!.month}' : '${dataFinal!.month}'}/${dataFinal!.year}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: viewWidth * 0.9,
                      height: viewHeight * 0.06,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            // width: viewWidth * 0.9,
                            // height: viewHeight * 0.2,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cinzaContainer,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(150),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: viewWidth * 0.62,
                              // height: viewHeight * 0.06,
                              child: TextField(
                                // controller: productCode,
                                // maxLength: 5,
                                onChanged: (value) async {
                                  await _refreshTransfer();
                                },
                                onTapOutside: (event) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                controller: filterTransferID,
                                keyboardType: TextInputType.numberWithOptions(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "N° do Boleto",
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            // width: viewWidth * 0.2,
                            // height: 40,
                            child: IconButton(
                              onPressed: () async {
                                await _refreshTransfer();
                              },
                              icon: Icon(
                                Icons.search_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.verdeBoti,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                minimumSize: Size(
                                  viewWidth * 0.2,
                                  viewHeight * 0.06,
                                ),
                                shadowColor: Colors.white.withAlpha(200),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (itens.isNotEmpty) {
                        final item = itens[index];
                        final icon = containersIcons[item.status];

                        return Container(
                          // height: viewHeight * 0.,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: ElevatedButton(
                              onPressed: () {
                                _showTransferModal(context, item);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    spacing: 12,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "VC-${item.id}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(
                                        width: viewWidth * 0.5,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            "Loja Destino: ${item.lojaDestino} - ${filiais.firstWhere(
                                              (e) => e.pdv == item.lojaDestino,
                                              orElse: () => Branch(pdv: -1, name: "Loja não encontrada", address: "", city: "", cnpj: "", state: ""),
                                            ).name}",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${DateTime.parse(item.createdAt!).day.toString().padLeft(2, '0')}"
                                        " de ${DateFormat('MMMM').format(DateTime.parse(item.createdAt!))} de "
                                        "${DateTime.parse(item.createdAt!).year} às "
                                        "${(DateTime.parse(item.createdAt!).hour - 3).toString().padLeft(2, '0')}:${DateTime.parse(item.createdAt!).minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    spacing: 16,
                                    children: [
                                      Text(
                                        "${item.tipoTransferencia}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      icon ?? const Icon(Icons.check),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return RefreshProgressIndicator(
                          color: AppColors.verdeBoti,
                        );
                      }
                    }, childCount: itens.length),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterModal(context, viewWidth);
        },
        backgroundColor: AppColors.verdeBoti,
        shape: CircleBorder(),
        child: const Icon(Icons.filter_list_alt, color: Colors.white, size: 30),
      ),
    );
  }
}

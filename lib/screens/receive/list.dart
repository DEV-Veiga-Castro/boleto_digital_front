import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ListReceiveScreen extends StatefulWidget {
  const ListReceiveScreen({super.key});

  @override
  _ListReceiveScreen createState() => _ListReceiveScreen();
}

class _ListReceiveScreen extends State<ListReceiveScreen> {
  List<DigitalTransfer> itens = [];
  final _storage = ClientStorage();
  Color containerShadow = Colors.transparent;
  int? selectedItemID;
  User? _user;

  final MobileScannerController scannerController = MobileScannerController(
    autoStart: true,
    formats: [BarcodeFormat.qrCode],
  );

  Future<void> listMovimentacoes() async {
    bool isLoggedIn = await _storage.isAccessTokenValid();

    if (!mounted) return;

    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sessão expirada, por favor, faça login novamente!"),
        ),
      );

      await AuthService().logout();

      Navigator.pushNamed(context, '/login');

      setState(() {});
    }

    String? accessToken = await _storage.getAccessToken();
    final user = context.read<UserProvider>().user;

    final dtService = await DigitalTransferService().listMovimentacoesToReceive(
      accessToken: accessToken!,
      branchPDV: user!.actualBranch!,
      transferID: selectedItemID,
    );

    if (dtService != null) {
      itens = dtService;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Ocorreu um erro ao listar as movimentações, tente novamente!",
          ),
        ),
      );
    }

    setState(() {});
  }

  Future<void> _showPopupModal() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Receber Movimentação",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: 120,
            height: 300,
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
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(12),
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) async {
                  final barcode = capture.barcodes.first.rawValue;

                  if (barcode == null) return;

                  await scannerController.stop();

                  selectedItemID = int.tryParse(barcode);

                  await listMovimentacoes();

                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> setMovimentacao() async {
    try {
      User? userProfile = _storage.user;

      if (selectedItemID == null || itens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Por favor, selecione uma movimentação!")),
        );

        return;
      }

      if (selectedItemID != null) {
        itens = [itens[itens.indexWhere((e) => e.id == selectedItemID)]];
      }

      if (userProfile != null) {
        _user = _storage.user;
      }

      if (!mounted) return;

      DigitalTransfer? transfer = DigitalTransfer(
        uuid: itens.first.uuid,
        id: itens.first.id,
        lojaOrigem: itens.first.lojaOrigem,
        lojaDestino: itens.first.lojaDestino,
        tipoTransferencia: itens.first.tipoTransferencia,
        sendedBy: itens.first.sendedBy,
        items: itens.first.items,
      );

      TransferProvider provider = context.read<TransferProvider>();

      provider.setReceiveTransfer(transfer);

      if (provider.transfer != null) {
        Navigator.pushNamed(context, '/receive/initial');

        setState(() {
          selectedItemID = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ocorreu um erro ao iniciar o recebimento, tente novamente!",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao salvar a movimentação, tente novamente! - $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.vermelhoOui,
        ),
      );
    }

    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    listMovimentacoes();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'pt_BR';
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        shadowColor: Colors.grey,
        toolbarHeight: viewHeight * 0.1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 33, 33, 33),
                Color.fromARGB(255, 18, 18, 18),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Receber Movimentação",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        // spacing: 30,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await listMovimentacoes();
              },
              color: AppColors.verdeBoti,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 60)),
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
                                onChanged: (value) async {
                                  selectedItemID = int.tryParse(value);

                                  await listMovimentacoes();

                                  setState(() {});
                                },
                                onTapOutside: (event) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.numberWithOptions(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Número do Boleto",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            // width: viewWidth * 0.2,
                            // height: 40,
                            child: IconButton(
                              onPressed: () {},
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
                  SliverToBoxAdapter(child: SizedBox(height: 30)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = itens[index];
                      bool isSelected = selectedItemID == item.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedItemID = item.id;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.verdeBoti
                                    : Colors.grey,
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            surfaceTintColor: Colors.transparent,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "VC-${item.id}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Loja Origem: ${item.lojaOrigem}",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "${DateTime.parse(item.createdAt!).day.toString().length < 2 ? '0${DateTime.parse(item.createdAt!).day}' : '${DateTime.parse(item.createdAt!).day}'}"
                                      " de ${DateFormat('MMMM').format(DateTime.parse(item.createdAt!))} de "
                                      "${DateTime.parse(item.createdAt!).year} às "
                                      "${DateTime.parse(item.createdAt!).hour - 3}:${DateTime.parse(item.createdAt!).minute}",
                                      style: TextStyle(color: Colors.white),
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: itens.length),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: viewHeight * 0.09,
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _showPopupModal();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(viewWidth * 0.2, viewHeight * 0.06),
                backgroundColor: AppColors.verdeBoti,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedItemID != null || itens.length == 1) {
                  await setMovimentacao();

                  await listMovimentacoes();
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(viewWidth * 0.6, viewHeight * 0.06),
                backgroundColor: AppColors.verdeBoti,
              ),
              child: Row(
                children: [
                  Text(
                    "CONTINUAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_right_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

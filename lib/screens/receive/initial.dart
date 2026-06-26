import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/screens/home_screen.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitialReceiveScreen extends StatefulWidget {
  const InitialReceiveScreen({super.key});

  @override
  _InitialReceiveScreen createState() => _InitialReceiveScreen();
}

class _InitialReceiveScreen extends State<InitialReceiveScreen> {
  final _storage = ClientStorage();
  User? _user;
  // var values = products.map((product) => product['price'] as double)

  int? transferID;
  int? itemTransferID;

  String selectedMovimentacao = "";

  dynamic selectedLojaOrigem = "Selecionar unidade";

  String selectedUsuario = '';

  TextEditingController observacoesText = TextEditingController();

  // Essa função executa tudo que estiver dentro dela antes mesmo da tela carregar
  @override
  void initState() {
    super.initState();
    preLoad();
    // loadBranches();
  }

  Future<void> preLoad() async {
    User? userProfile = await _storage.getUserProfile();

    if (!mounted) return;

    final transferProvider = context.read<TransferProvider>();

    if (transferProvider.transfer != null) {
      setState(() {
        itemTransferID = transferProvider.transfer!.items.first.id;
        transferID = transferProvider.transfer?.id;
        selectedMovimentacao =
            transferProvider.transfer?.tipoTransferencia ?? "";
        selectedLojaOrigem = transferProvider.transfer?.lojaOrigem ?? "";
        observacoesText.text = transferProvider.transfer?.comments ?? "";
      });
    } else {
      selectedMovimentacao = "REGULAR";
    }

    setState(() {
      _user = userProfile;
    });
  }

  void clearContent() {
    final provider = context.read<TransferProvider>();

    provider.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          clearContent();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 3,
          shadowColor: Colors.grey,
          toolbarHeight: viewHeight * 0.1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passo 01 de 03',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text('Informação Inicial'),
            ],
          ),
          actions: [
            Row(
              spacing: 3,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.verdeBoti,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 30,
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 20,
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 20,
                  height: 10,
                ),
                SizedBox(width: 10),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    spacing: 30,
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Container(
                        width: viewWidth * 0.9,
                        // height: viewHeight * 0.1,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cinzaContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(150),
                              blurRadius: 3,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              spacing: 12,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TIPO DE MOVIMENTAÇÃO",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  selectedMovimentacao,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 30),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20),
                        width: viewWidth * 0.9,
                        // height: viewHeight * 0.1,
                        decoration: BoxDecoration(
                          color: AppColors.cinzaContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.grey.withAlpha(150),
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 12,
                              children: [
                                Text(
                                  "LOJA DE ORIGEM",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "$selectedLojaOrigem",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 30),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20),
                        width: viewWidth * 0.9,
                        decoration: BoxDecoration(
                          color: AppColors.cinzaContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(150),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "RESPONSÁVEL PELO ENVIO",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${_user?.name?.capitalize()}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            // SizedBox(),
                            ElevatedButton(
                              onPressed: null,
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                shadowColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_person_outlined,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20),
                        width: viewWidth * 0.9,
                        // height: viewHeight * 0.2,
                        decoration: BoxDecoration(
                          color: AppColors.cinzaContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(150),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OBSERVAÇÕES",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            TextField(
                              maxLines: 5,
                              // expands: true,
                              decoration: InputDecoration(
                                hint: Text(
                                  "ID - $transferID | $itemTransferID | ${observacoesText.text}",
                                  style: TextStyle(
                                    color: Colors.grey.withAlpha(150),
                                  ),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: viewWidth * 0.8,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/receive/insert');
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              AppColors.verdeBoti,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "CONTINUAR",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                Icons.arrow_right,
                                size: 24,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

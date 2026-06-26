import 'package:boleto_digital/models/branch_model.dart';
import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/screens/home_screen.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitialSendScreen extends StatefulWidget {
  const InitialSendScreen({super.key});

  @override
  _InitialSendScreen createState() => _InitialSendScreen();
}

class _InitialSendScreen extends State<InitialSendScreen> {
  final _storage = ClientStorage();
  User? _user;
  final dynamic _userBranches = [];
  // var values = products.map((product) => product['price'] as double)

  IconData iconTipoMov = Icons.keyboard_arrow_down;

  IconData iconLoja = Icons.store;

  IconData iconUserLock = Icons.lock;

  String selectedMovimentacao = "";

  dynamic selectedLojaDestino = "Selecionar unidade";

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
        selectedMovimentacao = transferProvider.transfer?.tipoTransferencia ?? "";
        selectedLojaDestino = transferProvider.transfer?.lojaDestino ?? "";
        observacoesText.text = transferProvider.transfer?.comments ?? "";
      });
    } else {
      selectedMovimentacao = "REGULAR";
    }

    setState(() {
      _user = userProfile;
    });
  }

  Future<void> saveTransferCache() async {
    try {
      User? userProfile = _storage.user;
      String? accessToken = await _storage.getAccessToken();
      final actualBranch = context.read<UserProvider>().user?.actualBranch;

      if (userProfile != null) {
        _user = _storage.user;
      }

      if (!mounted) return;

      if (selectedLojaDestino.toString() == "Selecionar unidade") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Por favor, selecione uma unidade!"),
            backgroundColor: Colors.amber[200],
          ),
        );

        return;
      }

      DigitalTransfer? transfer = DigitalTransfer(
        lojaOrigem: actualBranch,
        lojaDestino: selectedLojaDestino,
        tipoTransferencia: selectedMovimentacao,
        status: 'em_andamento',
        sendedBy: _user?.id,
        comments: observacoesText.text,
        items: [],
      );

      final provider = context.read<TransferProvider>();
      final user = context.read<UserProvider>().user;

      await provider.setTransfer(
        transfer,
        accessToken!,
        user!.actualBranch!,
      );

      // Provider.of(context, listen: false);
      // final provider = context.read<TransferProvider>();

      if (provider.transfer != null) {
        Navigator.pushNamed(context, "/send/insert");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Ocorreu um erro ao salvar a movimentação, tente novamente!",
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
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    final filiais = context.watch<BranchProvider>().branches;
    final userProvider = context.read<UserProvider>().user;

    return Scaffold(
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
            Text('Configuração Inicial'),
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
                          MenuAnchor(
                            alignmentOffset: Offset(-(viewWidth * 0.6), 10),
                            style: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              elevation: WidgetStatePropertyAll(2),
                              shadowColor: WidgetStatePropertyAll(Colors.white),
                            ),
                            builder: (context, controller, child) {
                              return ElevatedButton(
                                onFocusChange: (value) {
                                  if (value) {
                                    setState(() {
                                      iconTipoMov = Icons.keyboard_arrow_up;
                                    });
                                  } else {
                                    setState(() {
                                      iconTipoMov = Icons.keyboard_arrow_down;
                                    });
                                  }
                                },
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                    setState(() {
                                      iconTipoMov = Icons.keyboard_arrow_down;
                                    });
                                  } else {
                                    controller.open();
                                    setState(() {
                                      iconTipoMov = Icons.keyboard_arrow_up;
                                    });
                                  }
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  shadowColor: WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                ),
                                child: Icon(
                                  iconTipoMov,
                                  size: 30,
                                  color: AppColors.verdeBoti,
                                ),
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () {
                                  setState(() {
                                    selectedMovimentacao = "REGULAR";
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(viewWidth * 0.8, 40),
                                ),
                                child: const Text(
                                  "REGULAR",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  setState(() {
                                    selectedMovimentacao = "BAIXA";
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(viewWidth * 0.8, 40),
                                ),
                                child: const Text(
                                  "BAIXA",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  setState(() {
                                    selectedMovimentacao = "VENDA";
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(viewWidth * 0.8, 40),
                                ),
                                child: const Text(
                                  "VENDA",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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
                                "LOJA DE DESTINO",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "$selectedLojaDestino",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          MenuAnchor(
                            alignmentOffset: Offset(-(viewWidth * 0.6), 10),
                            style: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              elevation: WidgetStatePropertyAll(2),
                              shadowColor: WidgetStatePropertyAll(Colors.white),
                            ),
                            builder: (context, controller, child) {
                              return ElevatedButton(
                                onPressed: () {
                                  if (controller.isOpen) {
                                    setState(() {
                                      controller.close();
                                      iconLoja = Icons.store;
                                    });
                                  } else {
                                    setState(() {
                                      controller.open();
                                      iconLoja = Icons.storefront;
                                    });
                                  }
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  shadowColor: WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                ),
                                child: Icon(
                                  iconLoja,
                                  size: 30,
                                  color: AppColors.verdeBoti,
                                ),
                              );
                            },
                            menuChildren: filiais
                                .where(
                                  (filial) =>
                                      filial.pdv != userProvider!.actualBranch,
                                )
                                .map((filial) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      print(
                                        "Filial ATUAL: ${userProvider!.actualBranch}",
                                      );
                                      setState(() {
                                        selectedLojaDestino = filial.pdv;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size(viewWidth * 0.8, 40),
                                    ),
                                    child: Text(
                                      "${filial.pdv} | ${filial.name}",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
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
                              iconUserLock,
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
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          TextField(
                            controller: observacoesText,
                            maxLines: 5,
                            // expands: true,
                            decoration: InputDecoration(
                              hint: Text(
                                "Adicione detalhes importantes sobre esta movimentação...",
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
                        onPressed: () async {
                          await saveTransferCache();
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
    );
  }
}

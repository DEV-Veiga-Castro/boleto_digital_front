import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RevisionReceiveScreen extends StatefulWidget {
  const RevisionReceiveScreen({super.key});

  @override
  _RevisionReceiveScreen createState() => _RevisionReceiveScreen();
}

class _RevisionReceiveScreen extends State<RevisionReceiveScreen> {
  final _storage = ClientStorage();

  @override
  void initState() {
    super.initState();
  }

  Future<bool> verifyDiscrepancy() async {
    // A função retornará TRUE caso haja alguma discrepancia no items
    // Ou retornará FALSE, caso todos os itens estão OK

    final provider = context.read<TransferProvider>();
    List<DigitalTransferItems> items = provider.transfer!.items;
    int discrepancies = 0;

    for (int i = 0; i < items.length; i++) {
      if (items[i].quantitySent != items[i].quantityReceived) {
        discrepancies += 1;
      }
    }

    if (discrepancies > 0) {
      return true;
    }

    return false;
  }

  Future<void> updateMovimentacao() async {
    if (!mounted) return;

    bool hasAT = await _storage.isAccessTokenValid();

    if (!hasAT) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tempo de sessão excedido, faça login novamente!"),
        ),
      );

      await AuthService().logout();

      setState(() {});
    }

    bool hasDiscrepancies = await verifyDiscrepancy();

    if (hasDiscrepancies) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Movimentação com Discrepâncias!",
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ListBody(
                children: [
                  Text(
                    "A movimentação contém discrepâncias entre os itens enviados e os recebidos, tem certeza que deseja confirmar o recebimento?",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  return;
                },
                child: const Text(
                  "Voltar",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await updateTranfer();
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
    } else {
      await updateTranfer();
    }
  }

  Future<void> updateTranfer() async {
    final accessToken = await _storage.getAccessToken();
    final provider = context.read<TransferProvider>();

    try {
      print(provider.transfer!.uuid);

      String response = await DigitalTransferService().updateMovimentacaoItems(
        accessToken: accessToken!,
        transferID: provider.transfer!.uuid!,
        digitalItems: provider.transfer!.items,
        model: "receive"
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response)));

      response = await DigitalTransferService().updateTransferStatus(
        accessToken: accessToken,
        transferID: provider.transfer!.uuid!,
        status: 'conferida',
        model: 'receive'
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response)));

      provider.clear();

      setState(() {});

      Navigator.pushNamed(context, '/home');
    } catch (e, stackTrace) {
      print("Eu sou o erro: $stackTrace");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$e!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    final transferProvider = context.read<TransferProvider>();
    final productProvider = context.read<ProductProvider>();

    final transfer = transferProvider.transfer;
    final itens = transfer?.items ?? [];

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
              'Passo 03 de 03',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text('Revisão'),
          ],
        ),
        actions: [
          Row(
            spacing: 3,
            children: [
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.verdeBoti,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 30,
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(20),
                    width: viewWidth * 0.9,
                    decoration: BoxDecoration(
                      color: AppColors.cinzaContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.roxoEudora,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Text(
                                  "ID DO BOLETO",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "VC-${transfer?.id}",
                                  style: TextStyle(
                                    color: AppColors.verdeBoti,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey.withAlpha(50),
                              size: 60,
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey.withAlpha(50)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Text(
                                  "ORIGEM",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${transfer?.lojaOrigem == 1 ? "Escritório" : transfer?.lojaOrigem}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_right_outlined,
                              color: AppColors.verdeBoti,
                              size: 32,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Text(
                                  "DESTINO",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${transfer?.lojaDestino == 1 ? "Escritório" : transfer?.lojaDestino}",
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
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: viewWidth * 0.9,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          width: viewWidth * 0.4,
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roxoEudora,
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "MOVIMENTAÇÃO",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${transfer?.tipoTransferencia}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(12),
                          width: viewWidth * 0.4,
                          decoration: BoxDecoration(
                            color: AppColors.cinzaContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roxoEudora,
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "TOTAL DE ITENS",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${transferProvider.getTotalQuantitySent()} Itens",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: viewWidth * 0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "ITENS DETALHADOS",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(),
                        Text(
                          "${itens.length} SKUs",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = itens[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cinzaContainer,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verdeBoti,
                            blurRadius: 4,
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
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          title: Text(
                            productProvider.getDescription(item.productID!),
                            maxLines: 1,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.quantitySent}x | ',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${item.quantityReceived}x',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: itens.length),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: viewHeight * 0.09,
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await updateMovimentacao();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.verdeBoti,
                minimumSize: Size(viewWidth * 0.8, 40),
              ),
              child: Row(
                children: [
                  Text(
                    "CONFIRMAR",
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

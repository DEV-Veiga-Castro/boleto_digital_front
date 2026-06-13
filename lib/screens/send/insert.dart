import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/product_model.dart';
// import 'package:boleto_digital/models/user_model.dart';
// import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class InsertSendScreen extends StatefulWidget {
  const InsertSendScreen({super.key});

  // final CameraDescription camera;

  @override
  _InsertSendScreen createState() => _InsertSendScreen();
}

class _InsertSendScreen extends State<InsertSendScreen> {
  // final _storage = ClientStorage();
  // User? _user;

  TextEditingController productCode = TextEditingController();
  final MobileScannerController scannerController = MobileScannerController(
    autoStart: false,
  );

  int? quantSKU;

  String? lastCode;

  bool scannerAtivo = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    scannerController.dispose();
    super.dispose();
  }

  Future<void> insertItens(int productID) async {
    if (productID.isNaN) {
      debugPrint("Produto vazio");
      return;
    }

    if (!mounted) return;

    if (productID.toString().length > 5) {
      productID = int.parse(
        productID.toString().substring(
          productID.toString().length - 6,
          productID.toString().length - 1,
        ),
      );
    }

    lastCode = "$productID";

    final product = context.read<ProductProvider>().products;
    final productIndex = product.indexWhere(
      (item) => item.codProduct == productID,
    );

    if (productIndex != -1) {
      context.read<TransferProvider>().addItem(productID);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Produto não encontrado: $productID",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber[200],
        ),
      );
    }

    Future.delayed(const Duration(seconds: 5), () => lastCode = null);
    productCode.clear();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    final transfer = context.read<TransferProvider>().transfer;

    final itens = transfer?.items ?? [];

    // bool isActive = false;

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
              'Passo 02 de 03',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text('Inserção de Itens'),
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
                // SizedBox(height: 10),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: viewWidth * 0.8,
                    height: viewHeight * 0.2,
                    // padding: EdgeInsets.all(6),
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
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(12),
                      child: MobileScanner(
                        controller: scannerController,
                        onDetect: (capture) async {
                          final barcode = capture.barcodes.first.rawValue;

                          if (barcode == null) return;

                          if (barcode == lastCode) return;

                          await scannerController.stop();

                          await insertItens(int.parse(barcode));

                          Future.delayed(Duration(seconds: 1), () {
                            setState(() {
                              scannerController.start();
                            });
                          });
                        },
                      ),
                    ),
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
                              controller: productCode,
                              // maxLength: 5,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Código",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          // width: viewWidth * 0.2,
                          // height: 40,
                          child: IconButton(
                            onPressed: () {
                              insertItens(int.parse(productCode.text));
                            },
                            icon: Icon(
                              Icons.add,
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
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: viewWidth * 0.9,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "ITENS",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(),
                        Text(
                          "${itens.length} SKUs",
                          style: TextStyle(
                            color: const Color.fromRGBO(158, 158, 158, 1),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
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
                            "Descriçãdwdawdawdawdawwdawdawdawdawo",
                            maxLines: 1,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          trailing: Text(
                            '${item.quantitySent}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // TODO: Implementar abertura de MODAL com as informações desse item e as opções de diminuir quantidade e exclusão
                          onTap: () {
                            print("${item.productID}");
                          },
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              // TODO: Implementar a abertura da camera
              onPressed: () async {
                if (!scannerAtivo) {
                  await scannerController.start();
                } else {
                  await scannerController.stop();
                }

                setState(() {
                  scannerAtivo = !scannerAtivo;
                  // _cameraPreview(isActive);
                });
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(viewWidth * 0.2, viewHeight * 0.06),
                backgroundColor: scannerAtivo
                    ? AppColors.verdeBoti
                    : Colors.grey,
              ),
              child: Icon(Icons.barcode_reader, size: 24, color: Colors.white),
            ),
            ElevatedButton(
              // TODO: Implementar o salvamento dos itens na movimentação
              onPressed: () {},
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

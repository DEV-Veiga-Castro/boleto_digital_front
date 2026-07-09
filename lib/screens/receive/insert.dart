import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class InsertReceiveScreen extends StatefulWidget {
  const InsertReceiveScreen({super.key});

  // final CameraDescription camera;

  @override
  _InsertReceiveScreen createState() => _InsertReceiveScreen();
}

class _InsertReceiveScreen extends State<InsertReceiveScreen> {
  final _storage = ClientStorage();

  late FocusNode _focusTextField;

  TextEditingController productCode = TextEditingController();
  final MobileScannerController scannerController = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.ean13],
  );

  int? quantSKU;

  String? lastCode;

  bool scannerAtivo = false;

  @override
  void initState() {
    super.initState();
    _focusTextField = FocusNode();
  }

  @override
  void dispose() {
    scannerController.dispose();
    _focusTextField.dispose();
    super.dispose();
  }

  Future<void> _showItemModal(
    BuildContext context,
    DigitalTransferItems item,
  ) async {
    // Remove o focus do textfield do código
    FocusManager.instance.primaryFocus?.unfocus();

    final descriptionProvider = context.read<ProductProvider>();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Consumer<TransferProvider>(
          builder: (context, transferProvider, child) {
            return Container(
              height: 250,
              padding: EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: AppColors.cinzaContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "CÓDIGO: ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${item.productID}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "DESCRIÇÃO: ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: Text(
                                  descriptionProvider.getDescription(
                                    item.productID!,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          transferProvider.clearReceivedItem(item.productID!);
                          Navigator.pop(context);

                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(10),
                        ),
                        icon: Icon(
                          Icons.delete_outlined,
                          color: Colors.red,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          transferProvider.subReceivedItem(item.productID!);
                          setState(() {});
                        },
                        icon: Icon(Icons.exposure_minus_1_rounded),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(15),
                              blurRadius: 3,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(12),
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          "${transferProvider.getQuantityReceived(item.productID!)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // transferProvider.addReceivedItem(item.productID!);

                          // setState(() {});
                          null;
                        },
                        icon: Icon(Icons.exposure_plus_1_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> insertItens(int productID) async {
    if (!mounted) return;

    if (productID.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Código vazio, não foi possível adicionar!",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber[200],
        ),
      );
      return;
    }

    if (productID.toString().length > 5) {
      productID = int.parse(
        productID.toString().substring(
          productID.toString().length - 6,
          productID.toString().length - 1,
        ),
      );
    }

    lastCode = "$productID";

    String? accessToken = await _storage.getAccessToken();

    final product = await context.read<ProductProvider>().searchProduct(
      token: accessToken,
      product: productID.toString(),
    );

    final productIndex = product!.indexWhere(
      (item) => item.codProduct == productID,
    );

    if (productIndex != -1) {
      final provider = context.read<TransferProvider>();

      String response = provider.addReceivedItem(productID);

      if (response != "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response, style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.amber[200],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Produto não cadastrado: $productID",
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

  Future<void> saveTransferCache(List itens) async {
    try {
      if (!mounted) return;

      if (itens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "A lista de itens está vazia!",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.amber[200],
          ),
        );

        return;
      }

      final provider = context.read<TransferProvider>();
      // String? accessToken = await _storage.getAccessToken();

      if (provider.transfer != null) {
        Navigator.pushNamed(context, '/receive/revision');
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
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    final transfer = context.read<TransferProvider>().transfer;
    final productProvider = context.read<ProductProvider>();

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
                              keyboardType: TextInputType.numberWithOptions(),
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
                              if (productCode.text.isEmpty) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_focusTextField);
                              } else {
                                insertItens(int.parse(productCode.text));
                              }
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
                                "${item.quantityReceived}x",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Abre um modal com as informações do item
                            _showItemModal(context, item);
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
              onPressed: () async {
                await saveTransferCache(itens);
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

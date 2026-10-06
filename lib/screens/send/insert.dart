import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class InsertSendScreen extends StatefulWidget {
  const InsertSendScreen({super.key});

  // final CameraDescription camera;

  @override
  _InsertSendScreen createState() => _InsertSendScreen();
}

class _InsertSendScreen extends State<InsertSendScreen> {
  final _storage = ClientStorage();
  late FocusNode _focusTextField;

  AudioSource? _beepSound;
  bool _soloudReady = false;
  bool _isBeeping = false;

  bool userWantsScanning = false;

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
    _initSoLoud();
  }

  @override
  void dispose() {
    scannerController.dispose();
    _focusTextField.dispose();
    if (_beepSound != null) {
      SoLoud.instance.disposeSource(_beepSound!);
    }
    super.dispose();
  }

  Future<void> _initSoLoud() async {
    try {
      final soloud = SoLoud.instance;

      if (!soloud.isInitialized) {
        await soloud.init();
      }

      _beepSound = await soloud.loadAsset('assets/sound/beep.mp3');
      _soloudReady = true;
    } catch (e) {
      debugPrint('Erro ao inicializar SoLoud: $e');
      _soloudReady = false;
    }
  }

  Future<void> _beepPlayer() async {
    if (_isBeeping) return; // ignora chamadas sobrepostas
    if (!_soloudReady || _beepSound == null) return;
    if (!SoLoud.instance.isInitialized) return;

    _isBeeping = true;
    try {
      SoLoud.instance.play(_beepSound!);
    } catch (e) {
      debugPrint('Erro ao tocar beep: $e');
    } finally {
      _isBeeping = false;
    }
  }

  Future<void> _showItemModal(
    BuildContext context,
    DigitalTransferItems item,
  ) async {
    // Remove o focus do textfield do código
    FocusManager.instance.primaryFocus?.unfocus();

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
                                "    ${item.productID}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "DESCRIÇÃO: ",
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: Text(
                                  '${item.description}',
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
                          transferProvider.removeItem(item.productID!);
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
                          transferProvider.subItem(item.productID!);
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
                          "${transferProvider.getQuantitySent(item.productID!)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          transferProvider.addItem(item.productID!, "add");

                          setState(() {});
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

    bool hasAT = await _storage.isAccessTokenValid();

    if (!hasAT) {
      _storage.clearTokens();
      // Navega para login se o token estiver ausente ou expirado
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

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

    if (productID.toString().contains('.') ||
        productID.toString().contains(',')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Código inválido, não foi possível adicionar!",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber[200],
        ),
      );
      return;
    }

    if (productID.toString().length == 8) {
      productID = int.parse(productID.toString());
    } else if (productID.toString().length > 5) {
      productID = int.parse(
        productID.toString().substring(
          productID.toString().length - 6,
          productID.toString().length - 1,
        ),
      );
    }

    lastCode = "$productID";

    String? accessToken = await _storage.getAccessToken();

    final transferProvider = context.read<TransferProvider>();

    String description = "Descrição";

    int? productIndex = -1;

    productIndex = transferProvider.transfer?.items.indexWhere(
      (item) => item.productID == productID,
    );

    if (productIndex == -1) {
      final product = await context.read<ProductProvider>().searchProduct(
        token: accessToken,
        product: productID.toString(),
      );

      if (product != null) {
        productIndex = product.indexWhere(
          (item) => item.codProduct == productID,
        );

        description = product.first.description!;
      }
    }

    if (productIndex != -1) {
      context.read<TransferProvider>().addItem(productID, description);
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
        Navigator.pushNamed(context, '/send/revision');
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
    } finally {
      await scannerController.stop();
    }
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: scannerController,
                            onDetect: (capture) async {
                              await _beepPlayer();

                              final barcode = capture.barcodes.first.rawValue;
                              if (barcode == null || barcode == lastCode) {
                                return;
                              }

                              try {
                                await scannerController.stop();
                                await insertItens(int.parse(barcode));

                                Future.delayed(
                                  const Duration(seconds: 1),
                                  () async {
                                    if (!mounted) return;
                                    if (!userWantsScanning) return;
                                    try {
                                      await scannerController.start();
                                    } catch (e) {
                                      debugPrint(
                                        'Erro ao reiniciar scanner: $e',
                                      );
                                    }
                                  },
                                );
                              } catch (e) {
                                debugPrint('Erro ao parar scanner: $e');
                              }
                            },
                          ),
                          // overlay por cima, sem desmontar o MobileScanner
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: scannerController,
                            builder: (context, state, child) {
                              if (state.isRunning) {
                                return const SizedBox.shrink();
                              } else {
                                return Container(
                                  color: Colors.black.withAlpha(50),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.videocam_off,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
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
                                if (productCode.text.contains('.') ||
                                    productCode.text.contains(',')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Código inválido, não foi possível adicionar!",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      backgroundColor: Colors.amber[200],
                                    ),
                                  );
                                  return;
                                }

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
                    final reversedItens = List.from(itens.reversed);
                    final item = reversedItens[index];

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
                            '${item.description}',
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
                try {
                  if (userWantsScanning) {
                    await scannerController.stop();
                  } else {
                    await scannerController.start();
                  }
                  setState(() {
                    userWantsScanning = !userWantsScanning;
                  });
                } catch (e) {
                  debugPrint('Erro ao alternar scanner: $e');
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(viewWidth * 0.2, viewHeight * 0.06),
                backgroundColor: userWantsScanning
                    ? AppColors.verdeBoti
                    : Colors.grey,
              ),
              child: const Icon(
                Icons.barcode_reader,
                size: 24,
                color: Colors.white,
              ),
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

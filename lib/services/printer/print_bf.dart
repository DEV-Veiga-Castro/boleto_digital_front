import 'package:boleto_digital/models/dt_model.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
// import 'package:flutter/services.dart';
// import 'package:image/image.dart' as img;

Future<void> imprimirBoleto(
  {
    int? transferID,
    int? transferUUID,
    int? lojaOrigem,
    int? lojaDestino,
    List<DigitalTransferItems>? itens
  }
) async {
  final profile = await CapabilityProfile.load();

  final generator = Generator(PaperSize.mm58, profile);

  List<int> bytes = [];

  // Logo da Empresa
  // final ByteData data = await rootBundle.load(
  //   'assets/imgs/logo_vc_wide_v2.png',
  // );
  // final Uint8List imgBytes = data.buffer.asUint8List();
  // final img.Image imgData = img.decodePng(imgBytes)!;

  // final whiteBack = img.Image(height: imgData.height, width: imgData.width);

  // img.fill(whiteBack, color: img.ColorRgb8(255, 255, 255));

  // img.compositeImage(whiteBack, imgData);

  // bytes += generator.image(whiteBack);

  // Título
  bytes += generator.text(
    "Boleto Digital",
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      width: PosTextSize.size2,
      height: PosTextSize.size2,
    ),
  );

  bytes += generator.hr(ch: "=");

  // ID do Boleto
  bytes += generator.row([
    PosColumn(
      text: 'VC-$transferID',
      width: 12,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
      ),
    ),
  ]);

  // Separador
  bytes += generator.hr(linesAfter: 1);

  // Informações
  bytes += generator.row([
    PosColumn(
      text: 'ORIGEM',
      width: 4,
      styles: PosStyles(align: PosAlign.left),
    ),

    PosColumn(
      text: '$lojaOrigem',
      width: 8,
      styles: PosStyles(align: PosAlign.center),
    ),
  ]);

  bytes += generator.row([
    PosColumn(
      text: 'DESTINO',
      width: 4,
      styles: PosStyles(align: PosAlign.left),
    ),

    PosColumn(
      text: '$lojaDestino',
      width: 8,
      styles: PosStyles(align: PosAlign.center),
    ),
  ]);

  bytes += generator.hr(linesAfter: 1);

  // ITEMS
  bytes += generator.row([
    PosColumn(
      text: 'ITEM',
      width: 5,
      styles: PosStyles(align: PosAlign.left),
    ),
    PosColumn(
      text: '|',
      width: 2,
      styles: PosStyles(align: PosAlign.left),
    ),
    PosColumn(
      text: 'QTD',
      width: 5,
      styles: PosStyles(align: PosAlign.center),
    ),
  ]);

  bytes += generator.hr();

  for (DigitalTransferItems item in itens!) {
    bytes += generator.row([
      PosColumn(
        text: "${item.productID}",
        width: 5,
        styles: PosStyles(align: PosAlign.left, underline: false),
      ),
      PosColumn(text: "|", width: 2),
      PosColumn(
        text: "${item.quantitySent}",
        width: 5,
        styles: PosStyles(align: PosAlign.center, underline: false),
      ),
    ]);
  }

  bytes += generator.hr(ch: '=', linesAfter: 2);

  // QR Code
  bytes += generator.qrcode("$transferID", size: QRSize.size8);

  bytes += generator.feed(2);

  // Corte (algumas impressoras apenas avançam o papel)
  // bytes += generator.cut();

  await PrintBluetoothThermal.writeBytes(bytes);
}

// List<int> listaItens(
//   final list
// ) {
//   return [int.parse(

//   )]
// }

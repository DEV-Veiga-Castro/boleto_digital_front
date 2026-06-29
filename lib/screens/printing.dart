import 'package:boleto_digital/services/printer/print_bf.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class ImpressaoPage extends StatefulWidget {
  const ImpressaoPage({super.key});

  @override
  State<ImpressaoPage> createState() => _ImpressaoPageState();
}

class _ImpressaoPageState extends State<ImpressaoPage> {
  final TextEditingController controller = TextEditingController();

  String? macAddress;

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

  Future<void> imprimir() async {
    bool isPermited = await requestBluetooth();

    if (!isPermited) return;

    if (macAddress == null) {
      await conectarImpressora();
    }

    bool conectado = await PrintBluetoothThermal.connectionStatus;

    if (!conectado) {
      return;
    }

    if (controller.text.isEmpty) {
      imprimirBoleto();
    } else {
      List<int> bytes = [];

      bytes.addAll(controller.text.codeUnits);

      // Quebra de linha
      bytes.addAll([10, 10, 10]);

      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Impressão Bluetooth")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Digite o texto",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: imprimir, child: const Text("Imprimir")),
          ],
        ),
      ),
    );
  }
}

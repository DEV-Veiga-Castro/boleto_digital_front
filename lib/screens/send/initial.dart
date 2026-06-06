import 'package:boleto_digital/services/client_storage.dart';
import 'package:flutter/material.dart';

class InitialSendScreen extends StatefulWidget {
  const InitialSendScreen({super.key});

  @override
  _InitialSendScreen createState() => _InitialSendScreen();
}

class _InitialSendScreen extends State<InitialSendScreen> {
  final _storage = ClientStorage();

  // Essa função executa tudo que estiver dentro dela antes mesmo da tela carregar
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar Boleto')),
      body: const Center(
        child: Text('Tela de envio de boleto - Em construção'),
      ),
    );
  }
}

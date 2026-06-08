import 'dart:typed_data';

import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class InitialSendScreen extends StatefulWidget {
  const InitialSendScreen({super.key});

  @override
  _InitialSendScreen createState() => _InitialSendScreen();
}

class _InitialSendScreen extends State<InitialSendScreen> {
  final _storage = ClientStorage();

  Icon dropdownIcon = Icon(Icons.keyboard_arrow_down, size: 30);

  String selectedMovimentacao = "REGULAR";

  final filiais = ["4178 - Loja 1", "6276 - Loja 2"];
  String selectedLojaDestino = "Selecionar unidade";

  // Essa função executa tudo que estiver dentro dela antes mesmo da tela carregar
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

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
      body: Center(
        child: Expanded(
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
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          selectedMovimentacao,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return ElevatedButton(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                              setState(() {
                                dropdownIcon = Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 30,
                                );
                              });
                            } else {
                              controller.open();
                              setState(() {
                                dropdownIcon = Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 30,
                                );
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
                          child: dropdownIcon,
                        );
                      },
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              selectedMovimentacao = "REGULAR";
                              dropdownIcon = Icon(
                                Icons.keyboard_arrow_down,
                                size: 30,
                              );
                            });
                          },
                          child: const Text("REGULAR"),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              selectedMovimentacao = "BAIXA";
                              dropdownIcon = Icon(
                                Icons.keyboard_arrow_down,
                                size: 30,
                              );
                            });
                          },
                          child: const Text("BAIXA"),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              selectedMovimentacao = "VENDA";
                              dropdownIcon = Icon(
                                Icons.keyboard_arrow_down,
                                size: 30,
                              );
                            });
                          },
                          child: const Text("VENDA"),
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          "LOJA DE DESTINO",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          selectedLojaDestino,
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return ElevatedButton(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          child: const Text("oi"),
                        );
                      },
                      menuChildren: filiais.map((filiais) {
                        return MenuItemButton(
                          onPressed: () {
                            print(filiais);
                          },
                          child: Text(filiais),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

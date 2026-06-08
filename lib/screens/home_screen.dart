import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:boleto_digital/services/routes/user_service.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = ClientStorage();
  User? user;
  int _countInTransit = 0;
  int _countReceived = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool loggedIn = await _storage.isLoggedIn();
    print("User logged in: $loggedIn");

    if (!mounted) {
      return;
    } else if (!loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Caso o usuário esteja logado, carrega as informações pessoais
      await _loadUserProfile();
      await _listMovimentacoes();
    }
  }

  Future<void> _loadUserProfile() async {
    User? userProfile = _storage.user;

    if (userProfile != null) {
      setState(() {
        user = _storage.user;
      });
    } else {
      final accessToken = await _storage.getAccessToken();
      User? userProfile = await UserService().getUserProfile(
        accessToken: accessToken!,
      );

      if (userProfile != null) {
        await _storage.setUserProfile(userProfile);

        setState(() {
          user = _storage.user;
        });
      } else {
        // await AuthService().logout();
        initState();
      }
    }
  }

  Future<void> _listMovimentacoes() async {
    // Captura o AccessToken do usuário
    String? accessToken = await _storage.getAccessToken();

    // Chama e atribiu o retorno da listagem das trasnferencias nas variáveis
    _countInTransit = await DigitalTransferService().countMovimentacoes(
      accessToken: accessToken!,
      status: "transito",
    );
    _countReceived = await DigitalTransferService().countMovimentacoes(
      accessToken: accessToken,
      status: "recebida",
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 3,
          shadowColor: Colors.white.withAlpha(150),
          toolbarHeight: viewHeight * 0.1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // Color.fromARGB(255, 113, 113, 133),
                  Color.fromARGB(255, 33, 33, 33),
                  Color.fromARGB(255, 18, 18, 18),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: const Image(
                        image: AssetImage("assets/imgs/anfora_logo.jpeg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [Text("Olá, ", style: TextStyle(fontSize: 18))],
                  ),
                  Text(
                    "${user?.name?.capitalize() ?? 'Usuário'}!",
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.only(right: 16),
              icon: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _checkLoginStatus,
                color: AppColors.verdeBoti,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewHeight * 0.9),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/send');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.transparent,
                                // shape: RoundedRectangleBorder(
                                //   borderRadius: BorderRadius.circular(20),
                                // ),
                                // padding: EdgeInsets.symmetric(
                                //   horizontal: viewWidth * 0.1,
                                //   vertical: viewHeight * 0.02,
                                // ),
                              ),
                              child: Container(
                                width: viewWidth * 0.8,
                                height: viewHeight * 0.2,
                                decoration: BoxDecoration(
                                  color: AppColors.cinzaContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.verdeBoti.withAlpha(200),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.swipe_up_outlined,
                                        color: AppColors.verdeBoti,
                                        size: 60,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "ENVIAR",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "MOVIMENTAÇÃO",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Container(
                              width: viewWidth * 0.8,
                              height: viewHeight * 0.2,
                              decoration: BoxDecoration(
                                color: AppColors.cinzaContainer,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.verdeBoti.withAlpha(200),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.swipe_down_outlined,
                                      color: AppColors.verdeBoti,
                                      size: 60,
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "RECEBER",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          "MOVIMENTAÇÃO",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  width: viewWidth * 0.35,
                                  height: viewHeight * 0.15,
                                  decoration: BoxDecoration(
                                    color: AppColors.cinzaContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.verdeBoti.withAlpha(
                                          200,
                                        ),
                                        blurRadius: 4,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "EM TRÂNSITO",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(),
                                        Text(
                                          _countInTransit.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: viewWidth * 0.35,
                                  height: viewHeight * 0.15,
                                  decoration: BoxDecoration(
                                    color: AppColors.cinzaContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.verdeBoti.withAlpha(
                                          200,
                                        ),
                                        blurRadius: 4,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "RECEBIDAS",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(),
                                        Text(
                                          _countReceived.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            BottomAppBar(
                              color: Colors.transparent,
                              child: Image(
                                image: AssetImage(
                                  "assets/imgs/logo_vc_footer.png",
                                ),
                                width: viewWidth * 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

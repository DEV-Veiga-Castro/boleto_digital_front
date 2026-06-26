import 'package:boleto_digital/models/branch_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/dt_service.dart';
import 'package:boleto_digital/services/routes/user_service.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  List<Branch> _userBranches = [];
  int? _selectedBranch = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // final accessToken = await _storage.getAccessToken();
    final tokenValid = await _storage.isAccessTokenValid();

    if (!mounted) return;

    if (!tokenValid) {
      // Navega para login se o token estiver ausente ou expirado
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Caso o token seja válido, carrega perfil e movimentações
    await _loadUserProfile();
    await _listMovimentacoes();
    await _listBranches();
    await _listProducts();
  }

  Future<void> _loadUserProfile() async {
    User? userProfile = _storage.user;

    if (!mounted) return;

    if (userProfile != null) {
      user = _storage.user;
      _userBranches = user!.branch;

      final userProvider = context.read<UserProvider>();

      userProvider.setUser(user!);

      if (userProvider.user!.actualBranch == null) {
        debugPrint("PDV ATUAL ${_userBranches.first.pdv!}");

        await userProvider.setActualBranch(_userBranches.first.pdv!);
      } else {
        _selectedBranch = userProvider.user!.actualBranch;
      }

      if (_selectedBranch == 0) {
        _selectedBranch = userProvider.user!.actualBranch;

        debugPrint("PDV SELECIONADO: $_selectedBranch");
      }

      debugPrint("PDV SELECIONADO: $_selectedBranch");

      setState(() {});

      if (mounted) setState(() {});
    } else {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      User? userProfile = await UserService().getUserProfile(
        accessToken: accessToken,
      );

      if (userProfile != null) {
        await _storage.setUserProfile(userProfile);

        user = _storage.user;
        _userBranches = user!.branch;

        final userProvider = context.read<UserProvider>();

        userProvider.setUser(user!);

        debugPrint("PDV ATUAL 2 ${_userBranches.first.pdv!}");

        userProvider.setActualBranch(_userBranches.first.pdv!);

        if (_selectedBranch == 0) {
          _selectedBranch = userProvider.user!.actualBranch;

          debugPrint("PDV SELECIONADO: $_selectedBranch");
        }

        setState(() {});
      } else {
        // Se não conseguiu carregar o perfil (ex.: 401), redireciona ao login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _listMovimentacoes() async {
    // Captura o AccessToken do usuário
    String? accessToken = await _storage.getAccessToken();

    if (accessToken == null) return;

    // Chama e atribui o retorno da listagem das transferencias nas variáveis
    _countInTransit = await DigitalTransferService().countMovimentacoes(
      accessToken: accessToken,
      status: "transito",
    );
    _countReceived = await DigitalTransferService().countMovimentacoes(
      accessToken: accessToken,
      status: "recebida",
    );

    if (mounted) setState(() {});
  }

  Future<void> _listBranches() async {
    String? token = await _storage.getAccessToken();

    // final branches = await BranchService().listBranch(accessToken: token!);

    if (!mounted) return;

    await context.read<BranchProvider>().loadBranches(token);

    if (mounted) setState(() {});
  }

  Future<void> _listProducts() async {
    String? token = await _storage.getAccessToken();

    if (!mounted) return;

    await context.read<ProductProvider>().loadProducts(token);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      key: _scaffoldKey,
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.verdeBoti),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    "Menu",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: .zero,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.store_outlined,
                        color: AppColors.verdeBoti,
                        size: 30,
                      ),
                      title: Text(
                        "$_selectedBranch | ",
                        maxLines: 1,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      titleAlignment: ListTileTitleAlignment.center,
                      trailing: MenuAnchor(
                        alignmentOffset: Offset(-(viewHeight * 0.2), 0),
                        style: MenuStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            AppColors.cinzaContainer,
                          ),
                        ),
                        builder: (context, controller, child) {
                          return IconButton(
                            onPressed: () {
                              if (controller.isOpen) {
                                setState(() {
                                  controller.close();
                                });
                              } else {
                                controller.open();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              // fixedSize: Size(viewWidth *, 40),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.verdeBoti,
                              size: 30,
                            ),
                          );
                        },
                        menuChildren: _userBranches.map((branches) {
                          return MenuItemButton(
                            onPressed: () async {
                              // print(branches.pdv);
                              _selectedBranch = branches.pdv;

                              print("EU selecionei $_selectedBranch");

                              await context
                                  .read<UserProvider>()
                                  .setActualBranch(_selectedBranch!);

                              setState(() {});
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(viewWidth * 0.6, 40),
                            ),
                            child: Text(
                              "${branches.pdv} | ${branches.name}",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Sair"),
                onTap: () async {
                  await AuthService().logout();
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          elevation: 3,
          automaticallyImplyLeading: false,
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
                    child: Builder(
                      builder: (context) {
                        return TextButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          style: OutlinedButton.styleFrom(
                            // fixedSize: Size(80, 80),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.all(0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: const Image(
                              image: AssetImage("assets/imgs/anfora_logo.jpeg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
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
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
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
                                shadowColor: Colors.transparent,
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
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/receive/list');
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
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

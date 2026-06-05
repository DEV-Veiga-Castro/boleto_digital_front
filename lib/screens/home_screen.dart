import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/screens/login_screen.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/services/routes/user_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = ClientStorage();
  User? user;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _storage.isLoggedIn();

    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      // Caso o usuário esteja logado, carrega as informações pessoais
      await _loadUserProfile();
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
        print("Failed to load user profile.");
      }
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
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
              SizedBox(width: 8,),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        Text(
                          "Olá, ", 
                          style: TextStyle(
                            fontSize: 18
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${user?.name?.capitalize() ?? 'Usuário'}!",
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                ]
              )
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
            )
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String{
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

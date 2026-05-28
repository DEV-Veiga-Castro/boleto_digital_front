
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
      print("User Profile:");
      print("ID: ${userProfile.id}");
      print("Username: ${userProfile.username}");
      print("Name: ${userProfile.name} ${userProfile.surname}");
      print("Email: ${userProfile.email}");
      print("Data de Nascimento: ${userProfile.dataNascimento}");
      print("CPF: ${userProfile.cpf}");
      print("Ativo: ${userProfile.isActive}");
      print("Validado: ${userProfile.isValidated}");
      print("Admin: ${userProfile.isAdmin}");
      print("Role: ${userProfile.role}");
      print("Branch: ${userProfile.branch}");
      print("Permissions: ${userProfile.permissions}");
    } else {
      final accessToken = await _storage.getAccessToken();
      User? userProfile = await UserService().getUserProfile(
        accessToken: accessToken!,
      );

      if (userProfile != null) {
        await _storage.setUserProfile(userProfile);
        print("User profile loaded and stored locally.");
        print("User Profile:");
        print("ID: ${userProfile.id}");
        print("Username: ${userProfile.username}");
        print("Name: ${userProfile.name} ${userProfile.surname}");
        print("Email: ${userProfile.email}");
        print("Data de Nascimento: ${userProfile.dataNascimento}");
        print("CPF: ${userProfile.cpf}");
        print("Ativo: ${userProfile.isActive}");
        print("Validado: ${userProfile.isValidated}");
        print("Admin: ${userProfile.isAdmin}");
        print("Role: ${userProfile.role}");
        print("Branch: ${userProfile.branch}");
        print("Permissions: ${userProfile.permissions}");
      } else {
        print("Failed to load user profile.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _storage.user;

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Home Screen - ${user?.name ?? 'User'} ${user?.surname ?? ''}"),
                ElevatedButton(
                  onPressed: () async {
                    await _storage.clearTokens();
                    // await _storage.clearUserProfile();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

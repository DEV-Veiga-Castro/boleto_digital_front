import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ClientStorage _storage = ClientStorage();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Os campos de usuário e senha são obrigatórios.",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color.fromARGB(255, 251, 192, 45),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().login(
        _loginController.text,
        _passwordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Usuário logado com sucesso!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.verdeBoti,
        ),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
          
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao fazer login: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.vermelhoOui,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: 'Usuário'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:boleto_digital/services/auth_service.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = await _storage.isLoggedIn();

    if (!mounted) return;

    if (token) {
      print("Token encontrado, navegando para a tela principal...");
      // Se já existe um token, navega para a tela principal
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("Nenhum token encontrado, permanecendo na tela de login.");
    }

  }

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
      final request = await AuthService().login(
        _loginController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (request) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Usuário logado com sucesso!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.verdeBoti,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Credenciais inválidas. Por favor, tente novamente.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.vermelhoOui,
          ),
        );
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
    final viewHeight = MediaQuery.of(context).size.height;
    final viewWidth = MediaQuery.of(context).size.width;
    
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 150,
                height: 150,
                alignment: Alignment(0, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha(100),
                      spreadRadius: -8,
                      blurRadius: 15,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Image(
                  image: AssetImage('assets/imgs/logo_preta.png'),
                  // : 150,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                // padding: const EdgeInsets.symmetric(horizontal: 16.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: AppColors.cinzaContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: -4,
                      blurRadius: 10,
                      offset: const Offset(0, -3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: viewWidth * 0.8,
                          child: const Text(
                            'Bem-vindo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'GoogleSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      // color: Colors.white,
                      width: viewWidth * 0.8,
                      child: TextField(
                        controller: _loginController,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'nome.sobrenome',
                          label: Text(
                            'Usuário',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          icon: Icon(Icons.person_outline_rounded, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      width: viewWidth * 0.8,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '**********',
                          label: Text(
                            'Senha',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          icon: Icon(Icons.lock_outline_rounded, size: 26),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 32.0, top: 8.0),
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password action
                            },
                            child: const Text(
                              'Esqueceu sua senha?',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading
                            ? Colors.grey
                            : AppColors.verdeBoti,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        minimumSize: Size(viewWidth * 0.8, 48),
                        elevation: 2.0,
                        shadowColor: Colors.white.withAlpha(50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                                indent: 60,
                                endIndent: 16,
                              ),
                            ),
                            const Text(
                              'Ou',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                                indent: 16,
                                endIndent: 60,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            //TODO: Implementar login com Google
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.microsoft,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

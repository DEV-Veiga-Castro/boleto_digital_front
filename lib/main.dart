import 'package:boleto_digital/screens/home_screen.dart';
import 'package:boleto_digital/screens/login_screen.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:flutter/material.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  final storage = ClientStorage();
  final bool isLoggedIn = await storage.isLoggedIn();

  runApp(BoletoDigitalApp(isLoggedIn: isLoggedIn));
}

class BoletoDigitalApp extends StatelessWidget {
  final bool isLoggedIn;

  const BoletoDigitalApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boleto Digital',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.blackBackground,
        fontFamily: 'GoogleSans',
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

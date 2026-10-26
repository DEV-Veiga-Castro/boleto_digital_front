import 'package:boleto_digital/models/branch_model.dart';
import 'package:boleto_digital/models/dt_model.dart';
import 'package:boleto_digital/models/history_model.dart';
import 'package:boleto_digital/models/product_model.dart';
import 'package:boleto_digital/models/user_model.dart';
import 'package:boleto_digital/screens/history.dart';
import 'package:boleto_digital/screens/home_screen.dart';
import 'package:boleto_digital/screens/login_screen.dart';
import 'package:boleto_digital/screens/printing.dart';
import 'package:boleto_digital/screens/receive/initial.dart';
import 'package:boleto_digital/screens/receive/insert.dart';
import 'package:boleto_digital/screens/receive/list.dart';
import 'package:boleto_digital/screens/receive/revision.dart';
import 'package:boleto_digital/screens/send/initial.dart';
import 'package:boleto_digital/screens/send/insert.dart';
import 'package:boleto_digital/screens/send/revision.dart';
import 'package:boleto_digital/services/client_storage.dart';
import 'package:flutter/material.dart';
import 'package:boleto_digital/theme/app_colors.dart';
import 'package:boleto_digital/theme/app_theme_controller.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // WakelockPlus.enable();

  // final cameras = await availableCameras();

  // final firstCamera = cameras.first;

  final storage = ClientStorage();
  final bool isLoggedIn = await storage.isLoggedIn();
  await initializeDateFormatting('pt_BR', null);
  final themeController = await AppThemeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransferHistoryProvider()),
      ],
      child: BoletoDigitalApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class BoletoDigitalApp extends StatelessWidget {
  final bool isLoggedIn;
  // final CameraDescription camera;

  const BoletoDigitalApp({
    super.key,
    required this.isLoggedIn,
    // required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeController>(
      builder: (context, themeController, _) => MaterialApp(
        title: 'Boleto Digital',
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'GoogleSans',
          scaffoldBackgroundColor: AppColors.backgroundLight,
          colorScheme: const ColorScheme.light(
            primary: AppColors.verdeBoti,
            surface: AppColors.containerLight,
            secondary: AppColors.containerLight,
            tertiary: AppColors.dropdownLight,
            onPrimary: Colors.black,
            onSurface: Color(0xFF202420),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.backgroundLight,
            foregroundColor: Color(0xFF202420),
          ),
          cardColor: AppColors.containerLight,
          dividerColor: AppColors.inputBorder,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'GoogleSans',
          scaffoldBackgroundColor: AppColors.backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.verdeBoti,
            surface: AppColors.containerDark,
            secondary: AppColors.containerDark,
            tertiary: AppColors.dropdownDark,
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.backgroundDark,
            foregroundColor: Colors.white,
          ),
          cardColor: AppColors.containerDark,
          dividerColor: AppColors.inputBorder,
        ),
        initialRoute: '/login',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/send': (context) => const InitialSendScreen(),
          '/send/insert': (context) => const InsertSendScreen(),
          '/send/revision': (context) => const RevisionScreen(),
          '/history': (context) => const HistoryScreen(),
          '/receive/list': (context) => const ListReceiveScreen(),
          '/receive/initial': (context) => const InitialReceiveScreen(),
          '/receive/insert': (context) => const InsertReceiveScreen(),
          '/receive/revision': (context) => const RevisionReceiveScreen(),
          '/printing': (context) => const ImpressaoPage(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/auth_service.dart';
import 'core/data_bootstrap.dart';
import 'ui/design_canvas.dart';
import 'ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await showDeviceStatusBar(
    darkIcons: false,
    backgroundColor: const Color(0xFF0046FE),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final auth = AuthService();
  await auth.initialize();
  await initializeUserData(auth);
  runApp(SuperSolApp(auth: auth));
}

class SuperSolApp extends StatelessWidget {
  const SuperSolApp({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super SOL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075FF7),
          primary: const Color(0xFF075FF7),
        ),
        fontFamily: 'NotoSansKR',
        fontFamilyFallback: const [
          'Apple SD Gothic Neo',
          'Noto Sans KR',
          'Noto Sans',
          'Roboto',
        ],
      ),
      home: SplashScreen(auth: auth),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:notio/screens/splash_screen.dart';
import 'package:notio/theme/app_theme.dart';

import 'package:notio/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOTIO',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notio/screens/splash_screen.dart';
import 'package:notio/services/localization_service.dart';
import 'package:notio/theme/app_theme.dart';
import 'package:notio/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  StorageService().loadTheme();
  LocalizationService.init(); // Initialize language
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StorageService().themeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<Locale>(
            valueListenable: LocalizationService.currentLocale,
            builder: (context, locale, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'NOTIO',
                theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
                locale: locale,
                supportedLocales: LocalizationService.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SplashScreen(),
              );
            });
      },
    );
  }
}

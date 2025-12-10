import 'package:flutter/material.dart';
import 'package:notio/screens/notes_list_screen.dart';
import 'package:notio/widgets/tech_loading_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Simulate some loading time, e.g., fetching initial data or setting up services
    await Future.delayed(const Duration(seconds: 3), () {});
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: TechLoadingAnimation(
          loadingText: 'NOTIO BOOTING UP...', // Customize your text here
        ),
      ),
    );
  }
}

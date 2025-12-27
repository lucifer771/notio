import 'package:flutter/material.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/screens/home_screen.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/widgets/animated_logo.dart';
import 'package:notio/utils/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // ... existing init code ...
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);

    // Save User Name
    await StorageService().saveUserProfile(
      UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: '',
        isGuest: true, // User entering only name is a Guest
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E), // Deep indigo
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const AnimatedLogo(size: 150),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'NOTIO', // Brand name
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'write_smarter'.tr,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w300,
                                ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "whats_your_name".tr,
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          hintText: 'enter_name'.tr,
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SlideTransition(
                  position: _slideAnimation,
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 10,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'get_started'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

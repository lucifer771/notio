import 'package:flutter/material.dart';
import 'package:notio/screens/notes_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconGlowController;
  late Animation<double> _iconGlowAnimation;

  late AnimationController _dotsController;
  late Animation<double> _dotScaleAnimation;
  late Animation<double> _dotOpacityAnimation;

  late AnimationController _textFadeController;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Icon Glow Animation
    _iconGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconGlowController, curve: Curves.easeInOut),
    );

    // Dots Animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _dotScaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );
    _dotOpacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );

    // Text Fade-in Animation
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeIn),
    );

    _textFadeController.forward(); // Start text fade-in

    // Navigate after a delay
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4)); // Display for 4 seconds
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NotesListScreen()),
      );
    }
  }

  @override
  void dispose() {
    _iconGlowController.dispose();
    _dotsController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color.fromARGB(255, 25, 0, 50), // Deep purple/indigo
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              AnimatedBuilder(
                animation: _iconGlowAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(
                                0.5 * _iconGlowAnimation.value,
                              ),
                              blurRadius: 20.0 * _iconGlowAnimation.value,
                              spreadRadius: 5.0 * _iconGlowAnimation.value,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.description,
                          size: 100,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.wb_sunny,
                          size: 30,
                          color: Colors.yellow.withOpacity(0.8),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // App Name
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const Text(
                  'NOTIO',
                  style: TextStyle(
                    fontFamily:
                        'Montserrat', // Assuming a modern sans-serif like Montserrat
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    shadows: [
                      BoxShadow(
                        color: Colors.cyanAccent,
                        blurRadius: 15.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tagline
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const Text(
                  'Write Smarter.',
                  style: TextStyle(
                    fontFamily: 'Roboto', // Another common sans-serif
                    fontSize: 20,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      BoxShadow(
                        color: Colors.purpleAccent,
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Pagination Dots
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == 1; // Middle dot is active
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Transform.scale(
                          scale: isActive ? _dotScaleAnimation.value : 1.0,
                          child: Opacity(
                            opacity: isActive
                                ? _dotOpacityAnimation.value
                                : 0.5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? Colors.purpleAccent
                                    : Colors.white,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.purpleAccent
                                              .withOpacity(
                                                0.8 *
                                                    _dotOpacityAnimation.value,
                                              ),
                                          blurRadius:
                                              10.0 * _dotScaleAnimation.value,
                                          spreadRadius:
                                              3.0 * _dotScaleAnimation.value,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 80), // Spacer
              // Tap to continue
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const Text(
                  'Tap to continue',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.white38,
                    shadows: [
                      BoxShadow(color: Colors.white10, blurRadius: 5.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:notio/screens/notes_list_screen.dart';
import 'package:notio/services/gemini_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    // Initialize Gemini Service asynchronously
    GeminiService().initialize();

    // Navigate to Home / Onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NotesListScreen()),
    );
  }

  void _handleSignIn() {
    // Placeholder for Sign In navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Navigate to Sign In"),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen height helper for responsive spacing
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF05060F), // Top
              Color(0xFF02030A), // Bottom
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    
                    // 2. Illustration Section
                    const Expanded(
                      flex: 4,
                      child: _IllustrationSection(),
                    ),

                    // 3. Title Text
                    const Text(
                      'Welcome to NOTIO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Subtitle Text
                    const Text(
                      'Write Smarter with AI-powered notes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0B0D0), // Light grey / lavender tint
                        height: 1.5,
                      ),
                    ),
                    
                    const Spacer(flex: 1),

                    // 5. Primary Action Button
                    _PrimaryButton(onPressed: _handleGetStarted),
                    
                    const SizedBox(height: 16),

                    // 6. Secondary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _handleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.purpleAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 7. Footer Text
                    GestureDetector(
                      onTap: _handleSignIn,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: Colors.purpleAccent.shade100,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IllustrationSection extends StatelessWidget {
  const _IllustrationSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radial Glow
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        // Abstract Composition
        const Icon(
          Icons.person_outline_rounded,
          size: 140,
          color: Colors.deepPurpleAccent,
        ),
        Positioned(
          top: 40,
          right: 40,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 48,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 20,
          left: 60,
          child: Icon(
            Icons.lightbulb,
            size: 32,
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PrimaryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EA), Color(0xFFB388FF)], // Purple gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: const Center(
            child: Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
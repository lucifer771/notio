import 'package:flutter/material.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/widgets/animated_logo.dart';
import 'package:notio/utils/constants.dart';
import 'package:notio/widgets/cross_platform_image.dart';

class CollaborationAnimation extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onComplete;

  const CollaborationAnimation({
    super.key,
    required this.user,
    required this.onComplete,
  });

  @override
  State<CollaborationAnimation> createState() => _CollaborationAnimationState();
}

class _CollaborationAnimationState extends State<CollaborationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeCheck;
  late Animation<double> _slideLeft;
  late Animation<double> _slideRight;
  late Animation<double> _connectBeam;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // 1. Appear (0.0 - 0.2)
    _fadeCheck = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // 2. Move to Center (0.2 - 0.5)
    _slideLeft = Tween<double>(begin: -100.0, end: -30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOutBack),
      ),
    );

    _slideRight = Tween<double>(begin: 100.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOutBack),
      ),
    );

    // 3. Connect Beam (0.5 - 0.7)
    _connectBeam = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeInOut),
      ),
    );

    // 4. Text Fade (0.7 - 0.9)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      // Wait a moment then close
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95), // Deep dark overlay
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 180, // More space for pulse
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse Effect (Background)
                      if (_connectBeam.value > 0.5)
                        ScaleTransition(
                          scale: Tween(begin: 0.8, end: 1.5).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.6,
                                1.0,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                          child: Opacity(
                            opacity: (1.0 - _connectBeam.value) * 0.5,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF6C63FF).withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Connection Beam (Dynamic Line)
                      if (_connectBeam.value > 0)
                        Center(
                          child: Container(
                            width: 100 * _connectBeam.value,
                            height: 6, // Thicker beam
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Colors.blueAccent],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.8),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Notio Logo (Left)
                      Transform.translate(
                        offset: Offset(
                          _slideLeft.value * 1.5,
                          0,
                        ), // Use wider start
                        child: Opacity(
                          opacity: _fadeCheck.value,
                          child: const AnimatedLogo(
                            size: 70,
                          ), // Slightly larger
                        ),
                      ),

                      // User Avatar (Right)
                      Transform.translate(
                        offset: Offset(_slideRight.value * 1.5, 0),
                        child: Opacity(
                          opacity: _fadeCheck.value,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.grey],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2), // Inner spacing
                            child: ClipOval(
                              child: widget.user.profileImagePath != null
                                  ? CrossPlatformImage(
                                      path: widget.user.profileImagePath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      AppConstants.avatars[widget
                                              .user
                                              .avatarIndex %
                                          AppConstants.avatars.length],
                                      color: Colors.black87,
                                      size: 40,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Text
                Opacity(
                  opacity: _textFade.value,
                  child: Column(
                    children: [
                      const Text(
                        'THANKS FOR COLLABORATING',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          letterSpacing: 2.5,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'WITH US, '),
                            TextSpan(
                              text: widget.user.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

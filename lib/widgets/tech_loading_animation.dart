import 'dart:math';
import 'package:flutter/material.dart';
import 'package:notio/models/particle.dart';

class TechLoadingAnimation extends StatefulWidget {
  final String loadingText;

  const TechLoadingAnimation({super.key, this.loadingText = 'LOADING...'});

  @override
  State<TechLoadingAnimation> createState() => _TechLoadingAnimationState();
}

class _TechLoadingAnimationState extends State<TechLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  late AnimationController _flareController;
  late Animation<double> _flareAnimation;

  late AnimationController _textFlickerController;
  late Animation<double> _textFlickerAnimation;

  late AnimationController _particleController;
  late Animation<double> _particleAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Ring Rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotationController);

    // Highlight Segment Animation
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _highlightAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_highlightController);

    // Digital Light Flare Pulse
    _flareController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _flareAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _flareController, curve: Curves.easeInOut),
        );

    // Text Flicker
    _textFlickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(period: const Duration(seconds: 2));
    _textFlickerAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _textFlickerController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Particle Animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_particleController);

    _particleController.addListener(() {
      if (_particleController.value < 0.1) {
        // Spawn new particles at the beginning of the animation cycle
        _spawnParticles(5); // Spawn a few particles each cycle
      }
      _updateParticles();
    });
  }

  void _spawnParticles(int count) {
    for (int i = 0; i < count; i++) {
      _particles.add(
        Particle(
          position: Offset(
            _random.nextDouble() * 20 - 10, // Slightly off center
            _random.nextDouble() * 20 - 10,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 50,
            (_random.nextDouble() - 0.5) * 50,
          ),
          color: Colors.cyanAccent.withOpacity(_random.nextDouble()),
          size: _random.nextDouble() * 2 + 1,
          lifetime: _random.nextDouble() * 0.8 + 0.2,
        ),
      );
    }
  }

  void _updateParticles() {
    setState(() {
      _particles.removeWhere((p) => p.progress >= 1.0);
      for (var p in _particles) {
        p.update(_particleController.value);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _highlightController.dispose();
    _flareController.dispose();
    _textFlickerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Deep black / charcoal background
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _highlightController,
          _flareController,
          _textFlickerController,
          _particleController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _TechLoadingPainter(
              rotation: _rotationAnimation.value,
              highlightOffset: _highlightAnimation.value,
              flarePulse: _flareAnimation.value,
              textFlicker: _textFlickerAnimation.value,
              particles: _particles,
              loadingText: widget.loadingText,
            ),
            child: const Center(
              // This child can be used for static background elements if needed
              // For now, CustomPainter handles everything.
              child: SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _TechLoadingPainter extends CustomPainter {
  final double rotation;
  final double highlightOffset;
  final double flarePulse;
  final double textFlicker;
  final List<Particle> particles;
  final String loadingText;

  _TechLoadingPainter({
    required this.rotation,
    required this.highlightOffset,
    required this.flarePulse,
    required this.textFlicker,
    required this.particles,
    required this.loadingText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.3;

    // Paint for glowing effects
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);

    // Paint for main ring
    final ringPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // Paint for highlights
    final highlightPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0);

    // Paint for flare
    final flarePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue.withOpacity(0.8 * flarePulse),
          Colors.cyan.withOpacity(0.5 * flarePulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.8));

    // Draw Hexagonal Grid Background (Optional Add-on)
    _drawHexGrid(canvas, size, center);

    // Draw Digital Tracking Scan Lines (Optional Add-on)
    _drawScanLines(canvas, size);

    // Draw the central light flare
    canvas.drawCircle(center, radius * 0.5 * flarePulse, flarePaint);

    // Draw the main rotating ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius, glowPaint); // Soft glow for the ring

    // Draw segmented highlights
    final numSegments = 6;
    final segmentAngle = (2 * pi) / numSegments;
    final highlightLength = segmentAngle * 0.6; // Length of each highlight

    for (int i = 0; i < numSegments; i++) {
      final startAngle = (i * segmentAngle) + highlightOffset;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        highlightLength,
        false,
        highlightPaint,
      );
    }
    canvas.restore();

    // Draw particles
    for (var p in particles) {
      final particlePaint = Paint()
        ..color = p.color.withOpacity(1.0 - p.progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5);
      canvas.drawCircle(
        center + p.position,
        p.size * (1.0 - p.progress),
        particlePaint,
      );
    }

    // Draw "LOADING..." text
    final textSpan = TextSpan(
      text: loadingText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8 * textFlicker),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.cyanAccent.withOpacity(0.5 * textFlicker),
            blurRadius: 10.0,
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawHexGrid(Canvas canvas, Size size, Offset center) {
    final gridPaint = Paint()
      ..color = Colors.blue
          .withOpacity(0.05) // Very subtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final hexSize = 50.0;
    final hexHeight = hexSize * sqrt(3);
    final hexWidth = hexSize * 2;

    for (
      double y = -size.height / 2;
      y < size.height / 2;
      y += hexHeight * 0.75
    ) {
      for (
        double x = -size.width / 2;
        x < size.width / 2;
        x += hexWidth * 0.75
      ) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = pi / 3 * i;
          final point = Offset(
            x + hexSize * cos(angle),
            y + hexSize * sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path.shift(center), gridPaint);
      }
    }
  }

  void _drawScanLines(Canvas canvas, Size size) {
    final scanLinePaint = Paint()
      ..color = Colors.cyanAccent
          .withOpacity(0.03) // Very subtle
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TechLoadingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.highlightOffset != highlightOffset ||
        oldDelegate.flarePulse != flarePulse ||
        oldDelegate.textFlicker != textFlicker ||
        oldDelegate.particles.length !=
            particles.length; // Simple check for particles
  }
}

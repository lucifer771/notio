import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double lifetime; // 0.0 to 1.0
  double progress = 0.0;
  double _previousAnimationValue = 0.0;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });

  void update(double animationValue) {
    // Simple update based on the controller's value
    // This makes particles move and fade over the duration of the particleController
    progress = animationValue / lifetime;
    if (progress <= 1.0) {
      // Calculate delta time based on animation value change
      // Handle wrap-around or reset if necessary (though simple subtraction works for linear 0->1)
      double delta = progress == 0
          ? 0
          : (animationValue - _previousAnimationValue);

      // Avoid negative delta if animation restarts
      if (delta < 0) delta = 0;

      position += velocity * delta;
    }
    _previousAnimationValue = animationValue;
  }
}

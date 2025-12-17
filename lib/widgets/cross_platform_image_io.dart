import 'dart:io';
import 'package:flutter/material.dart';

class CrossPlatformImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CrossPlatformImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.white24);
      },
    );
  }
}

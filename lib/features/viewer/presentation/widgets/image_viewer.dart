import 'dart:io';
import 'package:flutter/material.dart';

/// Full-bleed image viewer with pinch-to-zoom and tap-to-toggle-controls.
class ImageViewer extends StatelessWidget {
  final String filePath;
  final VoidCallback? onTap;

  const ImageViewer({
    required this.filePath,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Failed to load image',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
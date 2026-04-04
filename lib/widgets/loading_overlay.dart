import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModernLoadingOverlay extends StatelessWidget {
  final String message;
  
  const ModernLoadingOverlay({
    super.key,
    this.message = "Préparation...",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Backdrop Blur Effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.4) 
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        
        // Centered Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Elegant Rotating Circle
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
              
              const SizedBox(height: 24),
              
              // Minimalist Loading Text
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ).animate().fadeIn(duration: 600.ms),
            ],
          ),
        ),
      ],
    );
  }
}

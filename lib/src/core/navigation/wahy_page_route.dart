import 'package:flutter/material.dart';

/// Premium page transition for the Al-Quran app.
/// Combines subtle slide-up with fade for a modern, smooth feel.
class WahyPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool isModal;

  WahyPageRoute({
    required this.page,
    this.isModal = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (isModal) {
              // Modal: scale + fade from center
              return ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            }
            // Standard: slide up + fade
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );
            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

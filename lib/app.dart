import 'package:flutter/material.dart';

import 'theme.dart';
import 'splash.dart';

class ToadHealthApp extends StatelessWidget {
  const ToadHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'toadHEALTH',
      debugShowCheckedModeBanner: false,
      theme: buildToadTheme(),
      home: const SplashScreen(),
    );
  }
}

/// Flowing page transition: a gentle rise and fade, like a lily pad drifting.
class FlowRoute<T> extends PageRouteBuilder<T> {
  FlowRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

// lib/screens/splash_screen.dart
// MediSync Splash Screen – shows logo then routes to auth gate.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  /// Called when splash is done — navigate to next screen from here.
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim  = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    // Start animation then wait, then call onDone
    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo image ──
                  // Place your MediSync logo PNG at: assets/images/medisync_logo.png
                  // Make sure to add to pubspec.yaml (see instructions below)
                  Image.asset(
                    'assets/images/medisync_logo.png',
                    width:  220,
                    height: 220,
                    fit:    BoxFit.contain,
                    // Fallback if asset not found yet
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width:  120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryDark, AppTheme.primaryTeal],
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color:      AppTheme.primaryTeal.withValues(alpha: 0.4),
                                blurRadius: 30,
                                offset:     const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.medical_services_rounded,
                              color: Colors.white, size: 64),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF1A3A8F), AppTheme.primaryTeal],
                          ).createShader(bounds),
                          child: const Text(
                            'MediSync',
                            style: TextStyle(
                              fontSize:   42,
                              fontWeight: FontWeight.w900,
                              color:      Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keeping You in Sync with Your Health.',
                          style: TextStyle(
                            fontSize:   14,
                            color:      AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
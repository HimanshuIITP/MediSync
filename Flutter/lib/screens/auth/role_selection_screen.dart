// lib/screens/auth/role_selection_screen.dart
// MediSync opening screen – logo + role selection.
// FIX: role cards use flexible height to prevent RenderFlex overflow.

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background blobs ──
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 80, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -60, right: -40,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentMint.withValues(alpha: 0.6),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),

                  // ── MediSync Logo ──
                  // Tries to load your PNG asset; falls back to icon if not found
                  Image.asset(
                    'assets/images/medisync_logo.png',
                    width:  160,
                    height: 160,
                    fit:    BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width:  90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primaryTeal],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color:      AppTheme.primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset:     const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 46),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // App name
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF1A3A8F), AppTheme.primaryTeal],
                    ).createShader(bounds),
                    child: const Text(
                      'MediSync',
                      style: TextStyle(
                        fontSize:   36,
                        fontWeight: FontWeight.w900,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keeping You in Sync with Your Health.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.04),

                  Text(
                    'Continue as',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textMedium, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // ── Role Cards — FIX: IntrinsicHeight prevents overflow ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _RoleCard(
                            role:     UserRole.patient,
                            emoji:    '🧑‍⚕️',
                            title:    'Patient',
                            subtitle: 'Book appointments\n& manage health',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1DE9B6), Color(0xFF00838F)],
                              begin:  Alignment.topLeft,
                              end:    Alignment.bottomRight,
                            ),
                            onTap: () => _goToLogin(context, UserRole.patient),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _RoleCard(
                            role:     UserRole.doctor,
                            emoji:    '🩺',
                            title:    'Doctor',
                            subtitle: 'Manage patients\n& appointments',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B61FF), Color(0xFF5C3FBF)],
                              begin:  Alignment.topLeft,
                              end:    Alignment.bottomRight,
                            ),
                            onTap: () => _goToLogin(context, UserRole.doctor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Demo credentials
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(color: AppTheme.divider),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.info_outline,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Text('Demo Credentials',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                      const SizedBox(height: 5),
                      const _CredRow(label: 'Patient',  value: 'patient@demo.com'),
                      const _CredRow(label: 'Doctor',   value: 'doctor@demo.com'),
                      const _CredRow(label: 'Password', value: 'demo123'),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }
}

// ── Role Card — FIX: no fixed height, uses flexible layout ───────────────────
class _RoleCard extends StatefulWidget {
  final UserRole     role;
  final String       emoji, title, subtitle;
  final Gradient     gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          // FIX: removed fixed height:190, now uses intrinsic height from parent
          // Added minHeight via constraints so cards never get too small
          constraints: const BoxConstraints(minHeight: 160),
          decoration: BoxDecoration(
            gradient:     widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.role == UserRole.patient
                        ? AppTheme.primaryTeal
                        : const Color(0xFF7B61FF))
                    .withValues(alpha: 0.35),
                blurRadius: 20,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // FIX: mainAxisSize.min lets the card grow with content
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji,
                  style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text(widget.title,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  style: const TextStyle(
                      color:      Colors.white70,
                      fontSize:   12,
                      fontWeight: FontWeight.w500,
                      height:     1.4)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Login / Sign up',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label, value;
  const _CredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        SizedBox(
          width: 60,
          child: Text('$label:',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textLight)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize:   11,
                color:      AppTheme.textDark,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
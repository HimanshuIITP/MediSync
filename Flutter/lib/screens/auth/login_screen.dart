// lib/screens/auth/login_screen.dart
// Shared login screen – role-aware UI (Patient or Doctor).

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
// FIX: removed broad '../../main.dart' import; import only what is needed
import '../../main.dart' show MainNavigation;
import 'signup_screen.dart';
import '../doctor/doctor_main_navigation.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePass  = true;
  bool  _isLoading    = false;
  String? _errorMsg;

  bool  get _isDoctor    => widget.role == UserRole.doctor;
  Color get _accentColor => _isDoctor ? const Color(0xFF7B61FF) : AppTheme.primaryTeal;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final error = await AuthService().login(
      email:        _emailCtrl.text,
      password:     _passwordCtrl.text,
      expectedRole: widget.role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    if (_isDoctor) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DoctorMainNavigation()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        foregroundColor: AppTheme.textDark,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Container(
                  width:  60,
                  height: 60,
                  decoration: BoxDecoration(
                    // FIX: replaced withOpacity with withValues
                    color:        _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _isDoctor ? Icons.medical_services_outlined : Icons.person_2_outlined,
                    color: _accentColor,
                    size:  32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isDoctor ? 'Doctor Sign In' : 'Patient Sign In',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  _isDoctor
                      ? 'Welcome back, Doctor. Your patients are waiting.'
                      : 'Welcome back! Let\'s take care of your health.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textLight),
                ),
                const SizedBox(height: 36),

                // ── Email ──
                TextFormField(
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText:  'Email address',
                    prefixIcon: Icon(Icons.email_outlined, color: _accentColor),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // ── Password ──
                TextFormField(
                  controller:  _passwordCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText:  'Password',
                    prefixIcon: Icon(Icons.lock_outlined, color: _accentColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 4) ? 'Enter a valid password' : null,
                ),

                // ── Error message ──
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:        AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Login Button ──
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 24),
                const Row(children: [
                  Expanded(child: Divider()),
                  SizedBox(width: 12),
                  Text("Don't have an account?",
                      style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                  SizedBox(width: 12),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // ── Sign Up Button ──
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(color: _accentColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SignupScreen(role: widget.role)),
                    ),
                    child: const Text('Create Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Quick demo fill ──
                GestureDetector(
                  onTap: () {
                    _emailCtrl.text    = _isDoctor ? 'doctor@demo.com' : 'patient@demo.com';
                    _passwordCtrl.text = 'demo123';
                  },
                  child: Center(
                    child: Text(
                      '⚡ Tap to use demo credentials',
                      style: TextStyle(
                        color:      _accentColor,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
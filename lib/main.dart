// lib/main.dart
// Entry point – Firebase init + splash + auth gate + bottom navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analyzer_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/doctor/doctor_main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MediSyncApp());
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'MediSync',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.lightTheme,
      home:                       const _SplashToAuthGate(),
    );
  }
}

// ── Splash → Auth Gate ────────────────────────────────────────────────────────
// Shows splash first, then decides where to go based on Firebase auth state.
class _SplashToAuthGate extends StatefulWidget {
  const _SplashToAuthGate();

  @override
  State<_SplashToAuthGate> createState() => _SplashToAuthGateState();
}

class _SplashToAuthGateState extends State<_SplashToAuthGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onDone: () => setState(() => _splashDone = true),
      );
    }
    return const _AuthGate();
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_rebuild);
  }

  @override
  void dispose() {
    _auth.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryTeal,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.medical_services_rounded, color: Colors.white, size: 60),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      );
    }
    if (!_auth.isLoggedIn)   return const RoleSelectionScreen();
    if (_auth.role == UserRole.doctor) return const DoctorMainNavigation();
    return const MainNavigation();
  }
}

// ── Patient Main Navigation ───────────────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AnalyzerScreen(),
    ChatbotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key:      ValueKey<int>(_selectedIndex),
          index:    _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _MedBottomBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _MedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _MedBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:      AppTheme.primaryTeal.withValues(alpha: 0.12),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Booking',     isActive: currentIndex == 0,
                  onTap: () => onTap(0)),
              _NavItem(icon: Icons.document_scanner_outlined,
                  activeIcon: Icons.document_scanner,
                  label: 'AI Analyzer', isActive: currentIndex == 1,
                  onTap: () => onTap(1)),
              _NavItem(icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy,
                  label: 'AI Chat',     isActive: currentIndex == 2,
                  onTap: () => onTap(2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon,
      required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        isActive
              ? AppTheme.primaryTeal.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryTeal : AppTheme.textLight,
              size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize:   11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color:      isActive ? AppTheme.primaryTeal : AppTheme.textLight,
          )),
        ]),
      ),
    );
  }
}
// lib/screens/doctor/doctor_main_navigation.dart
// Doctor-side bottom navigation: Dashboard / Appointments / Profile

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorMainNavigation extends StatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  State<DoctorMainNavigation> createState() => _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends State<DoctorMainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    DoctorDashboardScreen(),
    DoctorAppointmentsScreen(),
    DoctorProfileScreen(),
  ];

  static const Color _doctorAccent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key:      ValueKey<int>(_selectedIndex),
          index:    _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // FIX: replaced withOpacity with withValues
              color:      _doctorAccent.withValues(alpha: 0.12),
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
                _DoctorNavItem(
                  icon:       Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label:      'Dashboard',
                  isActive:   _selectedIndex == 0,
                  onTap:      () => setState(() => _selectedIndex = 0),
                ),
                _DoctorNavItem(
                  icon:       Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label:      'Appointments',
                  isActive:   _selectedIndex == 1,
                  onTap:      () => setState(() => _selectedIndex = 1),
                ),
                _DoctorNavItem(
                  icon:       Icons.person_outline,
                  activeIcon: Icons.person,
                  label:      'Profile',
                  isActive:   _selectedIndex == 2,
                  onTap:      () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorNavItem extends StatelessWidget {
  static const Color _accent = Color(0xFF7B61FF);

  final IconData     icon;
  final IconData     activeIcon;
  final String       label;
  final bool         isActive;
  final VoidCallback onTap;

  const _DoctorNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 200),
        padding:   const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          // FIX: replaced withOpacity with withValues
          color:        isActive ? _accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _accent : AppTheme.textLight,
              size:  24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color:      isActive ? _accent : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
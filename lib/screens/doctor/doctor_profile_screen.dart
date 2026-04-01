// lib/screens/doctor/doctor_profile_screen.dart
// Doctor's own profile screen.

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/role_selection_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  static const Color _accent = Color(0xFF7B61FF);
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon:    const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit profile',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Purple header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5C3FBF), Color(0xFF7B61FF)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              children: [
                // Avatar
                Container(
                  width:  90,
                  height: 90,
                  decoration: BoxDecoration(
                    // FIX: replaced withOpacity with withValues
                    color:  Colors.white.withValues(alpha: 0.2),
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      (user?.name ?? 'DR')
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   30,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Doctor',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.specialty ?? 'Specialist',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.hospital ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 16),
                // FIX: stats row — only show data we actually have from the model;
                // placeholder values shown for demo fields not in UserModel.
                Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  _HeaderStat(label: 'Rating',     value: '4.9 ⭐'),
                  _VertDivider(),
                  _HeaderStat(label: 'Experience', value: '16 yrs'),
                  _VertDivider(),
                  _HeaderStat(label: 'Patients',   value: '1,200+'),
                ]),
              ],
            ),
          ),

          // ── Availability toggle ──
          Container(
            margin:   const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isAvailable ? AppTheme.success : AppTheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.circle,
                    size:  14,
                    color: _isAvailable ? AppTheme.success : AppTheme.error),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAvailable
                          ? 'Available for Appointments'
                          : 'Currently Unavailable',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 14),
                    ),
                    Text(
                      _isAvailable
                          ? 'Patients can book slots with you'
                          : 'Your slots are hidden from patients',
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value:       _isAvailable,
                activeColor: AppTheme.success,
                onChanged:   (v) => setState(() => _isAvailable = v),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Info cards ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Professional Information',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _InfoCard(children: [
                  _InfoRow(
                      icon:  Icons.badge_outlined,
                      label: 'Reg. No',
                      value: user?.registrationNumber ?? 'MCI-2024-KA-48291'),
                  _InfoRow(
                      icon:  Icons.local_hospital_outlined,
                      label: 'Hospital',
                      value: user?.hospital ?? 'Apollo Heart Institute'),
                  _InfoRow(
                      icon:  Icons.medical_services_outlined,
                      label: 'Specialty',
                      value: user?.specialty ?? 'Cardiologist'),
                  _InfoRow(
                      icon:  Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? ''),
                ]),
                const SizedBox(height: 20),

                Text('Consultation Fee & Slots',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _InfoCard(children: const [
                  _InfoRow(icon: Icons.currency_rupee,       label: 'Fee',          value: '₹1,200 per visit'),
                  _InfoRow(icon: Icons.access_time_outlined,  label: 'Duration',     value: '30 minutes'),
                  _InfoRow(icon: Icons.calendar_month,        label: 'Working days', value: 'Mon – Sat'),
                  _InfoRow(icon: Icons.event_available,       label: 'Hours',        value: '9:00 AM – 6:00 PM'),
                ]),
                const SizedBox(height: 20),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side:  const BorderSide(color: AppTheme.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon:  const Icon(Icons.logout),
                    label: const Text('Sign Out',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      AuthService().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) => Container(
        width:  1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color:  Colors.white30,
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: children.map((child) {
          return Column(children: [
            child,
            if (children.last != child) const Divider(height: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF7B61FF)),
      const SizedBox(width: 12),
      SizedBox(
        width: 80,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
      ),
    ]);
  }
}
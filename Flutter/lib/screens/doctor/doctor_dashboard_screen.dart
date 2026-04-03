// lib/screens/doctor/doctor_dashboard_screen.dart
// FIX: Removed .orderBy('createdAt') — same composite index issue as appointments screen.
// Sort is done in Dart after fetching.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/role_selection_screen.dart';
import 'patient_detail_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    final user     = AuthService().currentUser;
    final doctorId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: StreamBuilder<QuerySnapshot>(
        // FIX: no orderBy — just where(), sort in Dart
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snap) {
          // Parse
          final allAppts = (snap.data?.docs ?? [])
              .map((d) => AppointmentModel.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          // Sort newest first in Dart
          allAppts.sort((a, b) {
            final ta = a.createdAt ?? DateTime(2000);
            final tb = b.createdAt ?? DateTime(2000);
            return tb.compareTo(ta);
          });

          final todayAppts = _todayAppointments(allAppts);
          final upcoming   = allAppts
              .where((a) => a.status == AppointmentStatus.accepted)
              .length;
          final completed  = allAppts
              .where((a) => a.status == AppointmentStatus.completed)
              .length;

          return CustomScrollView(
            slivers: [
              // ── AppBar ──
              SliverAppBar(
                expandedHeight:  170,
                floating:        false,
                pinned:          true,
                backgroundColor: _accent,
                actions: [
                  IconButton(
                    icon:    const Icon(Icons.logout, color: Colors.white70),
                    tooltip: 'Sign out',
                    onPressed: () {
                      AuthService().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const RoleSelectionScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      _DoctorHeader(userName: user?.name ?? 'Doctor'),
                ),
                title: const Text('Dashboard',
                    style: TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w800)),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats ──
                      Row(children: [
                        _StatCard(
                            label: 'Upcoming',
                            value: '$upcoming',
                            icon:  Icons.pending_actions,
                            color: _accent),
                        const SizedBox(width: 12),
                        _StatCard(
                            label: 'Completed',
                            value: '$completed',
                            icon:  Icons.check_circle_outline,
                            color: AppTheme.success),
                        const SizedBox(width: 12),
                        _StatCard(
                            label: 'Total',
                            value: '${allAppts.length}',
                            icon:  Icons.people_outline,
                            color: AppTheme.primaryTeal),
                      ]),

                      const SizedBox(height: 28),

                      // ── Quick Actions ──
                      Text('Quick Actions',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Row(children: [
                        _QuickAction(
                            icon:  Icons.add_circle_outline,
                            label: 'Add Slot',
                            color: _accent,
                            onTap: () {}),
                        const SizedBox(width: 12),
                        _QuickAction(
                            icon:  Icons.description_outlined,
                            label: 'Write Note',
                            color: AppTheme.primaryTeal,
                            onTap: () {}),
                        const SizedBox(width: 12),
                        _QuickAction(
                            icon:  Icons.bar_chart,
                            label: 'Reports',
                            color: const Color(0xFFEF5350),
                            onTap: () {}),
                        const SizedBox(width: 12),
                        _QuickAction(
                            icon:  Icons.message_outlined,
                            label: 'Messages',
                            color: AppTheme.warning,
                            onTap: () {}),
                      ]),

                      const SizedBox(height: 28),

                      // ── Today's Schedule ──
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Schedule",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge),
                          Text(
                            '${todayAppts.length} appointments',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: _accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (snap.connectionState ==
                              ConnectionState.waiting &&
                          !snap.hasData)
                        const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF7B61FF)))
                      else if (todayAppts.isEmpty)
                        const _EmptySchedule()
                      else
                        ...todayAppts.map((appt) => _ScheduleCard(
                              appt:  appt,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailScreen(
                                            appointment: appt)),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppointmentModel> _todayAppointments(
      List<AppointmentModel> all) {
    final now    = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final todayStr =
        '${months[now.month - 1]} ${now.day}, ${now.year}';
    return all
        .where((a) =>
            a.date.contains(todayStr) ||
            a.date.startsWith('Today'))
        .toList();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DoctorHeader extends StatelessWidget {
  final String userName;
  const _DoctorHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5C3FBF),
            Color(0xFF7B61FF),
            Color(0xFF9C8FFF)
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Welcome back 👋',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(userName,
                style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
                'Your patients are ready to see you today.',
                style: TextStyle(
                    color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:      color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset:     const Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize:   24,
                  fontWeight: FontWeight.w800,
                  color:      color)),
          Text(label,
              style: const TextStyle(
                  fontSize:   11,
                  color:      AppTheme.textLight,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    color:      color)),
          ]),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final AppointmentModel appt;
  final VoidCallback     onTap;
  const _ScheduleCard(
      {required this.appt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.05),
                blurRadius: 10)
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(appt.timeSlot,
                style: const TextStyle(
                    color:      Color(0xFF7B61FF),
                    fontWeight: FontWeight.w800,
                    fontSize:   12)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(appt.patientName,
                  style:
                      Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(appt.symptoms,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              color: AppTheme.textLight),
        ]),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:   const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: const Column(children: [
        Icon(Icons.event_available,
            size: 40, color: AppTheme.textLight),
        SizedBox(height: 10),
        Text('No appointments today',
            style: TextStyle(
                color:      AppTheme.textMedium,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

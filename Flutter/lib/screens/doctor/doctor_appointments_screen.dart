// lib/screens/doctor/doctor_appointments_screen.dart
// FIX: Removed .orderBy('createdAt') from Firestore query.
// Combining where() + orderBy() on different fields requires a Firestore
// composite index. Without that index the data briefly appears then vanishes.
// Solution: fetch with where() only, then sort the list in Dart.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'patient_detail_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen> {
  static const Color _accent = Color(0xFF7B61FF);
  AppointmentStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Text('Appointments',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon:      const Icon(Icons.search, color: Colors.white),
              onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIX: only where() — no orderBy() — avoids composite index requirement
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snap) {
          // Show spinner only on first load, not on every update
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF7B61FF)));
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading appointments.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMedium)),
              ),
            );
          }

          // Parse all appointments
          final all = (snap.data?.docs ?? [])
              .map((d) => AppointmentModel.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          // FIX: sort in Dart (newest first) instead of using orderBy in query
          all.sort((a, b) {
            final ta = a.createdAt ?? DateTime(2000);
            final tb = b.createdAt ?? DateTime(2000);
            return tb.compareTo(ta); // descending
          });

          // Apply status filter
          final filtered = _filterStatus == null
              ? all
              : all
                  .where((a) => a.status == _filterStatus)
                  .toList();

          final upcoming  =
              all.where((a) => a.status == AppointmentStatus.upcoming).length;
          final completed =
              all.where((a) => a.status == AppointmentStatus.completed).length;
          final cancelled =
              all.where((a) => a.status == AppointmentStatus.cancelled).length;

          return Column(children: [
            // ── Summary ribbon ──
            Container(
              color:   _accent,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                _MiniStat(value: '$upcoming',  label: 'Upcoming'),
                _MiniStat(value: '$completed', label: 'Completed'),
                _MiniStat(value: '$cancelled', label: 'Cancelled'),
              ]),
            ),

            // ── Filter chips ──
            Container(
              color:   Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(
                      label:    'All',
                      isActive: _filterStatus == null,
                      onTap:    () =>
                          setState(() => _filterStatus = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label:    'Upcoming',
                      isActive:
                          _filterStatus == AppointmentStatus.upcoming,
                      onTap: () => setState(
                          () => _filterStatus = AppointmentStatus.upcoming)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label:    'Completed',
                      isActive:
                          _filterStatus == AppointmentStatus.completed,
                      onTap: () => setState(() =>
                          _filterStatus = AppointmentStatus.completed)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label:    'Cancelled',
                      isActive:
                          _filterStatus == AppointmentStatus.cancelled,
                      onTap: () => setState(() =>
                          _filterStatus = AppointmentStatus.cancelled)),
                ]),
              ),
            ),
            const Divider(height: 1),

            // ── Appointment list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        const Icon(Icons.inbox_outlined,
                            size: 48, color: AppTheme.textLight),
                        const SizedBox(height: 10),
                        Text(
                          all.isEmpty
                              ? 'No appointments yet'
                              : 'No ${_filterStatus?.label ?? ''} appointments',
                          style: const TextStyle(
                              color: AppTheme.textMedium),
                        ),
                      ]))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount:        filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) => _AppointmentCard(
                        appt:  filtered[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(
                                  appointment: filtered[i])),
                        ),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ]),
      );
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         isActive;
  final VoidCallback onTap;
  static const Color _accent = Color(0xFF7B61FF);

  const _FilterChip(
      {required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:  const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        isActive ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? _accent : AppTheme.divider,
              width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:
                  isActive ? Colors.white : AppTheme.textMedium,
            )),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  final VoidCallback     onTap;

  static const Map<AppointmentStatus, Color> _colors = {
    AppointmentStatus.upcoming:  Color(0xFF7B61FF),
    AppointmentStatus.completed: AppTheme.success,
    AppointmentStatus.cancelled: AppTheme.error,
  };
  static const Map<AppointmentStatus, IconData> _icons = {
    AppointmentStatus.upcoming:  Icons.schedule,
    AppointmentStatus.completed: Icons.check_circle_outline,
    AppointmentStatus.cancelled: Icons.cancel_outlined,
  };

  const _AppointmentCard(
      {required this.appt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = _colors[appt.status]!;
    final i = _icons[appt.status]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.05),
                blurRadius: 10)
          ],
          border: Border(left: BorderSide(color: c, width: 4)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius:          24,
            backgroundColor: c.withValues(alpha: 0.12),
            child: Text(
              appt.patientName
                  .split(' ')
                  .map((e) => e[0])
                  .take(2)
                  .join(),
              style: TextStyle(
                  color:      c,
                  fontWeight: FontWeight.w800,
                  fontSize:   14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                    child: Text(appt.patientName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        c.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(i, size: 11, color: c),
                    const SizedBox(width: 4),
                    Text(appt.status.label,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      c)),
                  ]),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                '${appt.date}  •  ${appt.timeSlot}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appt.symptoms,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          fontSize: 11,
                          color:    AppTheme.textMedium),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.textLight),
        ]),
      ),
    );
  }
}
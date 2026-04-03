// lib/screens/patient_bookings_screen.dart
// Patient's appointment history — pending, upcoming, completed, cancelled.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class PatientBookingsScreen extends StatefulWidget {
  const PatientBookingsScreen({super.key});

  @override
  State<PatientBookingsScreen> createState() =>
      _PatientBookingsScreenState();
}

class _PatientBookingsScreenState extends State<PatientBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        title: const Text('My Appointments',
            style: TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller:          _tabCtrl,
          indicatorColor:      Colors.white,
          indicatorWeight:     3,
          labelColor:          Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: FirestoreService()
            .patientAppointmentsStream(patientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryTeal));
          }

          final all = snap.data ?? [];
          final pending   = all.where((a) =>
              a.status == AppointmentStatus.pending).toList();
          final accepted  = all.where((a) =>
              a.status == AppointmentStatus.accepted).toList();
          final completed = all.where((a) =>
              a.status == AppointmentStatus.completed).toList();
          final cancelled = all.where((a) =>
              a.status == AppointmentStatus.cancelled).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _AppointmentList(
                  appointments: pending,
                  emptyMessage:  'No pending appointments',
                  emptyIcon:     Icons.hourglass_empty),
              _AppointmentList(
                  appointments: accepted,
                  emptyMessage:  'No upcoming appointments',
                  emptyIcon:     Icons.calendar_today_outlined),
              _AppointmentList(
                  appointments: completed,
                  emptyMessage:  'No completed appointments',
                  emptyIcon:     Icons.check_circle_outline),
              _AppointmentList(
                  appointments: cancelled,
                  emptyMessage:  'No cancelled appointments',
                  emptyIcon:     Icons.cancel_outlined),
            ],
          );
        },
      ),
    );
  }
}

// ── Appointment list ──────────────────────────────────────────────────────────
class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String   emptyMessage;
  final IconData emptyIcon;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, size: 52, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(emptyMessage,
              style: const TextStyle(
                  color:      AppTheme.textMedium,
                  fontSize:   15,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return ListView.separated(
      padding:          const EdgeInsets.all(16),
      itemCount:        appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:      (_, i) =>
          _PatientAppointmentCard(appt: appointments[i]),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────
class _PatientAppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  const _PatientAppointmentCard({required this.appt});

  static const Map<AppointmentStatus, Color> _colors = {
    AppointmentStatus.pending:   AppTheme.warning,
    AppointmentStatus.accepted:  AppTheme.primaryTeal,
    AppointmentStatus.completed: AppTheme.success,
    AppointmentStatus.cancelled: AppTheme.error,
  };

  static const Map<AppointmentStatus, IconData> _icons = {
    AppointmentStatus.pending:   Icons.hourglass_top_rounded,
    AppointmentStatus.accepted:  Icons.check_circle_outline,
    AppointmentStatus.completed: Icons.task_alt,
    AppointmentStatus.cancelled: Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[appt.status]!;
    final icon  = _icons[appt.status]!;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 10)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(appt.doctorName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium),
                  const SizedBox(height: 2),
                  Text(appt.specialty,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color:    AppTheme.primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                ]),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 5),
                  Text(appt.status.label,
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      color)),
                ]),
              ),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Details row ──
            Row(children: [
              _DetailPill(
                  icon:  Icons.access_time_outlined,
                  label: appt.timeSlot),
              const SizedBox(width: 10),
              _DetailPill(
                  icon:  Icons.calendar_month_outlined,
                  label: appt.date),
            ]),

            // ── Pending message ──
            if (appt.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 12),
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for doctor to accept your booking.',
                      style: TextStyle(
                          fontSize:   12,
                          color:      Colors.orange.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              // Cancel button for pending
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(
                        color: AppTheme.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon:  const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Booking',
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                  onPressed: () => _cancelBooking(context),
                ),
              ),
            ],

            // ── Accepted message ──
            if (appt.status == AppointmentStatus.accepted) ...[
              const SizedBox(height: 12),
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppTheme.primaryTeal
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryTeal
                          .withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.primaryTeal, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your appointment has been accepted by the doctor!',
                      style: TextStyle(
                          fontSize:   12,
                          color:      AppTheme.primaryTeal,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title:   const Text('Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No',
                style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService().cancelAppointment(appt.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Appointment cancelled'),
          backgroundColor: AppTheme.error,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppTheme.textLight),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      AppTheme.textMedium)),
      ]),
    );
  }
}

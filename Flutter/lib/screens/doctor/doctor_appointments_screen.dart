// lib/screens/doctor/doctor_appointments_screen.dart
// Doctor appointments — pending requests show Accept/Decline buttons.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'patient_detail_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF7B61FF);
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
    final doctorId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Text('Appointments',
            style: TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon:      const Icon(Icons.search, color: Colors.white),
              onPressed: () {})
        ],
        bottom: TabBar(
          controller:           _tabCtrl,
          indicatorColor:       Colors.white,
          indicatorWeight:      3,
          labelColor:           Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF7B61FF)));
          }

          final all = (snap.data?.docs ?? [])
              .map((d) => AppointmentModel.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          all.sort((a, b) {
            final ta = a.createdAt ?? DateTime(2000);
            final tb = b.createdAt ?? DateTime(2000);
            return tb.compareTo(ta);
          });

          final pending   = all.where((a) =>
              a.status == AppointmentStatus.pending).toList();
          final accepted  = all.where((a) =>
              a.status == AppointmentStatus.accepted).toList();
          final completed = all.where((a) =>
              a.status == AppointmentStatus.completed).toList();
          final cancelled = all.where((a) =>
              a.status == AppointmentStatus.cancelled).toList();

          // Summary counts in app bar ribbon
          return Column(children: [
            Container(
              color:   _accent,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                _MiniStat(
                    value: '${pending.length}',
                    label: 'New'),
                _MiniStat(
                    value: '${accepted.length}',
                    label: 'Upcoming'),
                _MiniStat(
                    value: '${completed.length}',
                    label: 'Done'),
                _MiniStat(
                    value: '${all.length}',
                    label: 'Total'),
              ]),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── New/Pending — show Accept/Decline ──
                  _buildList(
                    context: context,
                    appointments: pending,
                    emptyMsg:  'No new appointment requests',
                    emptyIcon: Icons.inbox_outlined,
                    showActions: true,
                  ),
                  _buildList(
                    context: context,
                    appointments: accepted,
                    emptyMsg:  'No upcoming appointments',
                    emptyIcon: Icons.calendar_today_outlined,
                    showActions: false,
                  ),
                  _buildList(
                    context: context,
                    appointments: completed,
                    emptyMsg:  'No completed appointments',
                    emptyIcon: Icons.check_circle_outline,
                    showActions: false,
                  ),
                  _buildList(
                    context: context,
                    appointments: cancelled,
                    emptyMsg:  'No cancelled appointments',
                    emptyIcon: Icons.cancel_outlined,
                    showActions: false,
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildList({
    required BuildContext              context,
    required List<AppointmentModel>    appointments,
    required String                    emptyMsg,
    required IconData                  emptyIcon,
    required bool                      showActions,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 10),
          Text(emptyMsg,
              style: const TextStyle(color: AppTheme.textMedium)),
        ]),
      );
    }
    return ListView.separated(
      padding:          const EdgeInsets.all(16),
      itemCount:        appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _AppointmentCard(
        appt:        appointments[i],
        showActions: showActions,
        onTap: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) =>
                PatientDetailScreen(appointment: appointments[i]))),
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────
class _AppointmentCard extends StatefulWidget {
  final AppointmentModel appt;
  final bool             showActions;
  final VoidCallback     onTap;
  const _AppointmentCard({
    required this.appt,
    required this.showActions,
    required this.onTap,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _processing = false;

  static const Map<AppointmentStatus, Color> _colors = {
    AppointmentStatus.pending:   AppTheme.warning,
    AppointmentStatus.accepted:  Color(0xFF7B61FF),
    AppointmentStatus.completed: AppTheme.success,
    AppointmentStatus.cancelled: AppTheme.error,
  };

  Future<void> _accept() async {
    setState(() => _processing = true);
    await FirestoreService().acceptAppointment(widget.appt.id);
    if (mounted) setState(() => _processing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Appointment accepted ✓'),
        backgroundColor: AppTheme.success,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _decline() async {
    setState(() => _processing = true);
    await FirestoreService().updateAppointmentStatus(
        widget.appt.id, AppointmentStatus.cancelled);
    if (mounted) setState(() => _processing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Appointment declined'),
        backgroundColor: AppTheme.error,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt  = widget.appt;
    final color = _colors[appt.status]!;

    return GestureDetector(
      onTap: widget.onTap,
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
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius:          22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  appt.patientName
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join(),
                  style: TextStyle(
                      color:      color,
                      fontWeight: FontWeight.w800,
                      fontSize:   13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(appt.patientName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${appt.date}  •  ${appt.timeSlot}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(appt.status.label,
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      color)),
              ),
            ]),

            // Symptom preview
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color:        AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(appt.symptoms,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          fontSize: 11, color: AppTheme.textMedium),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),

            // ── Accept / Decline buttons for pending ──
            if (widget.showActions) ...[
              const SizedBox(height: 12),
              _processing
                  ? const Center(
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF7B61FF)),
                      ))
                  : Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                          icon:  const Icon(
                              Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Accept',
                              style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700)),
                          onPressed: _accept,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(
                                color: AppTheme.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                          icon:  const Icon(
                              Icons.cancel_outlined,
                              size: 16),
                          label: const Text('Decline',
                              style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700)),
                          onPressed: _decline,
                        ),
                      ),
                    ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   20,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ]),
      );
}

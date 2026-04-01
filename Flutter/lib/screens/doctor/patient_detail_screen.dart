// lib/screens/doctor/patient_detail_screen.dart
// Patient intake form view – status changes saved to Firestore.

import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PatientDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const PatientDetailScreen({super.key, required this.appointment});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  static const Color _accent = Color(0xFF7B61FF);
  late AppointmentStatus _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.appointment.status;
  }

  Future<void> _updateStatus(AppointmentStatus newStatus) async {
    setState(() => _isSaving = true);
    try {
      await FirestoreService()
          .updateAppointmentStatus(widget.appointment.id, newStatus);
      setState(() { _status = newStatus; _isSaving = false; });
      _showSnack(
        newStatus == AppointmentStatus.completed
            ? 'Appointment marked as completed ✓'
            : 'Appointment cancelled',
        newStatus == AppointmentStatus.completed
            ? AppTheme.success : AppTheme.error,
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Failed to update status. Please try again.', AppTheme.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white,
        title: const Text('Patient Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)))
          : ListView(padding: const EdgeInsets.all(20), children: [
              _PatientHeaderCard(appt: appt, status: _status),
              const SizedBox(height: 20),
              _IntakeSection(icon: Icons.sick_outlined,         color: AppTheme.error,
                  title: 'Chief Complaint / Symptoms',         content: appt.symptoms),
              const SizedBox(height: 14),
              _IntakeSection(icon: Icons.medication_outlined,   color: _accent,
                  title: 'Current Medications',                content: appt.medications),
              const SizedBox(height: 14),
              _IntakeSection(icon: Icons.warning_amber_outlined, color: AppTheme.warning,
                  title: 'Known Allergies',                    content: appt.allergies),
              const SizedBox(height: 14),
              _LifestyleGrid(appt: appt),
              const SizedBox(height: 14),
              _IntakeSection(icon: Icons.history_edu_outlined,  color: AppTheme.primaryTeal,
                  title: 'Medical History',                    content: appt.medicalHistory),
              const SizedBox(height: 28),

              if (_status == AppointmentStatus.upcoming) ...[
                Text('Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Complete'),
                    onPressed: () => _updateStatus(AppointmentStatus.completed),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    onPressed: () => _updateStatus(AppointmentStatus.cancelled),
                  )),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Add Clinical Note'),
                    onPressed: () => _showSnack('Clinical note feature coming soon', _accent),
                  )),
              ],

              if (_status == AppointmentStatus.completed)
                _StatusBanner(color: AppTheme.success, icon: Icons.check_circle,
                    message: 'This appointment has been completed.'),
              if (_status == AppointmentStatus.cancelled)
                _StatusBanner(color: AppTheme.error, icon: Icons.cancel,
                    message: 'This appointment has been cancelled.'),
              const SizedBox(height: 32),
            ]),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color; final IconData icon; final String message;
  const _StatusBanner({required this.color, required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color),
      const SizedBox(width: 10),
      Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _PatientHeaderCard extends StatelessWidget {
  final AppointmentModel appt; final AppointmentStatus status;
  const _PatientHeaderCard({required this.appt, required this.status});
  @override
  Widget build(BuildContext context) {
    final c = status == AppointmentStatus.upcoming ? const Color(0xFF7B61FF)
        : status == AppointmentStatus.completed    ? AppTheme.success
        : AppTheme.error;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.withValues(alpha: 0.12), Colors.white],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(radius: 30, backgroundColor: c.withValues(alpha: 0.15),
              child: Text(appt.patientName.split(' ').map((e) => e[0]).take(2).join(),
                  style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appt.patientName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Age: ${appt.patientAge}  •  ${appt.patientPhone}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
              child: Text(status.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
            ),
          ])),
        ]),
        const Divider(height: 24),
        Row(children: [
          _InfoPill(icon: Icons.access_time,    label: appt.timeSlot),
          const SizedBox(width: 12),
          _InfoPill(icon: Icons.calendar_month, label: appt.date),
          const SizedBox(width: 12),
          _InfoPill(icon: Icons.local_hospital, label: appt.specialty),
        ]),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(color: AppTheme.scaffoldBg, borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.textLight),
      const SizedBox(width: 4),
      Flexible(child: Text(label, style: const TextStyle(fontSize: 10,
          fontWeight: FontWeight.w600, color: AppTheme.textMedium),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  ));
}

class _IntakeSection extends StatelessWidget {
  final IconData icon; final Color color; final String title, content;
  const _IntakeSection({required this.icon, required this.color,
      required this.title, required this.content});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: color, width: 3)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, color: color)),
      ]),
      const SizedBox(height: 8),
      Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
    ]),
  );
}

class _LifestyleGrid extends StatelessWidget {
  final AppointmentModel appt;
  const _LifestyleGrid({required this.appt});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: const Border(left: BorderSide(color: AppTheme.warning, width: 3)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.self_improvement_outlined, color: AppTheme.warning, size: 16),
        SizedBox(width: 8),
        Text('Lifestyle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.warning)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _Pill(label: '${appt.sleepHours.toStringAsFixed(1)} hrs sleep', icon: Icons.bedtime_outlined),
        _Pill(label: appt.smokingStatus,                                icon: Icons.smoking_rooms_outlined),
        _Pill(label: 'Alcohol: ${appt.alcoholConsumption}',             icon: Icons.local_bar_outlined),
      ]),
      const SizedBox(height: 10),
      Text('Diet: ${appt.dietaryHabits}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label; final IconData icon;
  const _Pill({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.textMedium), const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
    ]),
  );
}
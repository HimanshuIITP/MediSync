// lib/screens/intake_form_screen.dart
// Pre-Consultation Intake Form – saves appointment to Firestore.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class IntakeFormScreen extends StatefulWidget {
  final Doctor  doctor;
  final String? selectedSlot;
  const IntakeFormScreen({super.key, required this.doctor, this.selectedSlot});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _symptomsCtrl   = TextEditingController();
  final _medsCtrl       = TextEditingController();
  final _allergiesCtrl  = TextEditingController();
  final _dietaryCtrl    = TextEditingController();
  final _historyCtrl    = TextEditingController();

  double  _sleepHours    = 7;
  double  _activityLevel = 2;
  String? _smokingStatus;
  String? _alcoholConsumption;
  bool    _isSubmitting  = false;
  String? _errorMsg;

  static const List<String> _smokingOptions = ['Never', 'Occasionally', 'Regularly', 'Former smoker'];
  static const List<String> _alcoholOptions = ['Never', 'Occasionally', 'Weekly', 'Daily'];

  @override
  void dispose() {
    _symptomsCtrl.dispose(); _medsCtrl.dispose(); _allergiesCtrl.dispose();
    _dietaryCtrl.dispose();  _historyCtrl.dispose();
    super.dispose();
  }

  String get _activityLabel {
    switch (_activityLevel.toInt()) {
      case 1: return 'Sedentary (desk job)';
      case 3: return 'Active (regular workouts)';
      case 4: return 'Very Active (athlete)';
      default: return 'Moderate (light walks)';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _errorMsg = null; });

    try {
      final user   = AuthService().currentUser!;
      final doctor = widget.doctor;
      final now    = DateTime.now();
      final date   = DateFormat('MMM d, yyyy').format(now);

      final appt = AppointmentModel(
        id:                 '',
        patientId:          user.uid,
        patientName:        user.name,
        patientAge:         user.age ?? 0,
        patientPhone:       user.phone ?? '',
        doctorId:           doctor.id,
        doctorName:         doctor.name,
        specialty:          doctor.specialty,
        timeSlot:           widget.selectedSlot ?? 'Not specified',
        date:               date,
        status:             AppointmentStatus.pending,
        symptoms:           _symptomsCtrl.text.trim(),
        medications:        _medsCtrl.text.trim().isEmpty ? 'None' : _medsCtrl.text.trim(),
        allergies:          _allergiesCtrl.text.trim().isEmpty ? 'None' : _allergiesCtrl.text.trim(),
        sleepHours:         _sleepHours,
        dietaryHabits:      _dietaryCtrl.text.trim().isEmpty ? 'Not specified' : _dietaryCtrl.text.trim(),
        smokingStatus:      _smokingStatus ?? 'Not specified',
        alcoholConsumption: _alcoholConsumption ?? 'Not specified',
        medicalHistory:     _historyCtrl.text.trim().isEmpty ? 'None' : _historyCtrl.text.trim(),
      );

      await FirestoreService().createAppointment(appt);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMsg = 'Failed to book appointment. Please try again.';
      });
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSuccessSheet(
          doctor: widget.doctor, selectedSlot: widget.selectedSlot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Consultation Form'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          _AppointmentBanner(doctor: widget.doctor, selectedSlot: widget.selectedSlot),
          const SizedBox(height: 24),

          const _SectionHeader(icon: Icons.sick_outlined, title: 'Current Symptoms'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _symptomsCtrl, maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe your main symptoms *',
              hintText:  'e.g. Chest pain, shortness of breath for 3 days…',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please describe your symptoms' : null,
          ),
          const SizedBox(height: 20),

          const _SectionHeader(icon: Icons.medication_outlined, title: 'Current Medications'),
          const SizedBox(height: 10),
          TextFormField(controller: _medsCtrl, maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Current medications',
              hintText:  'e.g. Metoprolol 25mg, Aspirin 75mg (or "None")…',
            )),
          const SizedBox(height: 12),
          TextFormField(controller: _allergiesCtrl,
            decoration: const InputDecoration(
              labelText: 'Known drug/food allergies',
              hintText:  'e.g. Penicillin, Peanuts (or "None Known")…',
            )),
          const SizedBox(height: 20),

          const _SectionHeader(icon: Icons.self_improvement_outlined, title: 'Lifestyle'),
          const SizedBox(height: 14),
          _FormLabel('Sleep: ${_sleepHours.toStringAsFixed(1)} hrs/night'),
          Slider(value: _sleepHours, min: 3, max: 12, divisions: 18,
              label: '${_sleepHours.toStringAsFixed(1)} hrs',
              activeColor: AppTheme.primaryTeal,
              onChanged: (v) => setState(() => _sleepHours = v)),
          const SizedBox(height: 10),
          _FormLabel('Activity level: $_activityLabel'),
          Slider(value: _activityLevel, min: 1, max: 4, divisions: 3,
              label: _activityLabel, activeColor: AppTheme.primaryTeal,
              onChanged: (v) => setState(() => _activityLevel = v)),
          const SizedBox(height: 14),
          TextFormField(controller: _dietaryCtrl, maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Describe your dietary habits',
              hintText:  'e.g. Mostly vegetarian, skip breakfast…',
            )),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _smokingStatus,
            decoration: const InputDecoration(labelText: 'Smoking status'),
            hint: const Text('Select'),
            items: _smokingOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _smokingStatus = v),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _alcoholConsumption,
            decoration: const InputDecoration(labelText: 'Alcohol consumption'),
            hint: const Text('Select'),
            items: _alcoholOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _alcoholConsumption = v),
          ),
          const SizedBox(height: 20),

          const _SectionHeader(icon: Icons.history_edu_outlined, title: 'Medical History'),
          const SizedBox(height: 10),
          TextFormField(controller: _historyCtrl, maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Past diagnoses or surgeries',
              hintText:  'e.g. Appendectomy 2018, Hypertension 2020…',
              alignLabelWithHint: true,
            )),
          const SizedBox(height: 16),

          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMsg!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Submit & Confirm Booking'),
            ),
          ),
          const SizedBox(height: 8),
          Text('🔒  Your health information is encrypted and only shared with your doctor.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.textLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _AppointmentBanner extends StatelessWidget {
  final Doctor  doctor;
  final String? selectedSlot;
  const _AppointmentBanner({required this.doctor, this.selectedSlot});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primaryTeal.withValues(alpha: 0.12), AppTheme.accentMint],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: AppTheme.success, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Appointment Pending',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryDark)),
          const SizedBox(height: 2),
          Text('${doctor.name} • ${doctor.specialty}',
              style: Theme.of(context).textTheme.bodyMedium),
          Text(doctor.hospital,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.textLight)),
          if (selectedSlot != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 12, color: AppTheme.primaryTeal),
              const SizedBox(width: 4),
              Text(selectedSlot!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
            ]),
          ],
        ])),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String   title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.accentMint, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primaryTeal, size: 20)),
      const SizedBox(width: 10),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
    ]);
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
  );
}

class _BookingSuccessSheet extends StatelessWidget {
  final Doctor  doctor;
  final String? selectedSlot;
  const _BookingSuccessSheet({required this.doctor, this.selectedSlot});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50)),
        const SizedBox(height: 20),
        Text('Appointment Confirmed!',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Your appointment with ${doctor.name}'
          '${selectedSlot != null ? ' at $selectedSlot' : ''} '
          'has been booked.\nYour intake form has been sent to the doctor.',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          )),
        const SizedBox(height: 12),
      ]),
    );
  }
}

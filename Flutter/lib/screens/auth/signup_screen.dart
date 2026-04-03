// lib/screens/auth/signup_screen.dart
// Doctor registration now includes time slot picker (30-min intervals).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../models/doctor.dart';
import '../../models/cities.dart';
import '../../theme/app_theme.dart';
import '../../main.dart' show MainNavigation;
import '../doctor/doctor_main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  final UserRole role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _ageCtrl        = TextEditingController();
  final _hospitalCtrl   = TextEditingController();
  final _regNoCtrl      = TextEditingController();
  final _qualCtrl       = TextEditingController();
  final _feeCtrl        = TextEditingController();
  final _experienceCtrl = TextEditingController();

  bool    _obscurePass       = true;
  bool    _isLoading         = false;
  String? _errorMsg;
  String? _selectedSpecialty;
  String? _selectedCity;
  // Selected time slots for doctor
  final List<String> _selectedSlots = [];

  bool  get _isDoctor    => widget.role == UserRole.doctor;
  Color get _accentColor =>
      _isDoctor ? const Color(0xFF7B61FF) : AppTheme.primaryTeal;

  // All 30-min slots from 6 AM to 10 PM
  static final List<String> _allSlots = _generateSlots();

  static List<String> _generateSlots() {
    final slots = <String>[];
    for (int h = 6; h < 22; h++) {
      final hour   = h > 12 ? h - 12 : h;
      final amPm   = h >= 12 ? 'PM' : 'AM';
      final hourStr = hour == 0 ? '12' : hour.toString();
      slots.add('$hourStr:00 $amPm');
      slots.add('$hourStr:30 $amPm');
    }
    return slots;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();      _emailCtrl.dispose();
    _passwordCtrl.dispose();  _phoneCtrl.dispose();
    _ageCtrl.dispose();       _hospitalCtrl.dispose();
    _regNoCtrl.dispose();     _qualCtrl.dispose();
    _feeCtrl.dispose();       _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDoctor && _selectedSlots.isEmpty) {
      setState(() => _errorMsg = 'Please select at least one time slot');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final error = await AuthService().signUp(
        name:               _nameCtrl.text,
        email:              _emailCtrl.text,
        password:           _passwordCtrl.text,
        role:               widget.role,
        specialty:          _isDoctor ? _selectedSpecialty : null,
        hospital:           _isDoctor ? _hospitalCtrl.text : null,
        registrationNumber: _isDoctor ? _regNoCtrl.text    : null,
        qualification:      _isDoctor ? _qualCtrl.text     : null,
        fee:                _isDoctor && _feeCtrl.text.isNotEmpty
                                ? int.tryParse(_feeCtrl.text) : null,
        experience:         _isDoctor ? _experienceCtrl.text : null,
        city:               _selectedCity,
        age: !_isDoctor && _ageCtrl.text.isNotEmpty
                ? int.tryParse(_ageCtrl.text) : null,
        phone: !_isDoctor ? _phoneCtrl.text : null,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() { _isLoading = false; _errorMsg = error; });
        return;
      }

      // Update doctor's available slots in Firestore
      if (_isDoctor) {
        final uid = AuthService().currentUser?.uid;
        if (uid != null) {
          // Sort slots chronologically before saving
          final sorted = List<String>.from(_selectedSlots);
          sorted.sort((a, b) =>
              _allSlots.indexOf(a).compareTo(_allSlots.indexOf(b)));
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(uid)
              .update({'availableSlots': sorted});
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;
      if (_isDoctor) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(
                builder: (_) => const DoctorMainNavigation()),
            (_) => false);
      } else {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg  = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  void _showCityPicker() {
    String query = '';
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final filtered = kIndianCities
              .where((c) =>
                  c.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color:        AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus:  true,
                  decoration: InputDecoration(
                    hintText:   'Search city…',
                    prefixIcon: Icon(Icons.search,
                        color: _accentColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled:    true,
                    fillColor: AppTheme.scaffoldBg,
                  ),
                  onChanged: (v) => setSheet(() => query = v),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final city     = filtered[i];
                    final selected = _selectedCity == city;
                    return ListTile(
                      leading: Icon(Icons.location_city,
                          color: selected
                              ? _accentColor
                              : AppTheme.textLight,
                          size: 20),
                      title: Text(city,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? _accentColor
                                : AppTheme.textDark,
                          )),
                      trailing: selected
                          ? Icon(Icons.check_circle,
                              color: _accentColor, size: 18)
                          : null,
                      onTap: () {
                        setState(() => _selectedCity = city);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
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
        title: Text(
          _isDoctor ? 'Doctor Registration' : 'Patient Registration',
          style: const TextStyle(
              color:      AppTheme.textDark,
              fontSize:   17,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:        _accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.assignment_outlined,
                        color: _accentColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _isDoctor
                          ? 'Complete your professional profile'
                          : 'Fill in your details to get started',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      _accentColor),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                _SectionLabel('Personal Information', _accentColor),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller:         _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText:  _isDoctor
                        ? 'Full name (with title, e.g. Dr.)'
                        : 'Full name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: _accentColor),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText:  'Email address',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: _accentColor),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller:  _passwordCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText:  'Password (min 6 characters)',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: _accentColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6)
                          ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // City picker
                GestureDetector(
                  onTap: _showCityPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCity != null
                            ? _accentColor
                            : AppTheme.divider,
                        width: _selectedCity != null ? 1.8 : 1.2,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_outlined,
                          color: _selectedCity != null
                              ? _accentColor
                              : AppTheme.textLight,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCity ?? 'Select your city *',
                          style: TextStyle(
                            fontSize:   14,
                            color:      _selectedCity != null
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                            fontWeight: _selectedCity != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: AppTheme.textLight),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Patient-specific ──────────────────────────────────
                if (!_isDoctor) ...[
                  _SectionLabel('Health Profile', _accentColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller:      _ageCtrl,
                        keyboardType:    TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText:  'Age',
                          prefixIcon: Icon(Icons.cake_outlined,
                              color: _accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller:   _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText:  'Phone',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: _accentColor),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],

                // ── Doctor-specific ───────────────────────────────────
                if (_isDoctor) ...[
                  _SectionLabel('Professional Details', _accentColor),
                  const SizedBox(height: 12),

                  // Specialty
                  DropdownButtonFormField<String>(
                    value:      _selectedSpecialty,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:  'Medical Specialty',
                      prefixIcon: Icon(Icons.local_hospital_outlined,
                          color: _accentColor),
                    ),
                    hint:  const Text('Select specialty'),
                    items: kSpecialties
                        .map((s) => DropdownMenuItem(
                              value: s['name'] as String,
                              child: Row(children: [
                                Text(s['icon'] as String,
                                    style: const TextStyle(
                                        fontSize: 18)),
                                const SizedBox(width: 10),
                                Text(s['name'] as String),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSpecialty = v),
                    validator: (v) =>
                        v == null
                            ? 'Please select a specialty'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // Qualification
                  TextFormField(
                    controller: _qualCtrl,
                    decoration: InputDecoration(
                      labelText:  'Qualification (e.g. MBBS, MD)',
                      prefixIcon: Icon(Icons.school_outlined,
                          color: _accentColor),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Qualification required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Hospital
                  TextFormField(
                    controller: _hospitalCtrl,
                    decoration: InputDecoration(
                      labelText:  'Hospital / Clinic name',
                      prefixIcon: Icon(Icons.business_outlined,
                          color: _accentColor),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Hospital name required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Fee + Experience
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller:      _feeCtrl,
                        keyboardType:    TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText:  'Consultation Fee (₹)',
                          prefixIcon: Icon(Icons.currency_rupee,
                              color: _accentColor),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Fee required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _experienceCtrl,
                        decoration: InputDecoration(
                          labelText:  'Experience (e.g. 5 years)',
                          prefixIcon: Icon(
                              Icons.work_history_outlined,
                              color: _accentColor),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Experience required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Registration Number
                  TextFormField(
                    controller: _regNoCtrl,
                    decoration: InputDecoration(
                      labelText:  'Medical Registration Number',
                      prefixIcon: Icon(Icons.badge_outlined,
                          color: _accentColor),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Registration number required' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Time Slot Picker ──────────────────────────────
                  _SectionLabel('Available Time Slots', _accentColor),
                  const SizedBox(height: 6),
                  Text(
                    'Select your consultation hours. Each slot is 30 minutes.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 12),

                  // Selected count chip
                  if (_selectedSlots.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:        _accentColor
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedSlots.length} slot${_selectedSlots.length > 1 ? 's' : ''} selected',
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      _accentColor),
                      ),
                    ),

                  // Morning slots
                  _SlotGroup(
                    label:         'Morning  (6 AM – 12 PM)',
                    slots:         _allSlots
                        .where((s) =>
                            s.contains('AM') &&
                            !s.startsWith('12'))
                        .toList(),
                    selectedSlots: _selectedSlots,
                    accentColor:   _accentColor,
                    onToggle: (slot) => setState(() {
                      _selectedSlots.contains(slot)
                          ? _selectedSlots.remove(slot)
                          : _selectedSlots.add(slot);
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Afternoon slots
                  _SlotGroup(
                    label:         'Afternoon  (12 PM – 5 PM)',
                    slots:         _allSlots
                        .where((s) =>
                            s.contains('PM') &&
                            (s.startsWith('12') ||
                             s.startsWith('1:') ||
                             s.startsWith('2:') ||
                             s.startsWith('3:') ||
                             s.startsWith('4:')))
                        .toList(),
                    selectedSlots: _selectedSlots,
                    accentColor:   _accentColor,
                    onToggle: (slot) => setState(() {
                      _selectedSlots.contains(slot)
                          ? _selectedSlots.remove(slot)
                          : _selectedSlots.add(slot);
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Evening slots
                  _SlotGroup(
                    label:         'Evening  (5 PM – 10 PM)',
                    slots:         _allSlots
                        .where((s) =>
                            s.contains('PM') &&
                            (s.startsWith('5:') ||
                             s.startsWith('6:') ||
                             s.startsWith('7:') ||
                             s.startsWith('8:') ||
                             s.startsWith('9:')))
                        .toList(),
                    selectedSlots: _selectedSlots,
                    accentColor:   _accentColor,
                    onToggle: (slot) => setState(() {
                      _selectedSlots.contains(slot)
                          ? _selectedSlots.remove(slot)
                          : _selectedSlots.add(slot);
                    }),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:        AppTheme.error
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.error
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(
                                  color:    AppTheme.error,
                                  fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit
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
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white))
                        : Text(
                            _isDoctor
                                ? 'Register as Doctor'
                                : 'Create Patient Account',
                            style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'By signing up, you agree to our Terms of Service and Privacy Policy.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Slot group widget ─────────────────────────────────────────────────────────
class _SlotGroup extends StatelessWidget {
  final String       label;
  final List<String> slots;
  final List<String> selectedSlots;
  final Color        accentColor;
  final void Function(String) onToggle;

  const _SlotGroup({
    required this.label,
    required this.slots,
    required this.selectedSlots,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      accentColor)),
      const SizedBox(height: 8),
      Wrap(
        spacing:    8,
        runSpacing: 8,
        children:   slots.map((slot) {
          final selected = selectedSlots.contains(slot);
          return GestureDetector(
            onTap: () => onToggle(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        selected
                    ? accentColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? accentColor : AppTheme.divider,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(
                        color:      accentColor.withValues(alpha: 0.25),
                        blurRadius: 6)]
                    : [],
              ),
              child: Text(slot,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      selected
                          ? Colors.white
                          : AppTheme.textMedium)),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color  color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width:  3, height: 18,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color)),
    ]);
  }
}

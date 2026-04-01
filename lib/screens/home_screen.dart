// lib/screens/home_screen.dart
// Booking screen — working search bar + city filter + live Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import '../models/cities.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'intake_form_screen.dart';
import 'auth/role_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String  _selectedSpecialty = 'General Physician';
  String? _selectedCity;           // null = all cities
  String  _searchQuery       = '';
  final   _searchCtrl        = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    final user = AuthService().currentUser;
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _PatientProfileSheet(user: user),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title:   const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen()),
                (_) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ── City picker sheet ──────────────────────────────────────────────────────
  void _showCityPicker() {
    String query = '';
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final filtered = [
            'All Cities',
            ...kIndianCities.where((c) =>
                c.toLowerCase().contains(query.toLowerCase())),
          ];
          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Filter by City',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus:  true,
                  decoration: InputDecoration(
                    hintText:   'Search city…',
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.primaryTeal),
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
                    final isAll    = city == 'All Cities';
                    final selected = isAll
                        ? _selectedCity == null
                        : _selectedCity == city;
                    return ListTile(
                      leading: Icon(
                        isAll
                            ? Icons.public
                            : Icons.location_city,
                        color: selected
                            ? AppTheme.primaryTeal
                            : AppTheme.textLight,
                        size: 20,
                      ),
                      title: Text(city,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppTheme.primaryTeal
                                : AppTheme.textDark,
                          )),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.primaryTeal, size: 18)
                          : null,
                      onTap: () {
                        setState(() =>
                            _selectedCity = isAll ? null : city);
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

  // ── Filter doctors client-side ─────────────────────────────────────────────
  List<Doctor> _applyFilters(List<Doctor> doctors) {
    var result = doctors;

    // City filter
    if (_selectedCity != null) {
      result = result
          .where((d) =>
              d.city.toLowerCase() ==
              _selectedCity!.toLowerCase())
          .toList();
    }

    // Search filter — matches name, hospital, specialty, city
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.hospital.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.city.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user  = AuthService().currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            expandedHeight:  180,
            floating:        false,
            pinned:          true,
            backgroundColor: AppTheme.primaryTeal,
            actions: [
              // City filter button
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 24),
                    if (_selectedCity != null)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: AppTheme.warning,
                              shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                tooltip:   'Filter by city',
                onPressed: _showCityPicker,
              ),
              // Profile avatar
              GestureDetector(
                onTap: () => _showProfileSheet(context),
                child: Container(
                  margin:  const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:  Colors.white.withValues(alpha: 0.20),
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: Colors.white54, width: 1.5),
                  ),
                  child: Text(
                    (user?.name ?? 'P')
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              // Logout
              IconButton(
                icon:    const Icon(Icons.logout,
                    color: Colors.white70, size: 22),
                tooltip: 'Sign out',
                onPressed: () => _logout(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _HeaderWidget(userName: user?.name ?? 'there'),
            ),
            title: const Text('MediSync',
                style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w800)),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search bar (now working) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged:  (v) =>
                        setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText:   'Search doctors, hospitals, specialties…',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textLight),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppTheme.textLight,
                                  size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:   BorderSide.none,
                      ),
                      fillColor: Colors.white,
                      filled:    true,
                    ),
                  ),
                ),

                // ── City filter chip (shown when city is selected) ──
                if (_selectedCity != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:        AppTheme.primaryTeal
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.primaryTeal
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Icons.location_on,
                              size: 14,
                              color: AppTheme.primaryTeal),
                          const SizedBox(width: 4),
                          Text(_selectedCity!,
                              style: const TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppTheme.primaryTeal)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(
                                () => _selectedCity = null),
                            child: const Icon(Icons.close,
                                size: 14,
                                color: AppTheme.primaryTeal),
                          ),
                        ]),
                      ),
                    ]),
                  ),

                // ── Specialty picker ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Select Specialty',
                      style: theme.textTheme.titleLarge),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection:  Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount:        kSpecialties.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final sp         = kSpecialties[i];
                      final isSelected =
                          _selectedSpecialty == sp['name'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedSpecialty =
                              sp['name'] as String;
                        }),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryTeal
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : AppTheme.divider,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme
                                          .primaryTeal
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(sp['icon'] as String,
                                  style: const TextStyle(
                                      fontSize: 26)),
                              const SizedBox(height: 6),
                              Text(
                                sp['name'] as String,
                                style: TextStyle(
                                  fontSize:   10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMedium,
                                ),
                                textAlign: TextAlign.center,
                                maxLines:  2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Doctors from Firestore ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('specialty',
                    isEqualTo: _selectedSpecialty)
                .where('isAvailable', isEqualTo: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState ==
                      ConnectionState.waiting &&
                  !snap.hasData) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryTeal),
                    ),
                  ),
                );
              }

              final allDocs = (snap.data?.docs ?? [])
                  .map((d) => Doctor.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>))
                  .toList();

              // Apply search + city filters in Dart
              final doctors = _applyFilters(allDocs);

              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Doctors',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge),
                      Text(
                        '${doctors.length} found'
                        '${_selectedCity != null ? ' in $_selectedCity' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('specialty',
                    isEqualTo: _selectedSpecialty)
                .where('isAvailable', isEqualTo: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SliverToBoxAdapter(
                    child: SizedBox());
              }

              final allDocs = snap.data!.docs
                  .map((d) => Doctor.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>))
                  .toList();

              final doctors = _applyFilters(allDocs);

              if (doctors.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        const Icon(Icons.search_off,
                            size: 48,
                            color: AppTheme.textLight),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No doctors found for "$_searchQuery"'
                              : _selectedCity != null
                                  ? 'No doctors in $_selectedCity for this specialty'
                                  : 'No doctors available for this specialty.',
                          style: const TextStyle(
                              color: AppTheme.textMedium),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedCity != null ||
                            _searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedCity  = null;
                              _searchQuery   = '';
                              _searchCtrl.clear();
                            }),
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ]),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _DoctorCard(
                      doctor: doctors[i],
                      onBook: (slot) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IntakeFormScreen(
                              doctor:       doctors[i],
                              selectedSlot: slot),
                        ),
                      ),
                    ),
                    childCount: doctors.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HeaderWidget extends StatelessWidget {
  final String userName;
  const _HeaderWidget({required this.userName});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryTeal,
            AppTheme.primaryLight
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('$_greeting, $firstName! 👋',
                style: const TextStyle(
                    color:      Colors.white70,
                    fontSize:   14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Find Your Doctor',
                style: TextStyle(
                    color:      Colors.white,
                    fontSize:   24,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

// ── Patient Profile Sheet ─────────────────────────────────────────────────────
class _PatientProfileSheet extends StatelessWidget {
  final UserModel? user;
  const _PatientProfileSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left:   24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color:        AppTheme.divider,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.primaryTeal, AppTheme.primaryLight],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight),
            shape:     BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color:      AppTheme.primaryTeal
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset:     const Offset(0, 6))
            ],
          ),
          child: Center(
            child: Text(
              (user?.name ?? 'P')
                  .split(' ')
                  .map((e) => e[0])
                  .take(2)
                  .join(),
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   28,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(user?.name ?? 'Patient',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
              color:        AppTheme.accentMint,
              borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_user_outlined,
                size: 14, color: AppTheme.primaryTeal),
            SizedBox(width: 5),
            Text('Patient',
                style: TextStyle(
                    color:      AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize:   13)),
          ]),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _InfoRow(icon: Icons.email_outlined,
            label: 'Email', value: user?.email ?? '—'),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.cake_outlined,
            label: 'Age',
            value: user?.age != null ? '${user!.age} years' : '—'),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.phone_outlined,
            label: 'Phone', value: user?.phone ?? '—'),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.location_on_outlined,
            label: 'City',  value: user?.city  ?? '—'),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side:    const BorderSide(color: AppTheme.error, width: 1.5),
              shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon:  const Icon(Icons.logout),
            label: const Text('Sign Out',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            onPressed: () {
              Navigator.pop(context);
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
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color:        AppTheme.accentMint,
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primaryTeal, size: 18),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize:   11,
                color:      AppTheme.textLight,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize:   14,
                color:      AppTheme.textDark,
                fontWeight: FontWeight.w700)),
      ]),
    ]);
  }
}

// ── Doctor Card ───────────────────────────────────────────────────────────────
class _DoctorCard extends StatefulWidget {
  final Doctor doctor;
  final void Function(String? slot) onBook;
  const _DoctorCard({required this.doctor, required this.onBook});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> {
  String? _selectedSlot;

  static const List<Color> _avatarColors = [
    AppTheme.primaryTeal, Color(0xFF7B61FF), Color(0xFFEF5350),
    Color(0xFF26A69A),    Color(0xFF5C6BC0), Color(0xFFFF7043),
  ];

  @override
  Widget build(BuildContext context) {
    final d    = widget.doctor;
    final bg   = _avatarColors[d.avatarColorIndex % _avatarColors.length];
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:  bg.withValues(alpha: 0.15),
                shape:  BoxShape.circle,
                border: Border.all(color: bg, width: 2),
              ),
              child: Center(
                child: Text(d.avatarInitials,
                    style: TextStyle(
                        color:      bg,
                        fontSize:   22,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(d.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(d.qualification,
                    style:    theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.local_hospital_outlined,
                      size: 13, color: AppTheme.primaryTeal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(d.hospital,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                                color:    AppTheme.primaryTeal,
                                fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                // City badge
                if (d.city.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Text(d.city,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 11,
                                color: AppTheme.textLight)),
                  ]),
                ],
              ]),
            ),

            // Fee
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        AppTheme.accentMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('₹${d.fee}',
                  style: const TextStyle(
                      color:      AppTheme.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize:   15)),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          Row(children: [
            RatingBarIndicator(
              rating:      d.rating,
              itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded, color: AppTheme.warning),
              itemCount: 5,
              itemSize:  16,
            ),
            const SizedBox(width: 6),
            Text('${d.rating} (${d.reviewCount} reviews)',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 12)),
            const Spacer(),
            const Icon(Icons.work_history_outlined,
                size: 13, color: AppTheme.textLight),
            const SizedBox(width: 4),
            Text(d.experience,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 12)),
          ]),

          const SizedBox(height: 14),
          Text('Available Slots',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: d.availableSlots.map((slot) {
              final sel = _selectedSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:        sel
                        ? AppTheme.primaryTeal
                        : AppTheme.accentMint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel
                            ? AppTheme.primaryTeal
                            : AppTheme.divider),
                  ),
                  child: Text(slot,
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      sel
                              ? Colors.white
                              : AppTheme.primaryDark)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onBook(_selectedSlot),
              icon:  const Icon(Icons.calendar_today, size: 18),
              label: const Text('Book Appointment'),
            ),
          ),
        ]),
      ),
    );
  }
}
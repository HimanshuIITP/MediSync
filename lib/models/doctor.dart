// lib/models/doctor.dart
// Doctor model — now includes city field for location-based search.

class Doctor {
  final String       id;
  final String       name;
  final String       specialty;
  final String       qualification;
  final String       hospital;
  final String       city;          // NEW
  final double       rating;
  final int          reviewCount;
  final int          fee;
  final String       experience;
  final List<String> availableSlots;
  final String       avatarInitials;
  final int          avatarColorIndex;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.hospital,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.fee,
    required this.experience,
    required this.availableSlots,
    required this.avatarInitials,
    required this.avatarColorIndex,
  });

  factory Doctor.fromMap(String id, Map<String, dynamic> m) => Doctor(
        id:               id,
        name:             m['name']            as String? ?? '',
        specialty:        m['specialty']       as String? ?? '',
        qualification:    m['qualification']   as String? ?? '',
        hospital:         m['hospital']        as String? ?? '',
        city:             m['city']            as String? ?? '',  // NEW
        rating:           (m['rating']         as num?)?.toDouble() ?? 0.0,
        reviewCount:      m['reviewCount']     as int?    ?? 0,
        fee:              m['fee']             as int?    ?? 0,
        experience:       m['experience']      as String? ?? '',
        availableSlots:   List<String>.from(m['availableSlots'] ?? []),
        avatarInitials:   m['avatarInitials']  as String? ?? '??',
        avatarColorIndex: m['avatarColorIndex'] as int?   ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name':             name,
        'specialty':        specialty,
        'qualification':    qualification,
        'hospital':         hospital,
        'city':             city,
        'rating':           rating,
        'reviewCount':      reviewCount,
        'fee':              fee,
        'experience':       experience,
        'availableSlots':   availableSlots,
        'avatarInitials':   avatarInitials,
        'avatarColorIndex': avatarColorIndex,
      };

  static List<Doctor> filterBySpecialty(
          List<Doctor> doctors, String specialty) =>
      doctors.where((d) => d.specialty == specialty).toList();
}

// ── Complete specialty list ───────────────────────────────────────────────────
const List<Map<String, dynamic>> kSpecialties = [
  // Common
  {'name': 'General Physician',     'icon': '🩺'},
  {'name': 'Cardiologist',          'icon': '❤️'},
  {'name': 'Dermatologist',         'icon': '🧴'},
  {'name': 'Gynaecologist',         'icon': '🌸'},
  {'name': 'Paediatrician',         'icon': '👶'},
  {'name': 'Orthopedist',           'icon': '🦴'},
  {'name': 'Neurologist',           'icon': '⚡'},
  {'name': 'Psychiatrist',          'icon': '🧠'},
  // Surgical
  {'name': 'General Surgeon',       'icon': '🔪'},
  {'name': 'Ophthalmologist',       'icon': '👁️'},
  {'name': 'ENT Specialist',        'icon': '👂'},
  {'name': 'Urologist',             'icon': '🫘'},
  {'name': 'Gastroenterologist',    'icon': '🫁'},
  // Diagnostic
  {'name': 'Radiologist',           'icon': '🔬'},
  {'name': 'Pathologist',           'icon': '🧪'},
  // Specialty
  {'name': 'Endocrinologist',       'icon': '⚗️'},
  {'name': 'Pulmonologist',         'icon': '🌬️'},
  {'name': 'Nephrologist',          'icon': '💧'},
  {'name': 'Rheumatologist',        'icon': '🦵'},
  {'name': 'Oncologist',            'icon': '🎗️'},
  {'name': 'Haematologist',         'icon': '🩸'},
  {'name': 'Dentist',               'icon': '🦷'},
  {'name': 'Physiotherapist',       'icon': '🤸'},
  {'name': 'Dietitian',             'icon': '🥗'},
];
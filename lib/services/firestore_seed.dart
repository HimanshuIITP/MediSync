// lib/services/firestore_seed.dart
// Run this ONCE to seed doctor data into Firestore.
// Call FirestoreSeed.seedDoctors() from a debug button or initState once.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeed {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedDoctors() async {
    final batch = _db.batch();

    final doctors = [
      {
        'uid': 'd1', 'name': 'Dr. Aisha Mehta',
        'specialty': 'Cardiologist', 'qualification': 'MBBS, MD (Cardiology)',
        'hospital': 'Apollo Heart Institute', 'rating': 4.9, 'reviewCount': 312,
        'fee': 1200, 'experience': '16 years',
        'availableSlots': ['10:00 AM', '11:30 AM', '03:00 PM', '05:30 PM'],
        'avatarInitials': 'AM', 'avatarColorIndex': 0, 'isAvailable': true,
      },
      {
        'uid': 'd2', 'name': 'Dr. Rohan Kapoor',
        'specialty': 'Cardiologist', 'qualification': 'MBBS, DM (Cardiology)',
        'hospital': 'Fortis Cardiac Center', 'rating': 4.7, 'reviewCount': 197,
        'fee': 1000, 'experience': '11 years',
        'availableSlots': ['09:00 AM', '01:00 PM', '04:00 PM'],
        'avatarInitials': 'RK', 'avatarColorIndex': 1, 'isAvailable': true,
      },
      {
        'uid': 'd3', 'name': 'Dr. Priya Sharma',
        'specialty': 'Orthopedist', 'qualification': 'MBBS, MS (Orthopaedics)',
        'hospital': 'Max Bone & Joint Clinic', 'rating': 4.8, 'reviewCount': 254,
        'fee': 900, 'experience': '14 years',
        'availableSlots': ['08:30 AM', '10:00 AM', '12:30 PM', '06:00 PM'],
        'avatarInitials': 'PS', 'avatarColorIndex': 2, 'isAvailable': true,
      },
      {
        'uid': 'd4', 'name': 'Dr. Vikram Nair',
        'specialty': 'Orthopedist',
        'qualification': 'MBBS, DNB (Ortho), Fellowship (Sports Medicine)',
        'hospital': 'AIIMS Sports Medicine Dept.', 'rating': 4.6, 'reviewCount': 128,
        'fee': 1100, 'experience': '9 years',
        'availableSlots': ['11:00 AM', '02:00 PM', '04:30 PM'],
        'avatarInitials': 'VN', 'avatarColorIndex': 3, 'isAvailable': true,
      },
      {
        'uid': 'd5', 'name': 'Dr. Kavitha Iyer',
        'specialty': 'Psychiatrist', 'qualification': 'MBBS, MD (Psychiatry)',
        'hospital': 'NIMHANS Outpatient Clinic', 'rating': 4.9, 'reviewCount': 401,
        'fee': 1500, 'experience': '18 years',
        'availableSlots': ['09:30 AM', '11:00 AM', '02:30 PM'],
        'avatarInitials': 'KI', 'avatarColorIndex': 4, 'isAvailable': true,
      },
      {
        'uid': 'd6', 'name': 'Dr. Arjun Das',
        'specialty': 'Psychiatrist', 'qualification': 'MBBS, MD, DPM',
        'hospital': 'Vandrevala Foundation', 'rating': 4.5, 'reviewCount': 89,
        'fee': 1200, 'experience': '7 years',
        'availableSlots': ['10:30 AM', '01:00 PM', '05:00 PM', '07:00 PM'],
        'avatarInitials': 'AD', 'avatarColorIndex': 5, 'isAvailable': true,
      },
      {
        'uid': 'd7', 'name': 'Dr. Sneha Patel',
        'specialty': 'Dermatologist', 'qualification': 'MBBS, MD (Dermatology)',
        'hospital': 'Skin & Cosmetology Centre', 'rating': 4.8, 'reviewCount': 330,
        'fee': 800, 'experience': '12 years',
        'availableSlots': ['08:00 AM', '09:30 AM', '12:00 PM', '04:00 PM'],
        'avatarInitials': 'SP', 'avatarColorIndex': 0, 'isAvailable': true,
      },
      {
        'uid': 'd8', 'name': 'Dr. Amit Bose',
        'specialty': 'Neurologist', 'qualification': 'MBBS, DM (Neurology)',
        'hospital': 'Institute of Neurosciences', 'rating': 4.7, 'reviewCount': 176,
        'fee': 1400, 'experience': '15 years',
        'availableSlots': ['10:00 AM', '01:30 PM', '03:30 PM'],
        'avatarInitials': 'AB', 'avatarColorIndex': 2, 'isAvailable': true,
      },
      {
        'uid': 'd9', 'name': 'Dr. Meena Joshi',
        'specialty': 'General Physician',
        'qualification': 'MBBS, MD (General Medicine)',
        'hospital': 'City Health Clinic', 'rating': 4.6, 'reviewCount': 512,
        'fee': 500, 'experience': '20 years',
        'availableSlots': ['08:00 AM', '09:00 AM', '11:00 AM', '02:00 PM', '05:00 PM'],
        'avatarInitials': 'MJ', 'avatarColorIndex': 1, 'isAvailable': true,
      },
    ];

    for (final doc in doctors) {
      final uid = doc['uid'] as String;
      final ref = _db.collection('doctors').doc(uid);
      batch.set(ref, doc);
    }

    await batch.commit();
    // ignore: avoid_print
    print('✅ Firestore seeded with ${doctors.length} doctors.');
  }
}
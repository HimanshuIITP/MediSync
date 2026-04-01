// lib/services/firestore_service.dart
// FIX: Removed orderBy('createdAt') from all streams.
// Combining where() + orderBy() on different fields requires a Firestore
// composite index. Without the index data briefly appears then vanishes.
// All sorting is now done in Dart after fetching.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Doctors ───────────────────────────────────────────────────────────────

  Stream<List<Doctor>> doctorsStream() => _db
      .collection('doctors')
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Doctor.fromMap(d.id, d.data()))
          .toList());

  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    final snap = await _db
        .collection('doctors')
        .where('specialty',    isEqualTo: specialty)
        .where('isAvailable', isEqualTo: true)
        .get();
    return snap.docs.map((d) => Doctor.fromMap(d.id, d.data())).toList();
  }

  Future<Doctor?> getDoctor(String uid) async {
    final doc = await _db.collection('doctors').doc(uid).get();
    if (!doc.exists) return null;
    return Doctor.fromMap(doc.id, doc.data()!);
  }

  // ── Appointments ──────────────────────────────────────────────────────────

  Future<String> createAppointment(AppointmentModel appt) async {
    final ref = await _db.collection('appointments').add(appt.toMap());
    return ref.id;
  }

  /// Stream appointments for a patient — sorted in Dart, no composite index needed.
  Stream<List<AppointmentModel>> patientAppointmentsStream(
      String patientId) =>
      _db
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs
                .map((d) => AppointmentModel.fromMap(d.id, d.data()))
                .toList();
            // Sort newest first in Dart
            list.sort((a, b) {
              final ta = a.createdAt ?? DateTime(2000);
              final tb = b.createdAt ?? DateTime(2000);
              return tb.compareTo(ta);
            });
            return list;
          });

  /// Stream appointments for a doctor — sorted in Dart, no composite index needed.
  Stream<List<AppointmentModel>> doctorAppointmentsStream(
      String doctorId) =>
      _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots()
          .map((snap) {
            final list = snap.docs
                .map((d) => AppointmentModel.fromMap(d.id, d.data()))
                .toList();
            // Sort newest first in Dart
            list.sort((a, b) {
              final ta = a.createdAt ?? DateTime(2000);
              final tb = b.createdAt ?? DateTime(2000);
              return tb.compareTo(ta);
            });
            return list;
          });

  /// Update appointment status.
  Future<void> updateAppointmentStatus(
      String apptId, AppointmentStatus status) async {
    await _db
        .collection('appointments')
        .doc(apptId)
        .update({'status': status.label.toLowerCase()});
  }

  // ── Doctor profile ────────────────────────────────────────────────────────

  Future<void> setDoctorAvailability(String uid, bool isAvailable) async {
    await _db
        .collection('doctors')
        .doc(uid)
        .update({'isAvailable': isAvailable});
  }

  Future<void> updateDoctorSlots(String uid, List<String> slots) async {
    await _db
        .collection('doctors')
        .doc(uid)
        .update({'availableSlots': slots});
  }
}
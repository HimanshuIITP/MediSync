// lib/services/firestore_service.dart
// All Firestore reads/writes — updated for pending/accepted flow.

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

  Future<Doctor?> getDoctor(String uid) async {
    final doc = await _db.collection('doctors').doc(uid).get();
    if (!doc.exists) return null;
    return Doctor.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateDoctorSlots(String uid, List<String> slots) async {
    await _db.collection('doctors').doc(uid)
        .update({'availableSlots': slots});
  }

  Future<void> setDoctorAvailability(String uid, bool isAvailable) async {
    await _db.collection('doctors').doc(uid)
        .update({'isAvailable': isAvailable});
  }

  // ── Appointments ──────────────────────────────────────────────────────────

  /// Create appointment — starts as PENDING.
  Future<String> createAppointment(AppointmentModel appt) async {
    final ref = await _db.collection('appointments').add(appt.toMap());
    return ref.id;
  }

  /// Stream all appointments for a PATIENT (real-time).
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
            list.sort((a, b) {
              final ta = a.createdAt ?? DateTime(2000);
              final tb = b.createdAt ?? DateTime(2000);
              return tb.compareTo(ta);
            });
            return list;
          });

  /// Stream all appointments for a DOCTOR (real-time).
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
            list.sort((a, b) {
              final ta = a.createdAt ?? DateTime(2000);
              final tb = b.createdAt ?? DateTime(2000);
              return tb.compareTo(ta);
            });
            return list;
          });

  /// Doctor accepts a pending appointment.
  Future<void> acceptAppointment(String apptId) async {
    await _db.collection('appointments').doc(apptId).update({
      'status':     'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Doctor declines / cancels an appointment.
  Future<void> updateAppointmentStatus(
      String apptId, AppointmentStatus status) async {
    await _db.collection('appointments').doc(apptId).update(
        {'status': status.firestoreValue});
  }

  /// Patient cancels their own pending/accepted appointment.
  Future<void> cancelAppointment(String apptId) async {
    await _db.collection('appointments').doc(apptId).update(
        {'status': 'cancelled'});
  }
}

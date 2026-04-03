// lib/models/appointment.dart
// Appointment model — now includes pending/accepted status flow.

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Status flow ───────────────────────────────────────────────────────────────
// Patient books → pending
// Doctor accepts → accepted (shown as "Upcoming" to patient)
// Doctor completes → completed
// Doctor/Patient cancels → cancelled
enum AppointmentStatus { pending, accepted, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:   return 'Pending';
      case AppointmentStatus.accepted:  return 'Upcoming';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
    }
  }

  String get firestoreValue {
    switch (this) {
      case AppointmentStatus.pending:   return 'pending';
      case AppointmentStatus.accepted:  return 'accepted';
      case AppointmentStatus.completed: return 'completed';
      case AppointmentStatus.cancelled: return 'cancelled';
    }
  }

  static AppointmentStatus fromString(String s) {
    switch (s) {
      case 'accepted':  return AppointmentStatus.accepted;
      case 'completed': return AppointmentStatus.completed;
      case 'cancelled': return AppointmentStatus.cancelled;
      default:          return AppointmentStatus.pending;
    }
  }
}

class AppointmentModel {
  final String            id;
  final String            patientId;
  final String            patientName;
  final int               patientAge;
  final String            patientPhone;
  final String            doctorId;
  final String            doctorName;
  final String            specialty;
  final String            timeSlot;
  final String            date;
  AppointmentStatus       status;
  final String            symptoms;
  final String            medications;
  final String            allergies;
  final double            sleepHours;
  final String            dietaryHabits;
  final String            smokingStatus;
  final String            alcoholConsumption;
  final String            medicalHistory;
  final DateTime?         createdAt;
  final DateTime?         acceptedAt; // NEW

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.timeSlot,
    required this.date,
    required this.status,
    required this.symptoms,
    required this.medications,
    required this.allergies,
    required this.sleepHours,
    required this.dietaryHabits,
    required this.smokingStatus,
    required this.alcoholConsumption,
    required this.medicalHistory,
    this.createdAt,
    this.acceptedAt,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> m) =>
      AppointmentModel(
        id:                 id,
        patientId:          m['patientId']          as String? ?? '',
        patientName:        m['patientName']        as String? ?? '',
        patientAge:         m['patientAge']         as int?    ?? 0,
        patientPhone:       m['patientPhone']       as String? ?? '',
        doctorId:           m['doctorId']           as String? ?? '',
        doctorName:         m['doctorName']         as String? ?? '',
        specialty:          m['specialty']          as String? ?? '',
        timeSlot:           m['timeSlot']           as String? ?? '',
        date:               m['date']               as String? ?? '',
        status:             AppointmentStatusX.fromString(
                                m['status'] as String? ?? 'pending'),
        symptoms:           m['symptoms']           as String? ?? '',
        medications:        m['medications']        as String? ?? '',
        allergies:          m['allergies']          as String? ?? '',
        sleepHours:         (m['sleepHours']        as num?)?.toDouble() ?? 7.0,
        dietaryHabits:      m['dietaryHabits']      as String? ?? '',
        smokingStatus:      m['smokingStatus']      as String? ?? '',
        alcoholConsumption: m['alcoholConsumption'] as String? ?? '',
        medicalHistory:     m['medicalHistory']     as String? ?? '',
        createdAt:          (m['createdAt']  as Timestamp?)?.toDate(),
        acceptedAt:         (m['acceptedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'patientId':          patientId,
        'patientName':        patientName,
        'patientAge':         patientAge,
        'patientPhone':       patientPhone,
        'doctorId':           doctorId,
        'doctorName':         doctorName,
        'specialty':          specialty,
        'timeSlot':           timeSlot,
        'date':               date,
        'status':             status.firestoreValue,
        'symptoms':           symptoms,
        'medications':        medications,
        'allergies':          allergies,
        'sleepHours':         sleepHours,
        'dietaryHabits':      dietaryHabits,
        'smokingStatus':      smokingStatus,
        'alcoholConsumption': alcoholConsumption,
        'medicalHistory':     medicalHistory,
        'createdAt':          FieldValue.serverTimestamp(),
      };
}

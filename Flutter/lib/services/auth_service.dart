// lib/services/auth_service.dart
// Firebase Authentication — now includes city for both patients and doctors.

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, doctor }

class UserModel {
  final String   uid;
  final String   name;
  final String   email;
  final UserRole role;
  final String?  specialty;
  final String?  hospital;
  final String?  registrationNumber;
  final String?  qualification;
  final int?     fee;
  final String?  experience;
  final String?  city;      // NEW — for both patients and doctors
  final int?     age;
  final String?  phone;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.specialty,
    this.hospital,
    this.registrationNumber,
    this.qualification,
    this.fee,
    this.experience,
    this.city,
    this.age,
    this.phone,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) =>
      UserModel(
        uid:                uid,
        name:               m['name']               as String,
        email:              m['email']              as String,
        role:               m['role'] == 'doctor'
                                ? UserRole.doctor
                                : UserRole.patient,
        specialty:          m['specialty']          as String?,
        hospital:           m['hospital']           as String?,
        registrationNumber: m['registrationNumber'] as String?,
        qualification:      m['qualification']      as String?,
        fee:                m['fee']                as int?,
        experience:         m['experience']         as String?,
        city:               m['city']               as String?,
        age:                m['age']                as int?,
        phone:              m['phone']              as String?,
      );

  Map<String, dynamic> toMap() => {
        'name':  name,
        'email': email,
        'role':  role == UserRole.doctor ? 'doctor' : 'patient',
        if (specialty          != null) 'specialty':          specialty,
        if (hospital           != null) 'hospital':           hospital,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (qualification      != null) 'qualification':      qualification,
        if (fee                != null) 'fee':                fee,
        if (experience         != null) 'experience':         experience,
        if (city               != null) 'city':               city,
        if (age                != null) 'age':                age,
        if (phone              != null) 'phone':              phone,
      };
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool       _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool       get isLoggedIn  => _currentUser != null;
  bool       get isLoading   => _isLoading;
  UserRole?  get role        => _currentUser?.role;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading   = false;
      notifyListeners();
      return;
    }
    try {
      final doc =
          await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _currentUser =
            UserModel.fromMap(firebaseUser.uid, doc.data()!);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login({
    required String   email,
    required String   password,
    required UserRole expectedRole,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);
      final doc =
          await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return 'User profile not found. Please sign up again.';
      }
      final user = UserModel.fromMap(cred.user!.uid, doc.data()!);
      if (user.role != expectedRole) {
        await _auth.signOut();
        return 'This account is registered as a '
            '${user.role == UserRole.doctor ? "Doctor" : "Patient"}. '
            'Please select the correct role.';
      }
      _currentUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUp({
    required String   name,
    required String   email,
    required String   password,
    required UserRole role,
    String?  specialty,
    String?  hospital,
    String?  registrationNumber,
    String?  qualification,
    int?     fee,
    String?  experience,
    String?  city,       // NEW
    int?     age,
    String?  phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);
      final uid  = cred.user!.uid;
      final user = UserModel(
        uid:                uid,
        name:               name.trim(),
        email:              email.trim().toLowerCase(),
        role:               role,
        specialty:          specialty,
        hospital:           hospital,
        registrationNumber: registrationNumber,
        qualification:      qualification,
        fee:                fee,
        experience:         experience,
        city:               city,
        age:                age,
        phone:              phone,
      );

      await _db.collection('users').doc(uid).set(user.toMap());

      if (role == UserRole.doctor) {
        final initials = name.trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join();
        await _db.collection('doctors').doc(uid).set({
          'uid':              uid,
          'name':             name.trim(),
          'specialty':        specialty     ?? '',
          'qualification':    qualification ?? '',
          'hospital':         hospital      ?? '',
          'city':             city          ?? '', // NEW
          'rating':           0.0,
          'reviewCount':      0,
          'fee':              fee           ?? 0,
          'experience':       experience    ?? '',
          'availableSlots':   <String>[],
          'avatarInitials':   initials,
          'avatarColorIndex': 0,
          'isAvailable':      true,
        });
      }

      _currentUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  String _friendly(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':    return 'Incorrect password. Please try again.';
      case 'email-already-in-use':  return 'An account with this email already exists.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'too-many-requests':     return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':return 'No internet. Please check your connection.';
      default:                      return 'Authentication failed. Please try again.';
    }
  }
}
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Account {
  const Account(
      {required this.id,
      required this.email,
      required this.name,
      this.verified = false});
  final String id, email, name;
  final bool verified;
}

class CloudData {
  const CloudData(this.values, {this.pending = false, this.fromCache = false});
  final Map<String, dynamic> values;
  final bool pending, fromCache;
}

abstract class CloudBackend {
  Account? get currentAccount;
  Stream<Account?> get accounts;
  Stream<CloudData> watch(String uid);
  Future<void> signIn(String email, String password);
  Future<void> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> verifyEmail();
  Future<void> refreshAccount();
  Future<void> updateName(String name);
  Future<void> save(String uid, Map<String, dynamic> fields);
  Future<void> favorite(String uid, String id, bool selected);
  Future<void> savePlant(String uid, String id, Map<String, dynamic>? entry);
  Stream<List<Map<String, dynamic>>> worldPlants(String uid);
  Future<void> saveWorldPlant(
      String uid, String key, Map<String, dynamic>? plant);
}

class FirebaseBackend implements CloudBackend {
  FirebaseBackend({FirebaseAuth? auth, FirebaseFirestore? store})
      : _auth = auth ?? FirebaseAuth.instance,
        _store = store ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _store;
  Account? _account(User? user) => user == null
      ? null
      : Account(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Plant lover',
          verified: user.emailVerified);
  @override
  Account? get currentAccount => _account(_auth.currentUser);
  @override
  Stream<Account?> get accounts => _auth.userChanges().map(_account);
  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _store.collection('users').doc(uid);
  @override
  Stream<CloudData> watch(String uid) => _document(uid)
      .snapshots(includeMetadataChanges: true)
      .map((s) => CloudData(s.data() ?? {},
          pending: s.metadata.hasPendingWrites,
          fromCache: s.metadata.isFromCache));
  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user!.updateDisplayName(name);
  }

  @override
  Future<void> signOut() => _auth.signOut();
  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);
  @override
  Future<void> verifyEmail() async =>
      _auth.currentUser!.sendEmailVerification();
  @override
  Future<void> refreshAccount() async => _auth.currentUser?.reload();
  @override
  Future<void> updateName(String name) async =>
      _auth.currentUser!.updateDisplayName(name);
  @override
  Future<void> save(String uid, Map<String, dynamic> fields) =>
      _document(uid).set(fields, SetOptions(merge: true));
  @override
  Future<void> favorite(String uid, String id, bool selected) => save(uid, {
        'favorites': selected
            ? FieldValue.arrayUnion([id])
            : FieldValue.arrayRemove([id]),
      });
  @override
  Future<void> savePlant(String uid, String id, Map<String, dynamic>? entry) =>
      save(uid, {
        'garden': {id: entry ?? FieldValue.delete()},
      });
  @override
  Stream<List<Map<String, dynamic>>> worldPlants(String uid) => _document(uid)
      .collection('worldPlants')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  @override
  Future<void> saveWorldPlant(
      String uid, String key, Map<String, dynamic>? plant) {
    final document = _document(uid).collection('worldPlants').doc(key);
    return plant == null ? document.delete() : document.set(plant);
  }
}

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'The email or password is incorrect. Please try again.',
      'email-already-in-use' =>
        'This email already has an account. Sign in or reset your password.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'too-many-requests' =>
        'Too many attempts. Please wait a little and try again.',
      'network-request-failed' =>
        'Could not connect. Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled yet. Please contact support.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      'requires-recent-login' =>
        'Please sign in again before changing this account setting.',
      _ => 'Could not complete the account request. Please try again.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Your garden could not sync. Please check your account access or contact support.',
      'unavailable' =>
        'Cloud sync is temporarily unavailable. Check your connection and retry.',
      _ => 'Your changes could not sync. Please retry.',
    };
  }
  if (error is TimeoutException) {
    return 'The connection took too long. Please try again.';
  }
  if (error is StateError) return error.message.toString();
  return 'Something went wrong. Please try again.';
}

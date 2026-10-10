import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantify/services/cloud_backend.dart';

class FakeBackend implements CloudBackend {
  FakeBackend({bool signedIn = false}) {
    if (signedIn) {
      _account = const Account(
          id: 'user', email: 'user@example.com', name: 'Plant Person');
    }
  }
  Account? _account;
  final _accounts = StreamController<Account?>.broadcast();
  final Map<String, Map<String, dynamic>> documents = {};
  final Map<String, StreamController<CloudData>> _streams = {};
  bool failReset = false, failWrites = false;
  final Map<String, Map<String, Map<String, dynamic>>> world = {};
  final _worldChanges = StreamController<void>.broadcast();
  @override
  Stream<List<Map<String, dynamic>>> worldPlants(String uid) async* {
    yield world[uid]?.values.toList() ?? [];
    yield* _worldChanges.stream.map((_) => world[uid]?.values.toList() ?? []);
  }

  @override
  Future<void> saveWorldPlant(
      String uid, String key, Map<String, dynamic>? plant) async {
    if (failWrites) throw StateError('Cloud unavailable');
    final saved = world.putIfAbsent(uid, () => {});
    if (plant == null) {
      saved.remove(key);
    } else {
      saved[key] = plant;
    }
    _worldChanges.add(null);
  }

  int signInCalls = 0;
  @override
  Account? get currentAccount => _account;
  @override
  Stream<Account?> get accounts => _accounts.stream;
  @override
  Stream<CloudData> watch(String uid) async* {
    yield CloudData(_copy(uid));
    yield* _streams
        .putIfAbsent(uid, () => StreamController<CloudData>.broadcast())
        .stream;
  }

  Map<String, dynamic> _copy(String uid) =>
      jsonDecode(jsonEncode(documents[uid] ?? {})) as Map<String, dynamic>;
  void _emit(String uid) => _streams[uid]?.add(CloudData(_copy(uid)));
  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    await Future<void>.delayed(Duration.zero);
    if (password != 'password123') {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _account = Account(
        id: email == 'user@example.com' ? 'user' : 'other',
        email: email,
        name: 'Plant Person');
    _accounts.add(_account);
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    await Future<void>.delayed(Duration.zero);
    _account = Account(id: 'new-user', email: email, name: name);
    _accounts.add(_account);
  }

  @override
  Future<void> signOut() async {
    _account = null;
    _accounts.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    if (failReset) throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  Future<void> verifyEmail() async {}
  @override
  Future<void> refreshAccount() async {}
  @override
  Future<void> updateName(String name) async {
    final a = _account!;
    _account =
        Account(id: a.id, email: a.email, name: name, verified: a.verified);
    _accounts.add(_account);
  }

  @override
  Future<void> save(String uid, Map<String, dynamic> fields) async {
    if (failWrites) throw StateError('Cloud unavailable');
    documents.putIfAbsent(uid, () => {}).addAll(fields);
    _emit(uid);
  }

  @override
  Future<void> favorite(String uid, String id, bool selected) async {
    if (failWrites) throw StateError('Cloud unavailable');
    final doc = documents.putIfAbsent(uid, () => {});
    final favorites = Set<String>.from(doc['favorites'] as List? ?? []);
    if (selected) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
    doc['favorites'] = favorites.toList();
    _emit(uid);
  }

  @override
  Future<void> savePlant(
      String uid, String id, Map<String, dynamic>? entry) async {
    if (failWrites) throw StateError('Cloud unavailable');
    final doc = documents.putIfAbsent(uid, () => {});
    final garden = Map<String, dynamic>.from(doc['garden'] as Map? ?? {});
    if (entry == null) {
      garden.remove(id);
    } else {
      garden[id] = {
        ...Map<String, dynamic>.from(garden[id] as Map? ?? {}),
        ...entry
      };
    }
    doc['garden'] = garden;
    _emit(uid);
  }

  void emitFor(String uid, Map<String, dynamic> fields) {
    documents[uid] = fields;
    _emit(uid);
  }

  Future<void> dispose() async {
    await _worldChanges.close();
    await _accounts.close();
    for (final s in _streams.values) {
      await s.close();
    }
  }
}

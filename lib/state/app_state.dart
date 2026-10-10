import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/plants.dart';
import '../services/cloud_backend.dart';

class GardenEntry {
  GardenEntry({required this.plantId, this.notes = '', this.lastWatered});
  final String plantId;
  String notes;
  DateTime? lastWatered;
  Map<String, dynamic> toJson() => {
        'id': plantId,
        'notes': notes,
        'watered': lastWatered?.toIso8601String()
      };
}

class AppState extends ChangeNotifier {
  AppState(
      {SharedPreferences? preferences,
      CloudBackend? backend,
      this.connectionError})
      : _preferences = preferences,
        _backend = backend {
    if (backend != null) {
      _acceptAccount(backend.currentAccount);
      _authSubscription =
          backend.accounts.listen(_acceptAccount, onError: (Object error) {
        connectionError = friendlyError(error);
        _notify();
      });
    }
  }
  final SharedPreferences? _preferences;
  final CloudBackend? _backend;
  StreamSubscription<Account?>? _authSubscription;
  StreamSubscription<CloudData>? _dataSubscription;
  final Set<String> favorites = {};
  final Map<String, GardenEntry> garden = {};
  final Set<String> comparison = {};
  Account? account;
  bool darkMode = false, onboardingDone = false, careHints = true;
  bool cloudLoading = false, pendingSync = false, offline = false;
  bool _disposed = false;
  int _generation = 0;
  String name = 'Plant lover', email = '';
  String? storageError, connectionError;
  final Map<String, Future<void> Function()> _failedWrites = {};
  final Map<String, int> _writeVersions = {};
  Future<void> _pendingSave = Future<void>.value();
  Future<void> get saved => _pendingSave;
  bool get activeSession => account != null;
  CloudBackend get catalogueBackend => _auth;
  bool get emailVerified => account?.verified ?? false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static Future<AppState> load(
      {CloudBackend? backend, String? connectionError}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    final state = AppState(
        preferences: prefs, backend: backend, connectionError: connectionError);
    state.restore();
    if (prefs == null) {
      state.storageError =
          'Device preferences could not be saved. Your account data uses cloud storage.';
    }
    return state;
  }

  void restore() {
    try {
      final raw = _preferences?.getString('plantify.settings.v3');
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      darkMode = data['dark'] == true;
      onboardingDone = data['onboarded'] == true;
      careHints = data['hints'] != false;
    } catch (_) {
      storageError =
          'Device preferences could not be read. Your cloud collection is unaffected.';
    }
  }

  void _acceptAccount(Account? next) {
    if (_disposed) return;
    final changed = next?.id != account?.id;
    account = next;
    name = next?.name ?? 'Plant lover';
    email = next?.email ?? '';
    if (changed || (_dataSubscription == null && next != null)) {
      _generation++;
      final generation = _generation;
      unawaited(_dataSubscription?.cancel());
      _dataSubscription = null;
      comparison.clear();
      favorites.clear();
      garden.clear();
      _failedWrites.clear();
      _writeVersions.clear();
      pendingSync = false;
      offline = false;
      storageError = null;
      cloudLoading = next != null;
      if (next != null) {
        onboardingDone = true;
        _dataSubscription = _backend!.watch(next.id).listen((snapshot) {
          if (_disposed || generation != _generation) return;
          final data = snapshot.values;
          final validIds = plants.map((p) => p.id).toSet();
          favorites
            ..clear()
            ..addAll(
                (data['favorites'] is List ? data['favorites'] as List : [])
                    .whereType<String>()
                    .where(validIds.contains));
          garden.clear();
          final entries = data['garden'];
          if (entries is Map) {
            for (final entry in entries.entries) {
              if (entry.key is! String ||
                  !validIds.contains(entry.key) ||
                  entry.value is! Map) {
                continue;
              }
              final value = entry.value as Map;
              garden[entry.key as String] = GardenEntry(
                  plantId: entry.key as String,
                  notes:
                      value['notes'] is String ? value['notes'] as String : '',
                  lastWatered:
                      DateTime.tryParse(value['watered']?.toString() ?? ''));
            }
          }
          darkMode = data['dark'] == true;
          careHints = data['hints'] != false;
          cloudLoading = false;
          pendingSync = snapshot.pending;
          offline = snapshot.fromCache;
          if (_failedWrites.isEmpty) storageError = null;
          _notify();
        }, onError: (Object error) {
          if (generation != _generation) return;
          cloudLoading = false;
          storageError = friendlyError(error);
          _notify();
        });
        _write(
            'profile',
            () => _backend
                .save(next.id, {'name': next.name, 'email': next.email}));
      }
    }
    _notify();
  }

  CloudBackend get _auth =>
      _backend ??
      (throw StateError(connectionError ??
          'Account services could not connect. Please restart and try again.'));
  Future<void> signIn(String address, String password) async {
    await _auth.signIn(address.trim(), password);
    _acceptAccount(_auth.currentAccount);
  }

  Future<void> signUp(
      String displayName, String address, String password) async {
    await _auth.signUp(displayName.trim(), address.trim(), password);
    _acceptAccount(_auth.currentAccount);
    final user = account;
    if (user != null) {
      _write('profile',
          () => _auth.save(user.id, {'name': user.name, 'email': user.email}));
    }
  }

  Future<void> resetPassword(String address) =>
      _auth.resetPassword(address.trim());
  Future<void> sendVerification() => _auth.verifyEmail();
  Future<void> refreshAccount() async {
    await _auth.refreshAccount();
    _acceptAccount(_auth.currentAccount);
  }

  Future<void> logout() async {
    await _auth.signOut();
    _acceptAccount(null);
  }

  Future<void> updateProfile(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw StateError('Enter a display name.');
    await _auth.updateName(trimmed);
    _acceptAccount(_auth.currentAccount);
    final uid = account?.id;
    if (uid != null) {
      _write('profile', () => _auth.save(uid, {'name': trimmed}));
    }
  }

  void _saveSettings() {
    final data = jsonEncode(
        {'dark': darkMode, 'onboarded': onboardingDone, 'hints': careHints});
    _pendingSave = _pendingSave.then((_) async {
      if (_preferences == null) return;
      try {
        if (!await _preferences.setString('plantify.settings.v3', data)) {
          throw StateError('Write failed');
        }
      } catch (_) {
        storageError = 'Device preferences could not be saved.';
        _notify();
      }
    });
    _notify();
  }

  void _write(String key, Future<void> Function() operation) {
    final generation = _generation;
    final version = (_writeVersions[key] ?? 0) + 1;
    _writeVersions[key] = version;
    pendingSync = true;
    unawaited(Future<void>.sync(operation).then((_) {
      if (_disposed ||
          generation != _generation ||
          _writeVersions[key] != version) {
        return;
      }
      _failedWrites.remove(key);
      if (_failedWrites.isEmpty) storageError = null;
      _notify();
    }, onError: (Object error) {
      if (_disposed ||
          generation != _generation ||
          _writeVersions[key] != version) {
        return;
      }
      _failedWrites[key] = operation;
      pendingSync = false;
      storageError = friendlyError(error);
      _notify();
    }));
  }

  void retrySync() {
    final writes = Map<String, Future<void> Function()>.of(_failedWrites);
    for (final entry in writes.entries) {
      _write(entry.key, entry.value);
    }
    if (writes.isEmpty && account != null) {
      unawaited(_dataSubscription?.cancel());
      _dataSubscription = null;
      _acceptAccount(account);
    }
  }

  String _uid() =>
      account?.id ?? (throw StateError('Please sign in to save your plants.'));
  void completeOnboarding() {
    onboardingDone = true;
    _saveSettings();
  }

  void toggleCompare(String id) {
    if (comparison.contains(id)) {
      comparison.remove(id);
    } else if (comparison.length < 3) {
      comparison.add(id);
    } else {
      throw StateError(
          'Compare up to 3 plants. Remove one before adding another.');
    }
    _notify();
  }

  void toggleFavorite(String id) {
    final uid = _uid();
    final selected = !favorites.contains(id);
    if (selected) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
    _write('favorite-$id', () => _auth.favorite(uid, id, selected));
    _notify();
  }

  void addPlant(String id) {
    final uid = _uid();
    if (garden.containsKey(id)) return;
    final entry = GardenEntry(plantId: id);
    garden[id] = entry;
    final snapshot = entry.toJson();
    _write('garden-$id', () => _auth.savePlant(uid, id, snapshot));
    _notify();
  }

  void removePlant(String id) {
    final uid = _uid();
    garden.remove(id);
    for (final key in ['notes-$id', 'watered-$id']) {
      _writeVersions[key] = (_writeVersions[key] ?? 0) + 1;
      _failedWrites.remove(key);
    }
    _write('garden-$id', () => _auth.savePlant(uid, id, null));
    _notify();
  }

  void saveNotes(String id, String notes) {
    final uid = _uid();
    final entry = garden[id];
    if (entry == null) return;
    entry.notes = notes;
    _write('notes-$id', () => _auth.savePlant(uid, id, {'notes': notes}));
    _notify();
  }

  void markWatered(String id) {
    final uid = _uid();
    final entry = garden[id];
    if (entry == null) return;
    entry.lastWatered = DateTime.now();
    final watered = entry.lastWatered!.toIso8601String();
    _write('watered-$id', () => _auth.savePlant(uid, id, {'watered': watered}));
    _notify();
  }

  void setDarkMode(bool value) {
    darkMode = value;
    _saveSettings();
    final uid = account?.id;
    if (uid != null) _write('dark', () => _auth.save(uid, {'dark': value}));
  }

  void setCareHints(bool value) {
    careHints = value;
    _saveSettings();
    final uid = account?.id;
    if (uid != null) _write('hints', () => _auth.save(uid, {'hints': value}));
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    unawaited(_dataSubscription?.cancel());
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

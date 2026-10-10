import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../data/plants.dart';
import '../data/world_plant.dart';

class WorldPhoto {
  const WorldPhoto(
      {this.bytes,
      this.url,
      this.asset,
      required this.credit,
      required this.source,
      this.license = ''});
  final Uint8List? bytes;
  final String? url;
  final String? asset;
  final String credit, source, license;
}

class WorldPhotos {
  WorldPhotos({http.Client? client}) : _client = client ?? http.Client();
  static final shared = WorldPhotos();
  final http.Client _client;
  final _cache = <int, Future<WorldPhoto?>>{};
  final _pending = <_PhotoRequest>[];
  bool _running = false;
  bool _closed = false;
  final _watchers = <int, int>{};
  DateTime _nextRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  _PhotoRequest? _active;
  Timer? _waitTimer;
  Completer<void>? _waiter;
  bool get _cancelled =>
      _closed ||
      (_active?.watched == true && !_watchers.containsKey(_active!.key));

  void _cancelWait() {
    _waitTimer?.cancel();
    if (_waiter != null && !_waiter!.isCompleted) _waiter!.complete();
  }

  Future<WorldPhoto?> watch(WorldPlant plant, {bool priority = false}) {
    final key = plant.acceptedKey ?? plant.key;
    _watchers.update(key, (count) => count + 1, ifAbsent: () => 1);
    return photo(plant, priority: priority);
  }

  void release(WorldPlant plant) {
    final key = plant.acceptedKey ?? plant.key;
    final count = (_watchers[key] ?? 1) - 1;
    if (count > 0) {
      _watchers[key] = count;
      return;
    }
    _watchers.remove(key);
    if (_active?.key == key) _cancelWait();
    final index = _pending.indexWhere((request) => request.key == key);
    if (index < 0) return;
    _pending.removeAt(index).done.complete(null);
    _cache.remove(key);
  }

  Future<http.Response> _get(Uri uri) async {
    for (var attempt = 0;; attempt++) {
      final wait = _nextRequestAt.difference(DateTime.now());
      if (_cancelled) throw StateError('Photo request no longer visible');
      if (wait > Duration.zero) {
        final waiter = _waiter = Completer<void>();
        _waitTimer = Timer(wait, waiter.complete);
        await waiter.future;
        _waitTimer = null;
        _waiter = null;
      }
      if (_cancelled) throw StateError('Photo request no longer visible');
      _nextRequestAt = DateTime.now().add(const Duration(seconds: 1));
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 12));
      if (_cancelled) throw StateError('Photo request no longer visible');
      if (![429, 503].contains(response.statusCode) || attempt >= 2) {
        return response;
      }
      final seconds =
          int.tryParse(response.headers['retry-after'] ?? '') ?? (4 << attempt);
      _nextRequestAt =
          DateTime.now().add(Duration(seconds: seconds.clamp(1, 30)));
    }
  }

  Future<WorldPhoto?> photo(WorldPlant plant, {bool priority = false}) {
    for (final local in plants) {
      if (local.botanical.toLowerCase() == plant.name.toLowerCase()) {
        return Future.value(WorldPhoto(
            asset: local.imagePath,
            credit: local.imageCredit.isEmpty
                ? 'Plantify botanical illustration'
                : local.imageCredit,
            source:
                local.imageSource.isEmpty ? plant.source : local.imageSource));
      }
    }
    // Higher taxa must not be presented with a descendant's species photograph.
    if (!['SPECIES', 'SUBSPECIES', 'VARIETY', 'FORM'].contains(plant.rank)) {
      return Future.value(null);
    }
    final key = plant.acceptedKey ?? plant.key;
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      if (priority) {
        final index = _pending.indexWhere((request) => request.key == key);
        if (index >= 0) _pending.insert(0, _pending.removeAt(index));
      }
      return existing;
    }
    if (_closed) return Future.value(null);
    final request = _PhotoRequest(key, watched: _watchers.containsKey(key));
    final result = request.done.future;
    if (priority) {
      _pending.insert(0, request);
    } else {
      _pending.add(request);
    }
    _cache[key] = result;
    if (_cache.length > 128) _cache.remove(_cache.keys.first);
    unawaited(_drain());
    return result;
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (!_closed && _pending.isNotEmpty) {
        final request = _pending.removeAt(0);
        _active = request;
        request.done.complete(await _fetch(request.key));
        _active = null;
      }
    } finally {
      _running = false;
    }
  }

  static String? reusableLicense(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host != 'creativecommons.org') return null;
    if (!(uri.path.startsWith('/licenses/by/') ||
        uri.path.startsWith('/licenses/by-sa/') ||
        uri.path.startsWith('/publicdomain/zero/'))) {
      return null;
    }
    return uri.replace(scheme: 'https').toString();
  }

  Future<WorldPhoto?> _fetch(int key) async {
    try {
      // One connection at a time, including images, as requested by GBIF.
      for (final observationsOnly in [true, false]) {
        final response =
            await _get(Uri.https('api.gbif.org', '/v1/occurrence/search', {
          'taxonKey': '$key',
          'mediaType': 'StillImage',
          'limit': '30',
          'license': ['CC_BY_4_0', 'CC0_1_0'],
          if (observationsOnly) 'basisOfRecord': 'HUMAN_OBSERVATION'
        }));
        if (response.statusCode != 200) {
          _cache.remove(key);
          return null;
        }
        final records =
            (jsonDecode(response.body) as Map)['results'] as List? ?? [];
        var attempts = 0;
        for (final record in records) {
          if (record is! Map ||
              (record['speciesKey'] != key &&
                  record['taxonKey'] != key &&
                  record['acceptedTaxonKey'] != key)) {
            continue;
          }
          for (final media in record['media'] as List? ?? []) {
            if (media is! Map || media['type'] != 'StillImage') continue;
            final license = reusableLicense(media['license']);
            final identifier = media['identifier'];
            if (license == null ||
                identifier is! String ||
                !['https', 'http'].contains(Uri.tryParse(identifier)?.scheme) ||
                record['key'] is! int) {
              continue;
            }
            if (++attempts > 3) break;
            final hash = md5.convert(utf8.encode(identifier)).toString();
            final imageUri = Uri.https('api.gbif.org',
                '/v1/image/cache/512x/occurrence/${record['key']}/media/$hash');
            // GBIF image responses do not allow cross-origin byte fetching.
            // On Web the widget uses an HTML image element instead.
            if (kIsWeb) {
              return WorldPhoto(
                  url: imageUri.toString(),
                  credit:
                      '${media['creator'] ?? media['rightsHolder'] ?? media['publisher'] ?? 'Source photographer'}',
                  source: 'https://www.gbif.org/occurrence/${record['key']}',
                  license: license);
            }
            final image = await _get(imageUri);
            if (image.statusCode != 200 ||
                image.bodyBytes.isEmpty ||
                image.bodyBytes.length > 2 * 1024 * 1024 ||
                !(image.headers['content-type'] ?? '').startsWith('image/')) {
              continue;
            }
            return WorldPhoto(
                bytes: image.bodyBytes,
                credit:
                    '${media['creator'] ?? media['rightsHolder'] ?? media['publisher'] ?? 'Source photographer'}',
                source: 'https://www.gbif.org/occurrence/${record['key']}',
                license: license);
          }
          if (attempts >= 3) break;
        }
      }
    } catch (_) {
      // An unavailable photograph must never prevent catalogue browsing.
      _cache.remove(key);
    }
    return null;
  }

  void close() {
    _closed = true;
    _cancelWait();
    _client.close();
    _cache.clear();
    _watchers.clear();
    for (final request in _pending) {
      request.done.complete(null);
    }
    _pending.clear();
  }
}

class _PhotoRequest {
  _PhotoRequest(this.key, {this.watched = false});
  final int key;
  final bool watched;
  final done = Completer<WorldPhoto?>();
}

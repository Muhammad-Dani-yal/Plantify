import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myapp/data/world_plant.dart';
import 'package:myapp/services/world_photos.dart';

const plant = WorldPlant(
    key: 5275521,
    name: 'Welwitschia mirabilis',
    scientific: 'Welwitschia mirabilis Hook.f.',
    rank: 'SPECIES',
    status: 'ACCEPTED');
Map<String, dynamic> observation(
        {int key = 5275521,
        String license = 'http://creativecommons.org/licenses/by/4.0/'}) =>
    {
      'key': 12345,
      'speciesKey': key,
      'media': [
        {
          'type': 'StillImage',
          'identifier': 'https://photos.example/plant.jpg',
          'creator': 'Plant Photographer',
          'license': license
        }
      ]
    };
void main() {
  test(
      'Species-matched licensed photos preserve attribution and cache repeated requests',
      () async {
    var calls = 0;
    final photos = WorldPhotos(client: MockClient((request) async {
      calls++;
      if (request.url.path.contains('/image/cache/')) {
        return http.Response.bytes([1, 2, 3], 200,
            headers: {'content-type': 'image/jpeg'});
      }
      expect(request.url.queryParameters['taxonKey'], '${plant.key}');
      return http.Response(
          jsonEncode({
            'results': [observation()]
          }),
          200);
    }));
    final results =
        await Future.wait([photos.photo(plant), photos.photo(plant)]);
    expect(calls, 2);
    expect(results.first!.credit, 'Plant Photographer');
    expect(
        results.first!.license, 'https://creativecommons.org/licenses/by/4.0/');
    expect(results.first!.source, 'https://www.gbif.org/occurrence/12345');
    expect(results.last, same(results.first));
    photos.close();
  });
  test('Wrong species and restricted or missing media licences are excluded',
      () async {
    final photos = WorldPhotos(client: MockClient((request) async {
      expect(request.url.path, '/v1/occurrence/search');
      return http.Response(
          jsonEncode({
            'results': [
              observation(key: 999),
              observation(
                  license: 'https://creativecommons.org/licenses/by-nc/4.0/'),
              observation(license: ''),
            ]
          }),
          200);
    }));
    expect(await photos.photo(plant), isNull);
    expect(
        WorldPhotos.reusableLicense(
            'https://creativecommons.org.evil/licenses/by/4.0/'),
        isNull);
    photos.close();
  });
  test(
      'Reuses bundled photos without network and does not mislabel genus photos',
      () async {
    final photos = WorldPhotos(
        client:
            MockClient((_) async => throw StateError('No network expected')));
    final local = await photos.photo(const WorldPlant(
        key: 1,
        name: 'Monstera deliciosa',
        scientific: 'Monstera deliciosa Liebm.',
        rank: 'SPECIES',
        status: 'ACCEPTED'));
    expect(local!.asset, 'assets/botanical/monstera.webp');
    expect(
        await photos.photo(const WorldPlant(
            key: 2,
            name: 'Citrus',
            scientific: 'Citrus L.',
            rank: 'GENUS',
            status: 'ACCEPTED')),
        isNull);
    photos.close();
  });
  test('Unavailable source does not fail plant browsing', () async {
    final photos = WorldPhotos(
        client: MockClient((_) async => http.Response('Unavailable', 503)));
    expect(await photos.photo(plant), isNull);
    photos.close();
  });
  test(
      'Opening a profile prioritizes its queued photo without duplicate requests',
      () async {
    final started = Completer<void>();
    final first = Completer<http.Response>();
    final order = <int>[];
    final photos = WorldPhotos(client: MockClient((request) async {
      final key = int.parse(request.url.queryParameters['taxonKey']!);
      if (request.url.queryParameters.containsKey('basisOfRecord')) {
        order.add(key);
        if (key == 100) {
          started.complete();
          return first.future;
        }
      }
      return http.Response('{"results":[]}', 200);
    }));
    WorldPlant species(int key) => WorldPlant(
        key: key,
        name: 'Species $key',
        scientific: 'Species $key',
        rank: 'SPECIES',
        status: 'ACCEPTED');
    final initial = photos.photo(species(100));
    await started.future;
    final background = photos.photo(species(200));
    final selected = photos.photo(species(300));
    expect(photos.photo(species(300), priority: true), same(selected));
    first.complete(http.Response('{"results":[]}', 200));
    await Future.wait([initial, background, selected]);
    expect(order, [100, 300, 200]);
    photos.close();
  });
  test('Leaving a queued card cancels only its unshared photo request',
      () async {
    final started = Completer<void>();
    final first = Completer<http.Response>();
    final requested = <int>[];
    final photos = WorldPhotos(client: MockClient((request) async {
      final key = int.parse(request.url.queryParameters['taxonKey']!);
      requested.add(key);
      if (key == 100) {
        started.complete();
        return first.future;
      }
      return http.Response('{"results":[]}', 200);
    }));
    WorldPlant species(int key) => WorldPlant(
        key: key,
        name: 'Species $key',
        scientific: 'Species $key',
        rank: 'SPECIES',
        status: 'ACCEPTED');
    final initial = photos.watch(species(100));
    await started.future;
    final cancelled = photos.watch(species(200));
    final shared = photos.watch(species(300));
    photos.watch(species(300));
    photos.release(species(200));
    photos.release(species(300));
    expect(await cancelled, isNull);
    first.complete(http.Response('Unavailable', 400));
    await Future.wait([initial, shared]);
    expect(requested, isNot(contains(200)));
    expect(requested, contains(300));
    photos.release(species(100));
    photos.release(species(300));
    photos.close();
  });
  test(
      'A temporary photo rate limit retries automatically and keeps attribution',
      () async {
    var calls = 0;
    final photos = WorldPhotos(client: MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('Slow down', 429, headers: {'retry-after': '1'});
      }
      if (request.url.path.contains('/image/cache/')) {
        return http.Response.bytes([1, 2, 3], 200,
            headers: {'content-type': 'image/jpeg'});
      }
      return http.Response(
          jsonEncode({
            'results': [observation()]
          }),
          200);
    }));
    final photo = await photos.photo(plant);
    expect(calls, 3);
    expect(photo!.credit, 'Plant Photographer');
    expect(await photos.photo(plant), same(photo));
    photos.close();
  });
  test('Legacy HTTP media is displayed only through the HTTPS GBIF image proxy',
      () async {
    final photos = WorldPhotos(client: MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.gbif.org');
      if (request.url.path.contains('/image/cache/')) {
        return http.Response.bytes([1, 2, 3], 200,
            headers: {'content-type': 'image/jpeg'});
      }
      final item = observation();
      (item['media'] as List).first['identifier'] =
          'http://museum.example/specimen.jpg';
      return http.Response(
          jsonEncode({
            'results': [item]
          }),
          200);
    }));
    expect((await photos.photo(plant))!.credit, 'Plant Photographer');
    photos.close();
  });
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantify/components/app_theme.dart';
import 'package:plantify/components/plant_profile.dart';
import 'package:plantify/screen/home_page.dart';
import 'package:plantify/data/world_plant.dart';
import 'package:plantify/screen/world_catalogue.dart';
import 'package:plantify/services/world_catalogue.dart';
import 'package:plantify/state/app_state.dart';
import 'fake_backend.dart';

Map<String, dynamic> record(int key, String name) => {
      'key': key,
      'canonicalName': name,
      'scientificName': '$name L.',
      'rank': 'SPECIES',
      'taxonomicStatus': 'ACCEPTED',
      'family': 'Rosaceae',
      'genus': 'Rosa'
    };
http.Response response(List<Map<String, dynamic>> items, {bool end = true}) =>
    http.Response(
        jsonEncode({'results': items, 'count': 446842, 'endOfRecords': end}),
        200);
Widget harness(AppState state, WorldCatalogue catalogue) => AppScope(
    state: state,
    child: MaterialApp(
        theme: Botanical.theme(),
        home: WorldCatalogueScreen(catalogue: catalogue)));

Finder catalogueScroll() => find
    .descendant(
        of: find.byType(CustomScrollView).first,
        matching: find.byType(Scrollable))
    .first;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true));
  tearDown(
      () => binding.platformDispatcher.clearAccessibilityFeaturesTestValue());
  test('World records preserve names, taxonomy and source identity', () {
    final plant = WorldPlant.fromJson(
        {...record(123, 'Rosa canina'), 'acceptedKey': 456});
    expect(plant.source, 'https://www.gbif.org/species/123');
    expect(WorldPlant.fromJson(plant.toJson()).acceptedKey, 456);
    expect(() => WorldPlant.fromJson({'key': -1}), throwsFormatException);
    expect(() => WorldPlant.fromJson({'key': 1}), throwsFormatException);
  });
  test('Requests use the plant kingdom, backbone, rank, synonyms and paging',
      () async {
    final client = MockClient((request) async {
      final params = request.url.queryParameters;
      expect(params['highertaxon_key'], '6');
      expect(params['datasetKey'], WorldCatalogue.backbone);
      expect(params['q'], 'Rosa');
      expect(params['rank'], 'VARIETY');
      expect(params.containsKey('status'), false);
      expect(params['offset'], '48');
      return response([record(1, 'Rosa canina')], end: false);
    });
    final catalogue = WorldCatalogue(client: client);
    final page = await catalogue.search(
        query: ' Rosa ', rank: 'VARIETY', acceptedOnly: false, offset: 48);
    expect(page.total, 446842);
    expect(page.nextOffset, 49);
    expect(page.hasMore, true);
    catalogue.close();
  });
  test('API failure is reported; malformed records do not break paging',
      () async {
    final fail = WorldCatalogue(
        client: MockClient((_) async => http.Response('Unavailable', 503)));
    await expectLater(fail.search(), throwsStateError);
    fail.close();
    final catalogue = WorldCatalogue(
        client: MockClient((_) async => response([
              {'key': -1},
              record(2, 'Rosa rugosa')
            ], end: false)));
    final page = await catalogue.search(offset: 9998);
    expect(page.items.length, 1);
    expect(page.nextOffset, 10000);
    expect(page.hasMore, false);
    catalogue.close();
  });
  testWidgets(
      'World catalogue fits narrow screens and saves/removes cloud records',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final backend = FakeBackend(signedIn: true);
    final state = AppState(backend: backend);
    final catalogue = WorldCatalogue(
        client:
            MockClient((_) async => response([record(123, 'Rosa canina')])));
    await tester.pumpWidget(harness(state, catalogue));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final save = find.byTooltip('Save Rosa canina to world plants');
    await tester.scrollUntilVisible(save, 250, scrollable: catalogueScroll());
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.world['user']?['123']?['canonicalName'], 'Rosa canina');
    final remove = find.byTooltip('Remove Rosa canina from world plants');
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(backend.world['user']?.isEmpty, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
    await backend.dispose();
  });
  testWidgets('A late response cannot replace newer world search results',
      (tester) async {
    final delayed = Completer<http.Response>();
    final catalogue = WorldCatalogue(client: MockClient((request) async {
      final q = request.url.queryParameters['q'];
      if (q == 'First') return delayed.future;
      return response(
          [record(2, q == 'Second' ? 'New result' : 'Initial result')]);
    }));
    final state = AppState();
    await tester.pumpWidget(harness(state, catalogue));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('world-search'));
    await tester.enterText(input, 'First');
    await tester.pump(const Duration(milliseconds: 460));
    await tester.enterText(input, 'Second');
    await tester.pump(const Duration(milliseconds: 460));
    await tester.pumpAndSettle();
    delayed.complete(response([record(1, 'Old result')]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('New result'), 250,
        scrollable: catalogueScroll());
    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
  });
  testWidgets('Saved world collection clears when the account signs out',
      (tester) async {
    final backend = FakeBackend(signedIn: true);
    backend.world['user'] = {'1': record(1, 'Private plant')};
    final state = AppState(backend: backend);
    final catalogue =
        WorldCatalogue(client: MockClient((_) async => response([])));
    await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(
            theme: Botanical.theme(),
            home:
                WorldCatalogueScreen(catalogue: catalogue, savedOnly: true))));
    await tester.pumpAndSettle();
    expect(find.text('Private plant'), findsOneWidget);
    await state.logout();
    await tester.pumpAndSettle();
    expect(find.text('Private plant'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
    await backend.dispose();
  });

  testWidgets(
      'Scroll loads the next page once, retries failure and deduplicates',
      (tester) async {
    final requests = <int>[];
    final pending = Completer<http.Response>();
    var secondAttempts = 0;
    final catalogue = WorldCatalogue(client: MockClient((request) async {
      final offset = int.parse(request.url.queryParameters['offset']!);
      requests.add(offset);
      if (offset == 0) {
        return response(
            List.generate(24, (i) => record(i + 1, 'Rosa species $i')),
            end: false);
      }
      if (++secondAttempts == 1) return pending.future;
      return response(
          [record(24, 'Rosa species 23'), record(25, 'Next species')]);
    }));
    final state = AppState();
    await tester.pumpWidget(harness(state, catalogue));
    await tester.pumpAndSettle();
    expect(find.text('Explore more world plants'), findsNothing);
    // The grid builds only the visible cards, rather than every loaded photo.
    expect(
        find.byTooltip('Save Rosa species 23 to world plants'), findsNothing);
    final scroll =
        tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
    await tester.pump();
    scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
    await tester.pump();
    expect(requests, [0, 24]);
    pending.complete(http.Response('Unavailable', 503));
    await tester.pumpAndSettle();
    expect(find.text('Rosa species 23'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Retry catalogue'), 200,
        scrollable: catalogueScroll());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry catalogue'));
    await tester.pumpAndSettle();
    scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Next species'), findsOneWidget);
    expect(find.text('Rosa species 23'), findsOneWidget);
    expect(requests, [0, 24, 24]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
  });

  testWidgets('Fruit collection browses multiple genera and resets for unique',
      (tester) async {
    final queries = <String>[];
    final catalogue = WorldCatalogue(client: MockClient((request) async {
      final genus = request.url.queryParameters['q'] ?? 'Rosa';
      queries.add(genus);
      return response([
        {...record(queries.length, '$genus example'), 'genus': genus}
      ]);
    }));
    final state = AppState();
    await tester.pumpWidget(harness(state, catalogue));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fruit plants'));
    await tester.pumpAndSettle();
    expect(queries, containsAll(['Citrus', 'Mangifera', 'Malus', 'Psidium']));
    final controller = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    for (var i = 0; i < 8; i++) {
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(queries, containsAll(['Musa', 'Vitis', 'Persea', 'Artocarpus']));
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unique plants'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Welwitschia example'), 200,
        scrollable: catalogueScroll());
    expect(find.text('Citrus example'), findsNothing);
    expect(find.text('Welwitschia example'), findsOneWidget);
    expect(queries, containsAll(['Welwitschia', 'Lithops', 'Nepenthes']));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
  });

  testWidgets(
      'Default Discover and Search include plants without bundled photos',
      (tester) async {
    final queries = <String>[];
    final catalogue = WorldCatalogue(client: MockClient((request) async {
      queries.add(request.url.queryParameters['q'] ?? '');
      return response([
        record(987653, 'Monstera deliciosa'),
        record(987654, 'Unbundled species'),
      ]);
    }));
    final state = AppState(backend: FakeBackend(signedIn: true));
    await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(
            theme: Botanical.theme(), home: HomePage(catalogue: catalogue))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Downloaded plants (100)'), 200,
        scrollable: catalogueScroll());
    expect(find.text('Downloaded plants (100)'), findsOneWidget);
    expect(find.text('Unbundled species'), findsNothing);
    final grids = tester
        .widgetList<SliverGrid>(find.descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(SliverGrid)))
        .toList();
    expect(grids.first.delegate.estimatedChildCount, 100);
    await tester.scrollUntilVisible(find.text('Unbundled species'), 300,
        maxScrolls: 100,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable))
            .first);
    await Scrollable.ensureVisible(
        tester.element(find.text('Unbundled species')),
        alignment: .2);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SliverGrid>(find.byType(SliverGrid).first)
            .delegate
            .estimatedChildCount,
        1);
    await tester.tap(find.text('Unbundled species'));
    await tester.pumpAndSettle();
    expect(find.byType(PlantProfile), findsOneWidget);
    expect(find.text('Meet your plant'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('plant-search')), 'Welwitschia');
    await tester.pump(const Duration(milliseconds: 460));
    await tester.pumpAndSettle();
    expect(queries, contains('Welwitschia'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    catalogue.close();
  });
}

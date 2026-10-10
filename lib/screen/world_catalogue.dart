import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/botanical_widgets.dart';
import '../data/world_plant.dart';
import '../data/plants.dart';
import 'plant_details.dart';
import '../services/world_catalogue.dart';
import '../state/app_state.dart';
import 'plant_chat.dart';
import '../components/motion_icon.dart';
import '../components/world_plant_photo.dart';
import '../components/plant_profile.dart';

class WorldCatalogueScreen extends StatefulWidget {
  const WorldCatalogueScreen(
      {super.key,
      this.catalogue,
      this.savedOnly = false,
      this.initialQuery = '',
      this.embedded = false,
      this.searchTab = false,
      this.onCareCollection});
  final bool embedded, searchTab;
  final VoidCallback? onCareCollection;
  final String initialQuery;
  final WorldCatalogue? catalogue;
  final bool savedOnly;
  @override
  State<WorldCatalogueScreen> createState() => _WorldCatalogueScreenState();
}

class _WorldCatalogueScreenState extends State<WorldCatalogueScreen> {
  late final WorldCatalogue _catalogue = widget.catalogue ?? WorldCatalogue();
  final _query = TextEditingController();
  final _scroll = ScrollController();
  String _collection = 'All plants';
  final Map<String, int> _genusOffsets = {};
  final Set<String> _finishedGenera = {};
  int _genusCursor = 0;
  static const collections = {
    'Fruit plants': [
      'Citrus',
      'Mangifera',
      'Malus',
      'Psidium',
      'Prunus',
      'Punica',
      'Musa',
      'Fragaria',
      'Vitis',
      'Carica',
      'Ficus',
      'Pyrus',
      'Persea',
      'Artocarpus'
    ],
    'Everyday plants': [
      'Rosa',
      'Ocimum',
      'Mentha',
      'Hibiscus',
      'Epipremnum',
      'Monstera',
      'Dracaena',
      'Aloe',
      'Jasminum'
    ],
    'Unique plants': [
      'Welwitschia',
      'Lithops',
      'Nepenthes',
      'Amorphophallus',
      'Adansonia',
      'Dionaea',
      'Rafflesia',
      'Tillandsia'
    ],
  };
  void _nearEnd() {
    if (_scroll.hasClients &&
        _scroll.position.extentAfter < 650 &&
        !_savedOnly &&
        !_loading &&
        _hasMore &&
        _error == null) {
      _search(more: true);
    }
  }

  final Map<int, WorldPlant> _saved = {};
  final Set<int> _saving = {};
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _debounce;
  List<WorldPlant> _items = [];
  String _rank = 'SPECIES';
  String? _error, _libraryError, _uid;
  bool _accepted = true, _loading = false, _hasMore = false;
  late bool _savedOnly = widget.savedOnly;
  int _version = 0, _total = 0, _offset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_nearEnd);
    _query.text = widget.initialQuery;
    if (!_savedOnly) _search();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (_uid == state.account?.id) return;
    _uid = state.account?.id;
    _saved.clear();
    _libraryError = null;
    unawaited(_subscription?.cancel());
    final uid = _uid;
    if (uid == null) return;
    _subscription = state.catalogueBackend.worldPlants(uid).listen((records) {
      if (!mounted || _uid != uid) return;
      setState(() {
        _saved.clear();
        for (final record in records) {
          try {
            final plant = WorldPlant.fromJson(record);
            _saved[plant.key] = plant;
          } on FormatException {
            continue;
          }
        }
        _libraryError = null;
      });
    }, onError: (Object error) {
      if (mounted && _uid == uid) {
        setState(() => _libraryError =
            'Saved world plants could not sync. Reopen the catalogue to retry.');
      }
    });
  }

  @override
  void dispose() {
    _version++;
    _debounce?.cancel();
    unawaited(_subscription?.cancel());
    _query.dispose();
    _scroll.dispose();
    if (widget.catalogue == null) _catalogue.close();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    _version++;
    if (_savedOnly) {
      setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _items = [];
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 450), () => _search());
  }

  Future<void> _search({bool more = false}) async {
    if (more && (_loading || !_hasMore || _savedOnly)) return;
    if (!more && _scroll.hasClients) _scroll.jumpTo(0);
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _items = [];
        _offset = 0;
        _genusOffsets.clear();
        _finishedGenera.clear();
        _genusCursor = 0;
      }
    });
    try {
      final WorldPage result;
      if (_collection == 'All plants' || _query.text.trim().isNotEmpty) {
        final page = await _catalogue.search(
            query: _query.text,
            rank: _rank,
            acceptedOnly: _accepted,
            offset: more ? _offset : 0);
        final genera = collections[_collection];
        result = genera == null
            ? page
            : WorldPage(
                items: page.items
                    .where((p) => genera
                        .any((g) => g.toLowerCase() == p.genus.toLowerCase()))
                    .toList(),
                total: 0,
                nextOffset: page.nextOffset,
                hasMore: page.hasMore);
      } else {
        final genera = collections[_collection]!;
        final batch = <String>[];
        var cursor = _genusCursor;
        for (var i = 0; i < genera.length && batch.length < 4; i++) {
          final genus = genera[cursor++ % genera.length];
          if (!_finishedGenera.contains(genus)) batch.add(genus);
        }
        final pages = await Future.wait(batch.map((genus) => _catalogue.search(
            query: genus,
            rank: _rank,
            acceptedOnly: _accepted,
            offset: _genusOffsets[genus] ?? 0,
            limit: 6)));
        if (!mounted || version != _version) return;
        _genusCursor = cursor % genera.length;
        final found = <WorldPlant>[];
        for (var i = 0; i < batch.length; i++) {
          final page = pages[i];
          _genusOffsets[batch[i]] = page.nextOffset;
          if (!page.hasMore) _finishedGenera.add(batch[i]);
          found.addAll(page.items.where((p) =>
              p.genus.toLowerCase() == batch[i].toLowerCase() &&
              '${p.name} ${p.scientific} ${p.family}'
                  .toLowerCase()
                  .contains(_query.text.trim().toLowerCase())));
        }
        result = WorldPage(
            items: found,
            total: 0,
            nextOffset: _genusOffsets.values.fold(0, (a, b) => a + b),
            hasMore: _finishedGenera.length < genera.length);
      }
      if (!mounted || version != _version) return;
      setState(() {
        final seen = (more ? _items : <WorldPlant>[]).map((p) => p.key).toSet();
        _items = [
          if (more) ..._items,
          ...result.items.where((p) => seen.add(p.key))
        ];
        _total = result.total;
        _offset = result.nextOffset;
        _hasMore = result.hasMore;
      });
    } catch (_) {
      if (mounted && version == _version) {
        setState(() => _error =
            'Could not reach the world catalogue. Check your connection and retry.');
      }
    } finally {
      if (mounted && version == _version) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && version == _version) _nearEnd();
        });
      }
    }
  }

  Future<void> _save(WorldPlant plant) async {
    final state = AppScope.of(context);
    final uid = state.account?.id;
    if (uid == null) {
      showMessage(context, 'Sign in to save world plants.');
      return;
    }
    final removing = _saved.containsKey(plant.key);
    setState(() => _saving.add(plant.key));
    try {
      await state.catalogueBackend.saveWorldPlant(
          uid, '${plant.key}', removing ? null : plant.toJson());
      if (mounted && _uid == uid) {
        showMessage(
            context,
            removing
                ? 'Plant removed from your world collection.'
                : 'Plant saved to your world collection.');
      }
    } catch (_) {
      if (mounted && _uid == uid) {
        showMessage(context,
            'Plant could not be saved. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving.remove(plant.key));
    }
  }

  String _count(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  @override
  Widget build(BuildContext context) {
    final downloadedFirst = widget.embedded && !widget.searchTab && !_savedOnly;
    final downloaded = downloadedFirst
        ? plants.where((plant) {
            final query = _query.text.trim().toLowerCase();
            final genus = plant.botanical.split(' ').first;
            return (_collection == 'All plants' ||
                    collections[_collection]!.contains(genus)) &&
                (_rank.isEmpty || _rank == 'SPECIES') &&
                '${plant.name} ${plant.botanical} ${plant.category}'
                    .toLowerCase()
                    .contains(query);
          }).toList()
        : <Plant>[];
    final bundledNames =
        downloaded.map((plant) => plant.botanical.toLowerCase()).toSet();
    final items = _savedOnly
        ? _saved.values
            .where((p) => '${p.name} ${p.scientific} ${p.family} ${p.genus}'
                .toLowerCase()
                .contains(_query.text.trim().toLowerCase()))
            .toList()
        : _items
            .where((plant) => !bundledNames.contains(plant.name.toLowerCase()))
            .toList();
    final body = LayoutBuilder(builder: (context, constraints) {
      final side =
          ((constraints.maxWidth - 1120) / 2).clamp(24.0, double.infinity);
      return CustomScrollView(controller: _scroll, cacheExtent: 150, slivers: [
        SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 18, side, 0),
            sliver: SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Eyebrow('A whole world of green'),
                  const SizedBox(height: 10),
                  Text(
                      widget.searchTab
                          ? 'Find your green match.'
                          : 'Beyond your windowsill.',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  const Text(
                      'Discover botanical records from around the world. Photographs load as you explore; a missing photo never hides a plant.'),
                  const SizedBox(height: 20),
                  if (widget.onCareCollection != null) ...[
                    OutlinedButton.icon(
                        onPressed: widget.onCareCollection,
                        icon: const MotionIcon(Icons.spa_outlined),
                        label: const Text('Browse care profiles')),
                    const SizedBox(height: 16),
                  ],
                  Wrap(spacing: 10, runSpacing: 8, children: [
                    ChoiceChip(
                        avatar: const MotionIcon(Icons.public, size: 17),
                        label: const Text('Explore the world'),
                        selected: !_savedOnly,
                        onSelected: (_) {
                          _savedOnly = false;
                          _search();
                        }),
                    ChoiceChip(
                        avatar:
                            const MotionIcon(Icons.bookmark_border, size: 17),
                        label: Text('My world plants (${_saved.length})'),
                        selected: _savedOnly,
                        onSelected: (_) {
                          _debounce?.cancel();
                          _version++;
                          setState(() {
                            _savedOnly = true;
                            _loading = false;
                            _query.clear();
                          });
                        }),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                      key: ValueKey(
                          widget.searchTab ? 'plant-search' : 'world-search'),
                      controller: _query,
                      onChanged: (_) => _changed(),
                      onSubmitted: (_) {
                        _debounce?.cancel();
                        if (!_savedOnly) _search();
                      },
                      decoration: InputDecoration(
                          hintText: widget.searchTab
                              ? 'Name, species, light, or collection'
                              : 'Try Rosa, oak, orchids, or Rosaceae',
                          prefixIcon: const Icon(Icons.travel_explore),
                          suffixIcon: _query.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear world search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _query.clear();
                                    _changed();
                                  }))),
                  if (!_savedOnly) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final name in ['All plants', ...collections.keys])
                        ChoiceChip(
                            avatar: MotionIcon(collectionIcon(name), size: 17),
                            label: Text(name),
                            selected: _collection == name,
                            onSelected: (_) {
                              _collection = name;
                              _debounce?.cancel();
                              _search();
                            }),
                    ]),
                    if (_collection != 'All plants')
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              'Selected ${_collection.toLowerCase()} genera and their relatives. This is not an edibility guide.',
                              style: const TextStyle(fontSize: 11))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final rank in const {
                        'SPECIES': 'Species',
                        'SUBSPECIES': 'Subspecies',
                        'VARIETY': 'Varieties',
                        '': 'All names'
                      }.entries)
                        ChoiceChip(
                            label: Text(rank.value),
                            selected: _rank == rank.key,
                            onSelected: (_) {
                              _rank = rank.key;
                              _debounce?.cancel();
                              _search();
                            }),
                    ]),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include synonyms and older names'),
                        value: !_accepted,
                        onChanged: (v) {
                          _accepted = !v;
                          _debounce?.cancel();
                          _search();
                        }),
                  ],
                  if (_libraryError != null) Text(_libraryError!),
                  const SizedBox(height: 20),
                  Text(
                      _savedOnly
                          ? '${items.length} saved world plants'
                          : _collection == 'All plants'
                              ? '${_count(_total)} matching botanical records'
                              : '${items.length} plants discovered ? $_collection',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (_loading) const LinearProgressIndicator(value: .35),
                  if (_error != null && _items.isEmpty)
                    EmptyGarden(
                        title: 'A little connection break.',
                        message: _error!,
                        action: 'Retry catalogue',
                        onAction: () => _search(more: _items.isNotEmpty)),
                  if (!_loading &&
                      _error == null &&
                      items.isEmpty &&
                      downloaded.isEmpty)
                    EmptyGarden(
                        title: _savedOnly
                            ? 'Your world collection starts here.'
                            : 'Try another botanical name.',
                        message: _savedOnly
                            ? 'Save species to find them here on any device.'
                            : 'Try a scientific name or plant family.',
                        action: 'Explore species',
                        onAction: () {
                          _query.clear();
                          _collection = 'All plants';
                          _savedOnly = false;
                          _search();
                        }),
                ]))),
        if (downloaded.isNotEmpty) ...[
          SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 12, side, 0),
              sliver: SliverToBoxAdapter(
                  child: SectionHeading(
                      'Downloaded plants (${downloaded.length})'))),
          SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: side),
              sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 950 ? 3 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 295),
                  delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          PlantCard(downloaded[index], source: 'discover'),
                      childCount: downloaded.length))),
          SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 28, side, 0),
              sliver: const SliverToBoxAdapter(
                  child: SectionHeading('Explore online plants'))),
        ],
        SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: side),
            sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 950 ? 3 : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 295),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final plant = items[index];
                  void openPlant() => openPage(context, _detailsFor(plant));
                  return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SurfaceBox(
                          padding: EdgeInsets.zero,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WorldPlantPhoto(
                                    key: ValueKey('world-photo-${plant.key}'),
                                    plant: plant,
                                    priority: widget.searchTab,
                                    size: double.infinity,
                                    height: 160,
                                    onTap: openPlant),
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 8, 6, 0),
                                    child: Row(children: [
                                      Expanded(
                                          child: InkWell(
                                              onTap: openPlant,
                                              child: Text(plant.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall))),
                                      IconButton(
                                          tooltip: _saved.containsKey(plant.key)
                                              ? 'Remove ${plant.name} from world plants'
                                              : 'Save ${plant.name} to world plants',
                                          onPressed: _saving.contains(plant.key)
                                              ? null
                                              : () => _save(plant),
                                          icon: Icon(
                                              _saved.containsKey(plant.key)
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border)),
                                    ])),
                                Expanded(
                                    child: InkWell(
                                        onTap: openPlant,
                                        child: SizedBox(
                                            width: double.infinity,
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        12, 0, 12, 12),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          plant.family.isEmpty
                                                              ? 'Botanical record'
                                                              : plant.family,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      11)),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                          plant.rank
                                                              .toLowerCase(),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      10)),
                                                      if (plant.status !=
                                                          'ACCEPTED')
                                                        Text(
                                                            plant.status
                                                                .toLowerCase(),
                                                            maxLines: 1,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10)),
                                                    ]))))),
                              ])));
                }, childCount: items.length))),
        SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 12, side, 100),
            sliver: SliverToBoxAdapter(
                child: Column(children: [
              if (_loading && items.isNotEmpty)
                const LinearProgressIndicator(value: .35),
              if (_error != null && items.isNotEmpty)
                EmptyGarden(
                    title: 'A little connection break.',
                    message: _error!,
                    action: 'Retry catalogue',
                    onAction: () => _search(more: true)),
              if (!_savedOnly &&
                  !_hasMore &&
                  _offset >= 10000 &&
                  _collection == 'All plants')
                const Text(
                    'Search a genus, family, or name to explore further records.'),
              const SizedBox(height: 20),
              TextButton.icon(
                  onPressed: () => _source(context,
                      'https://www.gbif.org/species/search?kingdom_key=6'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Botanical data from GBIF')),
            ]))),
      ]);
    });
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('World catalogue')), body: body);
  }
}

Widget _detailsFor(WorldPlant plant) {
  for (final profile in plants) {
    if (profile.botanical.toLowerCase() == plant.name.toLowerCase()) {
      return PlantDetailsScreen(plant: profile);
    }
  }
  return WorldPlantDetails(plant: plant);
}

Future<void> _source(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {}
  if (context.mounted) {
    showMessage(context, 'Could not open the botanical source.');
  }
}

class WorldPlantDetails extends StatefulWidget {
  const WorldPlantDetails({super.key, required this.plant});
  final WorldPlant plant;
  @override
  State<WorldPlantDetails> createState() => _WorldPlantDetailsState();
}

class _WorldPlantDetailsState extends State<WorldPlantDetails> {
  bool _busy = false;
  Future<void> _save() async {
    final state = AppScope.of(context);
    final uid = state.account?.id;
    if (uid == null) {
      showMessage(context, 'Sign in to save world plants.');
      return;
    }
    setState(() => _busy = true);
    try {
      await state.catalogueBackend
          .saveWorldPlant(uid, '${widget.plant.key}', widget.plant.toJson());
      if (mounted && state.account?.id == uid) {
        showMessage(context, 'Plant saved to your world collection.');
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not save this plant. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('World botanical catalogue'),
      const SizedBox(height: 12),
      Text(plant.name, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(plant.scientific,
          style: const TextStyle(fontStyle: FontStyle.italic)),
      const SizedBox(height: 22),
      Text(
          'Meet ${plant.name}, a member of ${plant.family.isEmpty ? 'the plant kingdom' : 'the ${plant.family} family'}. Explore its botanical identity, photographs and recorded observations.',
          style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 26),
      LayoutBuilder(builder: (_, constraints) {
        final columns = constraints.maxWidth >= 400 ? 2 : 1;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final field in {
            'Family': plant.family.isEmpty ? 'Not recorded' : plant.family,
            'Genus': plant.genus.isEmpty ? 'Not recorded' : plant.genus,
            'Rank': plant.rank.toLowerCase(),
            'Status': plant.status.toLowerCase(),
          }.entries)
            SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 12) / columns,
                child: SurfaceBox(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(
                          field.key == 'Family'
                              ? Icons.account_tree_outlined
                              : Icons.spa_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(field.key,
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(field.value,
                                style: Theme.of(context).textTheme.labelLarge),
                          ])),
                    ]))),
        ]);
      }),
      const SizedBox(height: 18),
      const Text(
          'Care requirements are not verified for this botanical record. Ask the guide about your space, climate and experience before choosing how to grow it.',
          style: TextStyle(fontSize: 11, height: 1.6)),
      const SizedBox(height: 24),
      PlantButton(
          label: 'Ask AI about this plant',
          icon: Icons.chat_bubble_outline,
          onPressed: () => openPage(
              context,
              PlantChatScreen(
                  plantContext:
                      '${plant.name} (${plant.scientific})\nGBIF identity only. Family: ${plant.family}; genus: ${plant.genus}. Care is not verified.'))),
      const SizedBox(height: 12),
      PlantButton(
          label: _busy ? 'Saving plant?' : 'Save to my world plants',
          icon: Icons.bookmark_border,
          onPressed: _busy ? null : _save),
      const SizedBox(height: 12),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
              onPressed: () => _source(context, plant.source),
              icon: const Icon(Icons.open_in_new, size: 19),
              label: const Text('View source & observations'))),
      if (plant.acceptedKey != null)
        TextButton(
            onPressed: () => _source(
                context, 'https://www.gbif.org/species/${plant.acceptedKey}'),
            child: const Text('View the accepted name')),
    ]);
    return Scaffold(
        appBar: AppBar(title: const Text('Meet your plant')),
        body: PlantProfile(
            photo: (height) =>
                WorldPlantPhoto(plant: plant, expanded: true, height: height),
            details: details,
            footer: [
              SurfaceBox(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('A little growing wisdom',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Text(
                                  'Start with identification, then check light, climate and growing conditions. Your AI guide can help you work through each step.'),
                            ])),
                      ])),
              const SizedBox(height: 20),
              const Text(
                  'Source: GBIF Taxonomic Backbone. Photo attribution appears with each available image.',
                  style: TextStyle(fontSize: 11)),
            ]));
  }
}

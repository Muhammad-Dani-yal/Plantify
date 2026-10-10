import 'package:flutter/material.dart';
import '../components/motion_icon.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'compare_plants.dart';
import 'plant_match.dart';
import 'world_catalogue.dart';
import '../services/world_catalogue.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen(
      {super.key, this.initialFilter = const PlantFilter(), this.catalogue});
  final WorldCatalogue? catalogue;
  final PlantFilter initialFilter;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  late PlantFilter _filter = widget.initialFilter;
  int _limit = 24;
  String _sort = 'Recommended';
  late bool _careOnly = widget.initialFilter.activeCount > 0;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(PlantFilter filter) => setState(() {
        _filter = filter;
        _limit = 24;
      });
  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PlantFilter>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _FilterSheet(initial: _filter));
    if (result != null && mounted) _update(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!_careOnly) {
      return WorldCatalogueScreen(
          catalogue: widget.catalogue,
          embedded: true,
          searchTab: true,
          onCareCollection: () => setState(() => _careOnly = true));
    }
    final state = AppScope.of(context);
    final matches =
        plants.where((p) => _filter.matches(p, _controller.text)).toList();
    if (_sort == 'Name A–Z') matches.sort((a, b) => a.name.compareTo(b.name));
    if (_sort == 'Easy care first') {
      matches.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    }
    return NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.depth == 0 &&
              event.metrics.extentAfter < 500 &&
              matches.length > _limit) {
            setState(() => _limit += 24);
          }
          return false;
        },
        child: PageBody(children: [
          const Eyebrow('The right plant, the right place'),
          const SizedBox(height: 10),
          Text('Find your green match.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(
              'Explore ${plants.length} care profiles, or discover species from around the world in the World catalogue.'),
          const SizedBox(height: 22),
          Wrap(spacing: 8, runSpacing: 8, children: [
            PlantButton(
                label: 'World plant catalogue',
                icon: Icons.public,
                onPressed: () => setState(() => _careOnly = false)),
            OutlinedButton.icon(
                onPressed: () => openPage(context, const PlantMatchScreen()),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Find my match')),
            if (state.comparison.isNotEmpty)
              OutlinedButton.icon(
                  onPressed: () =>
                      openPage(context, const ComparePlantsScreen()),
                  icon: const Icon(Icons.compare_arrows),
                  label: Text('Compare (${state.comparison.length})')),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: TextField(
                    key: const ValueKey('plant-search'),
                    controller: _controller,
                    onChanged: (_) => setState(() => _limit = 24),
                    decoration: InputDecoration(
                        hintText: 'Name, species, light, or collection',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _limit = 24);
                                },
                                icon: const Icon(Icons.close_rounded))))),
            const SizedBox(width: 10),
            IconButton.filled(
                tooltip: 'Search filters',
                onPressed: _openFilters,
                padding: const EdgeInsets.all(18),
                icon: Badge(
                    isLabelVisible: _filter.activeCount > 0,
                    label: Text('${_filter.activeCount}'),
                    child: const Icon(Icons.tune_rounded))),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final word in [
              'Low light',
              'Succulents',
              'Herbs',
              'Flowering',
              'Ferns'
            ])
              ActionChip(
                  avatar: MotionIcon(collectionIcon(word), size: 17),
                  label: Text(word),
                  onPressed: () {
                    _controller.text = word;
                    _update(const PlantFilter());
                  }),
          ]),
          const SizedBox(height: 16),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final type in ['All', 'Indoor', 'Outdoor'])
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          avatar: MotionIcon(collectionIcon(type), size: 17),
                          label: Text(type == 'All' ? 'All plants' : type),
                          showCheckmark: false,
                          selected: _filter.environment == type,
                          onSelected: (_) => _update(PlantFilter(
                              environment: type,
                              light: _filter.light,
                              water: _filter.water,
                              difficulty: _filter.difficulty,
                              category: _filter.category)))),
              ])),
          if (_filter.activeCount > 0)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final value in [
                        _filter.light,
                        _filter.water == 'All'
                            ? 'All'
                            : '${_filter.water} water',
                        _filter.difficulty,
                        _filter.category
                      ])
                        if (value != 'All') Chip(label: Text(value)),
                      TextButton(
                          onPressed: () => _update(const PlantFilter()),
                          child: const Text('Reset filters')),
                    ])),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: Text('${matches.length} plants to get to know',
                    style: Theme.of(context).textTheme.titleMedium)),
            PopupMenuButton<String>(
                tooltip: 'Sort plants',
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                      for (final v in [
                        'Recommended',
                        'Name A–Z',
                        'Easy care first'
                      ])
                        PopupMenuItem(value: v, child: Text(v))
                    ],
                icon: const Icon(Icons.sort_rounded)),
          ]),
          const SizedBox(height: 18),
          if (matches.isEmpty)
            EmptyGarden(
                title: 'No leaves turned up.',
                message:
                    'Try a different name or give your filters a little more room.',
                action: 'Clear search & filters',
                icon: Icons.search_off_rounded,
                onAction: () {
                  _controller.clear();
                  _update(const PlantFilter());
                })
          else
            PlantGrid(items: matches.take(_limit).toList(), source: 'search'),
        ]));
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final PlantFilter initial;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _environment = widget.initial.environment,
      _light = widget.initial.light,
      _water = widget.initial.water,
      _difficulty = widget.initial.difficulty,
      _category = widget.initial.category;
  Widget _group(String title, List<String> values, String current,
          ValueChanged<String> change) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final value in values)
                ChoiceChip(
                    label: Text(value),
                    selected: value == current,
                    onSelected: (_) => setState(() => change(value)))
            ]),
          ]));
  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text('Make it your match.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium)),
                          TextButton(
                              onPressed: () => setState(() {
                                    _environment = 'All';
                                    _light = 'All';
                                    _water = 'All';
                                    _difficulty = 'All';
                                    _category = 'All';
                                  }),
                              child: const Text('Reset')),
                        ]),
                        const SizedBox(height: 24),
                        _group('Your space', ['All', 'Indoor', 'Outdoor'],
                            _environment, (v) => _environment = v),
                        _group(
                            'Sunlight',
                            ['All', 'Low light', 'Indirect', 'Full sun'],
                            _light,
                            (v) => _light = v),
                        _group('Watering needs', ['All', 'Low', 'Moderate'],
                            _water, (v) => _water = v),
                        _group('Care difficulty', ['All', 'Easy', 'Moderate'],
                            _difficulty, (v) => _difficulty = v),
                        _group(
                            'Plant collection',
                            [
                              'All',
                              ...({...plants.map((p) => p.category)}.toList()
                                ..sort())
                            ],
                            _category,
                            (v) => _category = v),
                        PlantButton(
                            label: 'Show matching plants',
                            onPressed: () => Navigator.pop(
                                context,
                                PlantFilter(
                                    environment: _environment,
                                    light: _light,
                                    water: _water,
                                    difficulty: _difficulty,
                                    category: _category))),
                      ])))));
}

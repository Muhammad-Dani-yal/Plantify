import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'care_guide.dart';
import 'favorites.dart';
import 'my_plants.dart';
import 'plant_details.dart';
import 'profile.dart';
import 'search.dart';
import 'plant_match.dart';
import 'world_catalogue.dart';
import 'plant_chat.dart';
import 'dart:math';
import '../components/motion_icon.dart';
import '../services/world_catalogue.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.catalogue});
  final WorldCatalogue? catalogue;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _contentKey = GlobalKey();
  late final WorldCatalogue _catalogue = widget.catalogue ?? WorldCatalogue();
  @override
  void dispose() {
    if (widget.catalogue == null) _catalogue.close();
    super.dispose();
  }

  int _index = 0;
  PlantFilter _searchFilter = const PlantFilter();
  int _searchVersion = 0;
  void _collection(PlantFilter filter) => setState(() {
        _searchFilter = filter;
        _searchVersion++;
        _index = 1;
      });
  void _select(int i) => setState(() => _index = i);
  static const _destinations = [
    NavigationDestination(
        icon: MotionIcon(Icons.explore_outlined),
        selectedIcon: MotionIcon(Icons.explore_rounded),
        label: 'Discover'),
    NavigationDestination(
        icon: MotionIcon(Icons.search_rounded), label: 'Search'),
    NavigationDestination(
        icon: MotionIcon(Icons.favorite_border_rounded),
        selectedIcon: MotionIcon(Icons.favorite_rounded),
        label: 'Favorites'),
    NavigationDestination(
        icon: MotionIcon(Icons.spa_outlined),
        selectedIcon: MotionIcon(Icons.spa_rounded),
        label: 'My Plants'),
    NavigationDestination(
        icon: MotionIcon(Icons.person_outline_rounded),
        selectedIcon: MotionIcon(Icons.person_rounded),
        label: 'Profile'),
  ];
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final pages = [
      WorldCatalogueScreen(
          catalogue: _catalogue,
          embedded: true,
          onCareCollection: () => openPage(
              context,
              Scaffold(
                  appBar: AppBar(title: const Text('Care collection')),
                  body: DiscoverScreen(onSearch: () {
                    Navigator.pop(context);
                    _select(1);
                  }, onCollection: (filter) {
                    Navigator.pop(context);
                    _collection(filter);
                  })))),
      SearchScreen(
          key: ValueKey(_searchVersion),
          initialFilter: _searchFilter,
          catalogue: _catalogue),
      FavoritesScreen(onDiscover: () => _select(0)),
      MyPlantsScreen(onDiscover: () => _select(1)),
      const ProfileScreen(),
    ];
    final content = KeyedSubtree(
        key: _contentKey,
        child: Column(children: [
          if (state.storageError != null)
            MaterialBanner(content: Text(state.storageError!), actions: [
              TextButton(onPressed: state.retrySync, child: const Text('Retry'))
            ]),
          if (state.cloudLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
              child: IndexedStack(index: _index, children: [
            for (var i = 0; i < pages.length; i++)
              TickerMode(enabled: _index == i, child: pages[i]),
          ])),
        ]));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => openPage(context, const PlantChatScreen()),
          icon: const MotionIcon(Icons.auto_awesome, size: 20, live: true),
          label: const Text('AI guide')),
      appBar: wide
          ? null
          : AppBar(
              toolbarHeight: 76,
              titleSpacing: 20,
              title: const FittedBox(fit: BoxFit.scaleDown, child: Wordmark()),
              actions: [
                  Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: IconButton.filledTonal(
                          tooltip: 'Open profile',
                          onPressed: () => _select(4),
                          icon: Text(
                              state.name.isEmpty
                                  ? 'P'
                                  : state.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))))
                ]),
      body: SafeArea(
          top: wide,
          child: wide
              ? Row(children: [
                  Container(
                      width: 220,
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest,
                          border: Border(
                              right: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: .5)))),
                      child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 8),
                                                child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Wordmark())),
                                            const SizedBox(height: 48),
                                            const Padding(
                                                padding: EdgeInsets.only(
                                                    left: 12, bottom: 16),
                                                child: Eyebrow(
                                                    'Your green space')),
                                            for (var i = 0;
                                                i < _destinations.length;
                                                i++)
                                              Padding(
                                                  padding: const EdgeInsets.only(
                                                      bottom: 8),
                                                  child: ListTile(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  16)),
                                                      selected: _index == i,
                                                      selectedTileColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondaryContainer,
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      leading:
                                                          _destinations[i].icon,
                                                      title: Text(_destinations[i].label,
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight.w700)),
                                                      onTap: () => _select(i))),
                                            const SizedBox(height: 40),
                                            SurfaceBox(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondaryContainer,
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .wb_sunny_outlined,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary),
                                                      const SizedBox(
                                                          height: 12),
                                                      const Text(
                                                          'Grow at your\nown pace.',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'DMSerifDisplay',
                                                              fontSize: 24,
                                                              height: 1.2)),
                                                      const SizedBox(
                                                          height: 12),
                                                      const Text(
                                                          'A little care goes a long way.',
                                                          style: TextStyle(
                                                              fontSize: 11)),
                                                      TextButton(
                                                          onPressed: () => openPage(
                                                              context,
                                                              const CareGuideScreen()),
                                                          child: const Text(
                                                              'Care essentials →')),
                                                    ])),
                                            const SizedBox(height: 20),
                                            ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                leading: CircleAvatar(
                                                    backgroundColor:
                                                        Botanical.lime,
                                                    foregroundColor:
                                                        Botanical.forest,
                                                    child: Text(state
                                                            .name.isEmpty
                                                        ? 'P'
                                                        : state.name[0]
                                                            .toUpperCase())),
                                                title: Text(state.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 12)),
                                                subtitle: const Text(
                                                    'Your growing space',
                                                    style: TextStyle(
                                                        fontSize: 10)),
                                                onTap: () => _select(4)),
                                          ]))))),
                  Expanded(child: content),
                ])
              : content),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              height: 76,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLowest,
              indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
              labelTextStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              destinations: _destinations),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen(
      {super.key, required this.onSearch, required this.onCollection});
  final VoidCallback onSearch;
  final ValueChanged<PlantFilter> onCollection;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _category = 'All plants';
  int _limit = 8;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = plants
        .where((p) =>
            _category == 'All plants' ||
            p.environment == _category ||
            p.category == _category ||
            (_category == 'Easy care' && p.difficulty == 'Easy'))
        .toList();
    return NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.depth == 0 &&
              event.metrics.extentAfter < 500 &&
              selected.length > _limit) {
            setState(() => _limit += 16);
          }
          return false;
        },
        child: PageBody(children: [
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Eyebrow('A greener everyday, ${state.name.split(' ').first}'),
                  const SizedBox(height: 10),
                  Text('Make room for\na little green.',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text('Find a plant you’ll love. Learn to help it thrive.',
                      style: Theme.of(context).textTheme.bodyLarge),
                ])),
            if (MediaQuery.sizeOf(context).width > 600)
              Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: OutlinedButton.icon(
                      onPressed: widget.onSearch,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Find your plant'))),
          ]),
          const SizedBox(height: 26),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final collection in const {
              'Fruit plants': 'Citrus',
              'Everyday plants': 'Ficus',
              'Unique plants': 'Welwitschia'
            }.entries)
              ActionChip(
                  avatar: MotionIcon(collectionIcon(collection.key), size: 18),
                  label: Text(collection.key),
                  onPressed: () => openPage(context,
                      WorldCatalogueScreen(initialQuery: collection.value))),
            ActionChip(
                avatar: const MotionIcon(Icons.public, size: 17),
                label: const Text('World plant catalogue'),
                onPressed: () =>
                    openPage(context, const WorldCatalogueScreen())),
            ActionChip(
                avatar:
                    const MotionIcon(Icons.local_florist_outlined, size: 17),
                label: Text('${plants.length} care profiles'),
                onPressed: widget.onSearch),
            ActionChip(
                avatar: const MotionIcon(Icons.auto_awesome_outlined, size: 17),
                label: const Text('Find my match'),
                onPressed: () => openPage(context, const PlantMatchScreen())),
            ActionChip(
                avatar: const MotionIcon(Icons.shuffle_rounded, size: 17),
                label: const Text('Surprise me'),
                onPressed: () => openPage(
                    context,
                    PlantDetailsScreen(
                        plant: plants[Random().nextInt(plants.length)]))),
          ]),
          const SizedBox(height: 20),
          if (MediaQuery.sizeOf(context).width <= 600) ...[
            InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onSearch,
                child: SurfaceBox(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(Icons.search_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('Search plants, find your match…')),
                      const Icon(Icons.tune_rounded, size: 20),
                    ]))),
            const SizedBox(height: 24),
          ],
          LayoutBuilder(builder: (_, constraints) {
            final wide = constraints.maxWidth > 740;
            final hero = ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                    height: constraints.maxWidth < 400 ? 620 : 480,
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset('assets/botanical/greenhouse-hero.webp',
                          fit: BoxFit.cover, alignment: Alignment.centerRight),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                            Color(0xF0183F32),
                            Color(0x93183F32),
                            Color(0x00183F32)
                          ],
                                  stops: [
                            0,
                            .5,
                            1
                          ]))),
                      Padding(
                          padding: const EdgeInsets.all(26),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 7),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: .12),
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    child: const Eyebrow('Plant of the moment',
                                        color: Botanical.lime)),
                                const SizedBox(height: 18),
                                const Text('Meet your new\ngreen obsession.',
                                    style: TextStyle(
                                        fontFamily: 'DMSerifDisplay',
                                        color: Colors.white,
                                        fontSize: 34,
                                        height: 1.12)),
                                const SizedBox(height: 12),
                                const Text(
                                    'Monstera deliciosa\nBig leaves. Bigger personality.',
                                    style: TextStyle(
                                        color: Color(0xFFDEE7DC),
                                        fontSize: 12,
                                        height: 1.7)),
                                const SizedBox(height: 20),
                                SizedBox(
                                    width: 174,
                                    child: PlantButton(
                                        label: 'Meet Monstera',
                                        accent: true,
                                        onPressed: () => openPage(
                                            context,
                                            PlantDetailsScreen(
                                                plant: plants.first)))),
                              ])),
                    ])));
            final guide = Container(
                height: 480,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(28)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('A little plant wisdom'),
                      const Spacer(),
                      BrandMark(
                          size: 56,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 20),
                      Text('Happy plants,\nsimple habits.',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      const Text(
                          'Start with light, a soil check, and a little patience.'),
                      const Spacer(),
                      OutlinedButton.icon(
                          onPressed: () =>
                              openPage(context, const CareGuideScreen()),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('Explore care guides')),
                    ]));
            return wide
                ? Row(children: [
                    Expanded(flex: 7, child: hero),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: guide)
                  ])
                : hero;
          }),
          const SizedBox(height: 30),
          SectionHeading('Find your kind of green',
              action: 'View all', onAction: widget.onSearch),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                'All plants',
                'Indoor',
                'Outdoor',
                'Easy care',
                'Trailing'
              ]
                      .map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              avatar: MotionIcon(collectionIcon(category),
                                  size: 17),
                              label: Text(category),
                              selected: _category == category,
                              showCheckmark: false,
                              onSelected: (_) => setState(() {
                                    _category = category;
                                    _limit = 8;
                                  }))))
                      .toList())),
          const SizedBox(height: 24),
          PlantGrid(items: selected.take(_limit).toList(), source: 'discover'),
          const SizedBox(height: 30),
          const SectionHeading('Little worlds worth exploring'),
          LayoutBuilder(builder: (_, c) {
            final width =
                c.maxWidth >= 680 ? (c.maxWidth - 32) / 3 : c.maxWidth;
            final collections = [
              (
                'Desert daydreams',
                'Succulents',
                Botanical.peach,
                Icons.wb_sunny_outlined
              ),
              (
                'A kitchen full of green',
                'Herbs',
                Botanical.sage,
                Icons.restaurant_outlined
              ),
              (
                'A little colour therapy',
                'Flowering',
                Botanical.lavender,
                Icons.local_florist_outlined
              ),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: [
              for (final item in collections)
                SizedBox(
                    width: width,
                    child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () =>
                            widget.onCollection(PlantFilter(category: item.$2)),
                        child: SurfaceBox(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? null
                                    : item.$3,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MotionIcon(item.$4,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(height: 18),
                                  Text(item.$1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${plants.where((p) => p.category == item.$2).length} plants · Explore collection'),
                                ]))))
            ]);
          }),
          const SizedBox(height: 32),
          SectionHeading('Easy starts. Beautiful companions.',
              action: 'Explore', onAction: widget.onSearch),
          SurfaceBox(
              child: Row(children: [
            Container(
                width: 70,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: PlantPhoto(plants[1])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('New to plants? Start here.',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                      'Snake plant, pothos, and peperomia are forgiving first companions.'),
                ])),
            IconButton(
                tooltip: 'Open snake plant',
                onPressed: () =>
                    openPage(context, PlantDetailsScreen(plant: plants[1])),
                icon: const Icon(Icons.arrow_forward_rounded)),
          ])),
          const SizedBox(height: 30),
          const SectionHeading('A little care, a lot of growth'),
          InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => openPage(context, const CareGuideScreen()),
              child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Botanical.forest,
                      borderRadius: BorderRadius.circular(24)),
                  child: const Row(children: [
                    Icon(Icons.water_drop_outlined,
                        color: Botanical.lime, size: 30),
                    SizedBox(width: 18),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Water with intention.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text(
                              'Check the soil before the calendar. Your plants will thank you.',
                              style: TextStyle(
                                  color: Color(0xFFD8E2D5),
                                  fontSize: 12,
                                  height: 1.6)),
                        ])),
                    Icon(Icons.arrow_outward_rounded, color: Botanical.lime),
                  ]))),
          const SizedBox(height: 28),
          const Center(child: Eyebrow('Small steps. Strong roots.')),
        ]));
  }
}

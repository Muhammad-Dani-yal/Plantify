import 'package:flutter/material.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'world_catalogue.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onDiscover});
  final VoidCallback onDiscover;
  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).favorites;
    final items = plants.where((p) => saved.contains(p.id)).toList();
    return PageBody(children: [
      const Eyebrow('Your green wish list'),
      const SizedBox(height: 10),
      Text('Love at first leaf.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      Text(
          '${items.length} saved ${items.length == 1 ? 'plant' : 'plants'}. A little inspiration for your next green chapter.'),
      const SizedBox(height: 28),
      PlantButton(
          label: 'My saved world plants',
          icon: Icons.public,
          onPressed: () =>
              openPage(context, const WorldCatalogueScreen(savedOnly: true))),
      const SizedBox(height: 20),
      if (items.isEmpty)
        EmptyGarden(
            title: 'Save a little inspiration.',
            message:
                'Tap the heart on a plant you love. Your favourites will be right here, ready on any device you sign in to.',
            action: 'Discover plants',
            icon: Icons.favorite_border_rounded,
            onAction: onDiscover)
      else
        PlantGrid(items: items, source: 'favorites'),
    ]);
  }
}

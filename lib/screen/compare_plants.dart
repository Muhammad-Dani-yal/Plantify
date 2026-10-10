import 'package:flutter/material.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';

class ComparePlantsScreen extends StatelessWidget {
  const ComparePlantsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = plants.where((p) => state.comparison.contains(p.id)).toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Compare your plants')),
        body: PageBody(children: [
          const Eyebrow('A little side-by-side inspiration'),
          const SizedBox(height: 10),
          Text('Which green fits you?',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          const Text(
              'Add up to three plants from their details to compare care needs. Swipe sideways on small screens.'),
          const SizedBox(height: 24),
          if (items.isEmpty)
            EmptyGarden(
                title: 'Find a few favourites first.',
                message: 'Open a plant and tap Compare plant to add it here.',
                action: 'Back to exploring',
                onAction: () => Navigator.pop(context)),
          if (items.isNotEmpty)
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final plant in items)
                        Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: SizedBox(
                                width: 260,
                                child: SurfaceBox(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: SizedBox(
                                              height: 220,
                                              child: PlantPhoto(plant))),
                                      const SizedBox(height: 16),
                                      Text(plant.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(plant.botanical,
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 11)),
                                      const SizedBox(height: 18),
                                      for (final fact in [
                                        ('Space', plant.environment),
                                        ('Light', plant.light),
                                        ('Water needs', plant.water),
                                        ('Care level', plant.difficulty),
                                        (
                                          'Soil check',
                                          '~${plant.waterDays} days'
                                        )
                                      ]) ...[
                                        Text(fact.$1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(fact.$2),
                                        const Divider(height: 24),
                                      ],
                                      TextButton.icon(
                                          onPressed: () =>
                                              state.toggleCompare(plant.id),
                                          icon: const Icon(Icons.close_rounded),
                                          label: const Text(
                                              'Remove from comparison')),
                                    ]))))
                    ])),
        ]));
  }
}

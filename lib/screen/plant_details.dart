import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../components/plant_profile.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'care_guide.dart';
import 'compare_plants.dart';
import 'plant_chat.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantDetailsScreen extends StatelessWidget {
  const PlantDetailsScreen({super.key, required this.plant, this.heroTag});
  final Plant plant;
  final String? heroTag;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final inGarden = state.garden.containsKey(plant.id);
    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Eyebrow('${plant.environment} / ${plant.category}'),
      const SizedBox(height: 12),
      Text(plant.name, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(plant.botanical,
          style: const TextStyle(fontStyle: FontStyle.italic)),
      const SizedBox(height: 22),
      Text(plant.description, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 26),
      LayoutBuilder(builder: (_, c) {
        final count = c.maxWidth >= 400 ? 2 : 1;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CareFact(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Sunlight',
                  value: plant.light),
              _CareFact(
                  icon: Icons.water_drop_outlined,
                  label: 'Watering',
                  value: 'Check ~${plant.waterDays} days'),
              _CareFact(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: plant.temperature),
              _CareFact(
                  icon: Icons.spa_outlined,
                  label: 'Care level',
                  value: plant.difficulty),
            ]
                .map((child) => SizedBox(
                    width: (c.maxWidth - (count - 1) * 12) / count,
                    child: child))
                .toList());
      }),
      const SizedBox(height: 18),
      const Text(
          'Watering intervals are check-in suggestions. Water only when the soil needs it; seasons and your room make a difference.',
          style: TextStyle(fontSize: 11, height: 1.6)),
      const SizedBox(height: 24),
      PlantButton(
          label: 'Ask AI about this plant',
          icon: Icons.chat_bubble_outline,
          onPressed: () => openPage(
              context,
              PlantChatScreen(
                  plantContext:
                      '${plant.name} (${plant.botanical})\nCare profile: light ${plant.light}; soil ${plant.soil}; ${plant.tip}'))),
      const SizedBox(height: 12),
      PlantButton(
          label: inGarden ? 'Added to My Plants' : 'Add to My Plants',
          icon: inGarden ? Icons.check_rounded : Icons.add_rounded,
          onPressed: inGarden
              ? null
              : () {
                  state.addPlant(plant.id);
                  showMessage(context,
                      '${plant.name} joined your garden. Find it in My Plants.');
                }),
      const SizedBox(height: 12),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
              onPressed: () => openPage(context, CareGuideScreen(plant: plant)),
              icon: const Icon(Icons.menu_book_outlined, size: 19),
              label: const Text('Read the care guide'))),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            onPressed: () {
              try {
                state.toggleCompare(plant.id);
              } on StateError catch (error) {
                showMessage(context, error.message.toString());
              }
            },
            icon: const Icon(Icons.compare_arrows_rounded),
            label: Text(state.comparison.contains(plant.id)
                ? 'Remove comparison'
                : 'Compare plant')),
        if (state.comparison.isNotEmpty)
          TextButton(
              onPressed: () => openPage(context, const ComparePlantsScreen()),
              child: Text('Compare (${state.comparison.length})')),
      ]),
    ]);
    return Scaffold(
        appBar: AppBar(title: const Text('Meet your plant'), actions: [
          Padding(
              padding: const EdgeInsets.only(right: 14),
              child: FavoriteButton(plant)),
        ]),
        body: PlantProfile(
            photo: (height) => SizedBox(
                height: height, child: PlantPhoto(plant, heroTag: heroTag)),
            details: details,
            footer: [
              if (plant.imageCredit.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Photo: ${plant.imageCredit}',
                              style: const TextStyle(fontSize: 10)),
                          TextButton.icon(
                              onPressed: () async {
                                final opened = await launchUrl(
                                    Uri.parse(plant.imageSource));
                                if (!opened && context.mounted) {
                                  showMessage(context,
                                      'Could not open the photo source.');
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded,
                                  size: 14),
                              label: const Text('Photo source & licence')),
                        ])),
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
                              Text(plant.tip),
                            ])),
                      ])),
              const SizedBox(height: 26),
              const SectionHeading('You might also love'),
              PlantGrid(
                  items: plants
                      .where((p) =>
                          p.id != plant.id &&
                          (p.category == plant.category ||
                              p.light == plant.light))
                      .take(4)
                      .toList(),
                  source: 'related-${plant.id}'),
            ]));
  }
}

class _CareFact extends StatelessWidget {
  const _CareFact(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => SurfaceBox(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Botanical.sage, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 21, color: Botanical.forest)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ])),
      ]));
}

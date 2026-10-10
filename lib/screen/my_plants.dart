import 'package:flutter/material.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'plant_details.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key, required this.onDiscover});
  final VoidCallback onDiscover;

  Future<void> _notes(BuildContext context, GardenEntry entry) async {
    final state = AppScope.of(context);
    var notes = entry.notes;
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('${plantById(entry.plantId).name} notes'),
              content: TextFormField(
                  initialValue: notes,
                  onChanged: (value) => notes = value,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                      hintText: 'What helps your plant thrive?')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, notes),
                    child: const Text('Save notes'))
              ],
            ));
    if (result != null) state.saveNotes(entry.plantId, result);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final due = state.garden.values
        .where((e) =>
            e.lastWatered == null ||
            DateTime.now().difference(e.lastWatered!).inDays >=
                plantById(e.plantId).waterDays)
        .length;
    return PageBody(children: [
      const Eyebrow('Your own little urban jungle'),
      const SizedBox(height: 10),
      Text('Growing together.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      const Text(
          'Keep care notes and record watering for the plants you grow.'),
      const SizedBox(height: 24),
      if (state.garden.isNotEmpty) ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(
              avatar: const Icon(Icons.spa_outlined, size: 17),
              label: Text('${state.garden.length} growing companions')),
          Chip(
              avatar: const Icon(Icons.water_drop_outlined, size: 17),
              label: Text('$due soil checks to consider')),
        ]),
        const SizedBox(height: 12),
        const Text(
            'Check-in timing is a guide. Check the soil before you water.'),
        const SizedBox(height: 20),
      ],
      if (state.garden.isEmpty)
        EmptyGarden(
            title: 'Your garden starts with one plant.',
            message:
                'Find a plant and add it to My Plants. Your collection and care notes sync with your account.',
            action: 'Find a plant',
            onAction: onDiscover),
      for (final entry in state.garden.values) ...[
        SurfaceBox(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                  width: 56,
                  height: 64,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PlantPhoto(plantById(entry.plantId)))),
              title: Text(plantById(entry.plantId).name),
              subtitle: Text(plantById(entry.plantId).botanical),
              onTap: () => openPage(context,
                  PlantDetailsScreen(plant: plantById(entry.plantId)))),
          const SizedBox(height: 12),
          if (entry.lastWatered == null ||
              DateTime.now().difference(entry.lastWatered!).inDays >=
                  plantById(entry.plantId).waterDays)
            const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Chip(
                    avatar: Icon(Icons.visibility_outlined, size: 16),
                    label: Text('Time for a soil check'))),
          Text(entry.lastWatered == null
              ? 'No watering recorded yet.'
              : 'Last watered: ${MaterialLocalizations.of(context).formatMediumDate(entry.lastWatered!)}'),
          if (state.careHints)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(plantById(entry.plantId).tip)),
          if (entry.notes.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(entry.notes)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: () {
                  state.markWatered(entry.plantId);
                  showMessage(context,
                      'Watering recorded. Check the soil before watering again.');
                },
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Record watering')),
            OutlinedButton.icon(
                onPressed: () => _notes(context, entry),
                icon: const Icon(Icons.edit_note),
                label: const Text('Care notes')),
            TextButton(
                onPressed: () async {
                  final remove = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text('Remove from My Plants?'),
                              content: const Text(
                                  'This will remove its care notes and watering record.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Keep plant')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Remove'))
                              ]));
                  if (remove == true) state.removePlant(entry.plantId);
                },
                child: const Text('Remove plant')),
          ]),
        ])),
        const SizedBox(height: 18),
      ],
    ]);
  }
}

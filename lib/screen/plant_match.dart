import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';

class PlantMatchScreen extends StatefulWidget {
  const PlantMatchScreen({super.key});
  @override
  State<PlantMatchScreen> createState() => _PlantMatchScreenState();
}

class _PlantMatchScreenState extends State<PlantMatchScreen> {
  String _space = 'Indoor', _light = 'Indirect', _care = 'Easy';
  bool _show = false;
  Widget _choices(String title, List<String> choices, String selected,
          ValueChanged<String> choose) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final choice in choices)
            ChoiceChip(
                label: Text(choice),
                selected: selected == choice,
                onSelected: (_) => setState(() {
                      choose(choice);
                      _show = false;
                    }))
        ]),
        const SizedBox(height: 24),
      ]);
  @override
  Widget build(BuildContext context) {
    final filter =
        PlantFilter(environment: _space, light: _light, difficulty: _care);
    final matches = plants.where((p) => filter.matches(p, '')).toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Find your plant match')),
        body: PageBody(maxWidth: 900, children: [
          const Eyebrow('A plant that fits your everyday'),
          const SizedBox(height: 10),
          Text('Your space. Your pace.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          const Text(
              'Three little choices to find a green companion. These matches use the plants’ light and care needs.'),
          const SizedBox(height: 24),
          SurfaceBox(
              color: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Botanical.peach,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _choices('Where will your plant live?',
                        ['Indoor', 'Outdoor'], _space, (v) => _space = v),
                    _choices(
                        'What light can you offer?',
                        ['Low light', 'Indirect', 'Full sun'],
                        _light,
                        (v) => _light = v),
                    _choices('How much care feels right?',
                        ['Easy', 'Moderate', 'All'], _care, (v) => _care = v),
                    PlantButton(
                        label: 'Show my matches',
                        accent: true,
                        onPressed: () => setState(() => _show = true)),
                  ])),
          if (_show) ...[
            const SizedBox(height: 28),
            SectionHeading('${matches.length} plants for your green chapter'),
            if (matches.isEmpty)
              EmptyGarden(
                  title: 'Let’s give your match more room.',
                  message:
                      'Try a different light level or include both care levels.',
                  action: 'Include all care levels',
                  onAction: () => setState(() => _care = 'All'))
            else
              PlantGrid(items: matches, source: 'match'),
          ],
        ]));
  }
}

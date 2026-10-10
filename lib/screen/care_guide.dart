import 'package:flutter/material.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';

class CareGuideScreen extends StatelessWidget {
  const CareGuideScreen({super.key, this.plant});
  final Plant? plant;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                plant == null ? 'Care essentials' : '${plant!.name} care')),
        body: PageBody(maxWidth: 760, children: [
          const Eyebrow('Small habits, happy plants'),
          const SizedBox(height: 12),
          Text('Help your green grow.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          for (final item in <(String, String)>[
            (
              'Find the right light',
              plant?.light ??
                  'Choose a spot that matches your plant. Bright indirect light means a bright room without harsh direct sun.'
            ),
            (
              'Check before you water',
              plant == null
                  ? 'Feel the soil first. Watering needs change with light, temperature, season, and pot size. Let excess water drain away.'
                  : 'Check the soil about every ${plant!.waterDays} days. This is a check-in suggestion, not an automatic watering schedule.'
            ),
            (
              'Give roots room to breathe',
              plant?.soil ??
                  'Use a pot with drainage holes and a suitable, airy potting mix. Avoid leaving roots in standing water.'
            ),
            (
              'A comfortable place',
              plant?.temperature ??
                  'Keep indoor plants away from cold drafts and heaters. Rotate pots occasionally for even growth.'
            ),
            (
              'A little extra care',
              plant?.tip ??
                  'Check leaves regularly, remove damaged foliage, and keep notes as you learn what works in your space.'
            ),
          ]) ...[
            SurfaceBox(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(item.$2),
                ])),
            const SizedBox(height: 16),
          ],
        ]),
      );
}

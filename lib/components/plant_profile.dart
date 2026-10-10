import 'package:flutter/material.dart';
import 'botanical_widgets.dart';

/// Shared responsive presentation for curated and worldwide plant profiles.
class PlantProfile extends StatelessWidget {
  const PlantProfile(
      {super.key,
      required this.photo,
      required this.details,
      this.footer = const []});
  final Widget Function(double height) photo;
  final Widget details;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) => PageBody(children: [
        LayoutBuilder(builder: (_, constraints) {
          final wide = constraints.maxWidth > 760;
          final art = ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: photo(wide ? 590 : 360));
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: art),
                  const SizedBox(width: 44),
                  Expanded(child: details)
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [art, const SizedBox(height: 28), details]);
        }),
        const SizedBox(height: 32),
        ...footer,
      ]);
}

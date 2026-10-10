import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/world_plant.dart';
import '../services/world_photos.dart';
import 'botanical_widgets.dart';

class WorldPlantPhoto extends StatefulWidget {
  const WorldPlantPhoto(
      {super.key,
      required this.plant,
      this.size = 76,
      this.height,
      this.onTap,
      this.priority = false,
      this.expanded = false,
      this.photos});
  final WorldPlant plant;
  final double size;
  final double? height;
  final VoidCallback? onTap;
  final bool priority;
  final bool expanded;
  final WorldPhotos? photos;
  @override
  State<WorldPlantPhoto> createState() => _WorldPlantPhotoState();
}

class _WorldPlantPhotoState extends State<WorldPlantPhoto> {
  late Future<WorldPhoto?> _photo;
  bool _watching = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _watching = true;
    _photo = (widget.photos ?? WorldPhotos.shared)
        .watch(widget.plant, priority: widget.priority || widget.expanded);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.of(context);
    if (!active && _watching) {
      (widget.photos ?? WorldPhotos.shared).release(widget.plant);
      _watching = false;
    } else if (active && !_watching) {
      _load();
    }
  }

  @override
  void didUpdateWidget(WorldPlantPhoto old) {
    super.didUpdateWidget(old);
    if (old.plant.key != widget.plant.key || old.photos != widget.photos) {
      if (_watching) {
        (old.photos ?? WorldPhotos.shared).release(old.plant);
        _load();
      } else {
        _photo = Future.value(null);
      }
    }
  }

  @override
  void dispose() {
    if (_watching) {
      (widget.photos ?? WorldPhotos.shared).release(widget.plant);
    }
    super.dispose();
  }

  Widget _placeholder(BuildContext context) => Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: BrandMark(
          size: widget.expanded ? 58 : 32,
          color: Theme.of(context).colorScheme.primary));
  Future<void> _source(String url) async {
    if (!await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication) &&
        mounted) {
      showMessage(context, 'The photo source could not open.');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorldPhoto?>(
      future: _photo,
      builder: (context, snapshot) {
        final photo = snapshot.data;
        final fit = widget.expanded ? BoxFit.contain : BoxFit.cover;
        final image = photo == null
            ? _placeholder(context)
            : photo.asset != null
                ? Image.asset(photo.asset!,
                    fit: fit,
                    errorBuilder: (_, __, ___) => _placeholder(context))
                : photo.url != null
                    ? Image.network(photo.url!,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: fit,
                        errorBuilder: (_, __, ___) => _placeholder(context))
                    : Image.memory(photo.bytes!,
                        fit: fit,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => _placeholder(context));
        final picture = Semantics(
            image: true,
            label: photo == null
                ? 'Photo unavailable for ${widget.plant.name}'
                : 'Plant photo: ${widget.plant.name}',
            child: ClipRRect(
                borderRadius: widget.size == double.infinity && !widget.expanded
                    ? const BorderRadius.vertical(top: Radius.circular(24))
                    : BorderRadius.circular(24),
                child: SizedBox(
                    width: widget.expanded ? double.infinity : widget.size,
                    height:
                        widget.height ?? (widget.expanded ? 250 : widget.size),
                    child: Stack(fit: StackFit.expand, children: [
                      ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest),
                      image,
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(
                                value: .35, minHeight: 2)),
                    ]))));
        if (!widget.expanded) {
          return Tooltip(
              message: photo == null
                  ? 'Photo unavailable'
                  : '${photo.credit} · Photo credits',
              child: InkWell(
                  onTap: widget.onTap ??
                      (photo == null
                          ? null
                          : () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => SafeArea(
                                  child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: WorldPlantPhoto(
                                          plant: widget.plant,
                                          expanded: true,
                                          photos: widget.photos))))),
                  child: picture));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          picture,
          const SizedBox(height: 8),
          if (photo == null)
            Text(snapshot.connectionState == ConnectionState.waiting
                ? 'Finding a plant photograph…'
                : 'No reusable photograph available yet.'),
          if (photo != null) ...[
            Text('Photo / illustration: ${photo.credit}',
                style: const TextStyle(fontSize: 12)),
            Wrap(spacing: 10, children: [
              TextButton(
                  onPressed: () => _source(photo.source),
                  child: const Text('Photo source & credits')),
              if (photo.license.isNotEmpty)
                TextButton(
                    onPressed: () => _source(photo.license),
                    child: Text(photo.license.contains('/by-sa/')
                        ? 'CC BY-SA'
                        : photo.license.contains('/zero/')
                            ? 'CC0'
                            : 'CC BY')),
            ]),
          ],
        ]);
      });
}

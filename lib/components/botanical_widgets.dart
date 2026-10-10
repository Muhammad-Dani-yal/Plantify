import 'package:flutter/material.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import '../screen/plant_details.dart';
import 'app_theme.dart';

Route<T> botanicalRoute<T>(Widget page, {bool reducedMotion = false}) =>
    PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: reducedMotion ? 0 : 380),
      reverseTransitionDuration:
          Duration(milliseconds: reducedMotion ? 0 : 280),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
              position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
              child: child)),
    );

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(botanicalRoute<T>(page,
        reducedMotion: MediaQuery.disableAnimationsOf(context)));

void replaceWith(BuildContext context, Widget page) =>
    Navigator.of(context).pushAndRemoveUntil(
        botanicalRoute<void>(page,
            reducedMotion: MediaQuery.disableAnimationsOf(context)),
        (_) => false);

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42, this.color, this.backdrop});
  final double size;
  final Color? color;
  final Color? backdrop;
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Plantify leaf logo',
      image: true,
      child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.18),
          decoration: BoxDecoration(
              color: backdrop, borderRadius: BorderRadius.circular(size * .28)),
          child: CustomPaint(
              painter: _LeafPainter(
                  color ?? Theme.of(context).colorScheme.primary))));
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * .06, size.height * .9)
      ..lineTo(size.width * .14, size.height * .4)
      ..quadraticBezierTo(size.width * .24, size.height * .05, size.width * .96,
          size.height * .03)
      ..lineTo(size.width * .85, size.height * .62)
      ..quadraticBezierTo(size.width * .7, size.height * .99, size.width * .28,
          size.height * .84)
      ..lineTo(size.width * .79, size.height * .22)
      ..lineTo(size.width * .06, size.height * .9)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawLine(
        Offset(size.width * .03, size.height * .99),
        Offset(size.width * .64, size.height * .37),
        Paint()
          ..color = color
          ..strokeWidth = size.width * .08
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) => oldDelegate.color != color;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.light = false, this.large = false});
  final bool light, large;
  @override
  Widget build(BuildContext context) {
    final color =
        light ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      BrandMark(
          size: large ? 52 : 34,
          color:
              light ? Botanical.lime : Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Text('plantify',
          style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: large ? 32 : 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: color)),
      Padding(
          padding: const EdgeInsets.only(left: 3, top: 10),
          child: Text('.',
              style: TextStyle(
                  color: light
                      ? Botanical.lime
                      : Theme.of(context).colorScheme.primary,
                  fontSize: large ? 32 : 23,
                  fontWeight: FontWeight.w900))),
    ]);
  }
}

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: child,
        builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)), child: child)));
  }
}

class PlantButton extends StatefulWidget {
  const PlantButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon = Icons.arrow_forward_rounded,
      this.accent = false,
      this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool accent;
  final bool busy;
  @override
  State<PlantButton> createState() => _PlantButtonState();
}

class _PlantButtonState extends State<PlantButton> {
  bool _pressed = false, _hovered = false, _focused = false;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onPressed != null && !widget.busy;
    final active = enabled && (_hovered || _focused);
    final colors = widget.accent
        ? [Botanical.lime, const Color(0xFFABD078)]
        : Theme.of(context).brightness == Brightness.dark
            ? [const Color(0xFF92B7A1), const Color(0xFF769C8E)]
            : [Botanical.forest, Botanical.teal];
    final foreground =
        widget.accent || Theme.of(context).brightness == Brightness.dark
            ? Botanical.forest
            : Colors.white;
    return Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Listener(
                onPointerDown: (_) => setState(() => _pressed = true),
                onPointerUp: (_) => setState(() => _pressed = false),
                onPointerCancel: (_) => setState(() => _pressed = false),
                child: AnimatedScale(
                    scale: _pressed && enabled
                        ? .965
                        : active
                            ? 1.015
                            : 1,
                    duration: Duration(milliseconds: reduced ? 0 : 180),
                    child: AnimatedContainer(
                        duration: Duration(milliseconds: reduced ? 0 : 220),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: enabled || widget.busy
                                    ? colors
                                    : [
                                        colors.first.withValues(alpha: .35),
                                        colors.last.withValues(alpha: .35)
                                      ]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: enabled
                                ? [
                                    BoxShadow(
                                        color: colors.last.withValues(
                                            alpha: active ? .35 : .16),
                                        blurRadius: active ? 22 : 12,
                                        offset: Offset(0, active ? 8 : 4))
                                  ]
                                : []),
                        child: FilledButton(
                            onPressed: enabled ? widget.onPressed : null,
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: foreground,
                                disabledForegroundColor:
                                    foreground.withValues(alpha: .7)),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: Text(widget.label,
                                          textAlign: TextAlign.center)),
                                  const SizedBox(width: 12),
                                  AnimatedSwitcher(
                                      duration: Duration(
                                          milliseconds: reduced ? 0 : 180),
                                      child: widget.busy
                                          ? SizedBox(
                                              key: const ValueKey('loading'),
                                              width: 19,
                                              height: 19,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: foreground))
                                          : AnimatedSlide(
                                              duration: Duration(
                                                  milliseconds:
                                                      reduced ? 0 : 180),
                                              offset: active
                                                  ? const Offset(.18, 0)
                                                  : Offset.zero,
                                              child: Icon(widget.icon,
                                                  key: ValueKey(widget.icon),
                                                  size: 19))),
                                ])))))));
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: color ?? Theme.of(context).colorScheme.primary));
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1120});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: Center(
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Reveal(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children)))));
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null)
          TextButton(
              onPressed: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action!),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_forward_rounded, size: 16)
              ]))
      ]));
}

class SurfaceBox extends StatelessWidget {
  const SurfaceBox(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: .55))),
      child: child);
}

class PlantPhoto extends StatelessWidget {
  const PlantPhoto(this.plant,
      {super.key, this.heroTag, this.fit = BoxFit.cover});
  final Plant plant;
  final String? heroTag;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
        color: plant.color,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.eco_outlined,
              size: 64, color: Botanical.forest.withValues(alpha: .4)),
          const SizedBox(height: 8),
          Text(plant.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Botanical.forest)),
        ])));
    final photo = plant.imagePath.isEmpty
        ? fallback
        : Image.asset(plant.imagePath,
            fit: fit,
            width: double.infinity,
            cacheWidth: 640,
            semanticLabel: plant.name,
            errorBuilder: (_, __, ___) => ColoredBox(
                color: plant.color,
                child: Center(
                    child: Icon(Icons.eco_outlined,
                        size: 64,
                        color: Botanical.forest.withValues(alpha: .4)))));
    return heroTag == null ? photo : Hero(tag: heroTag!, child: photo);
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton(this.plant, {super.key});
  final Plant plant;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.favorites.contains(plant.id);
    return IconButton.filledTonal(
      key: ValueKey('favorite-${plant.id}'),
      tooltip: saved
          ? 'Remove ${plant.name} from favorites'
          : 'Save ${plant.name} to favorites',
      style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .94),
          foregroundColor: Botanical.forest),
      onPressed: () => state.toggleFavorite(plant.id),
      icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(saved),
              size: 20)),
    );
  }
}

class PlantCard extends StatelessWidget {
  const PlantCard(this.plant, {super.key, required this.source});
  final Plant plant;
  final String source;
  @override
  Widget build(BuildContext context) {
    final tag = '$source-${plant.id}';
    return Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () => openPage(
                context, PlantDetailsScreen(plant: plant, heroTag: tag)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                PlantPhoto(plant, heroTag: tag),
                Positioned(top: 8, right: 8, child: FavoriteButton(plant)),
                Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            plant.difficulty == 'Easy'
                                ? 'Easy care'
                                : plant.environment,
                            style: const TextStyle(
                                color: Botanical.forest,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)))),
              ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.wb_sunny_outlined,
                              size: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 5),
                          Expanded(
                              child: Text(plant.light,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodySmall)),
                          Icon(Icons.arrow_outward_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary)
                        ]),
                      ])),
            ])));
  }
}

class PlantGrid extends StatelessWidget {
  const PlantGrid({super.key, required this.items, required this.source});
  final List<Plant> items;
  final String source;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, constraints) {
        final count = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
                ? 3
                : 2;
        final width = (constraints.maxWidth - (count - 1) * 16) / count;
        final tallText = MediaQuery.textScalerOf(context).scale(16) > 20;
        return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: width * .98 + (tallText ? 125 : 96)),
            itemBuilder: (_, index) => PlantCard(items[index], source: source));
      });
}

class EmptyGarden extends StatelessWidget {
  const EmptyGarden(
      {super.key,
      required this.title,
      required this.message,
      required this.action,
      required this.onAction,
      this.icon = Icons.eco_outlined});
  final String title, message, action;
  final VoidCallback onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(children: [
                Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: BoxShape.circle),
                    child: Icon(icon,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 22),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                PlantButton(label: action, onPressed: onAction),
              ]))));
}

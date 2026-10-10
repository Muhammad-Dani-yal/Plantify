import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Quiet botanical motion; pauses off-screen and respects reduced-motion settings.
class MotionIcon extends StatefulWidget {
  const MotionIcon(this.icon,
      {super.key, this.size = 24, this.color, this.live = false});
  final IconData icon;
  final double size;
  final Color? color;
  final bool live;
  @override
  State<MotionIcon> createState() => _MotionIconState();
}

class _MotionIconState extends State<MotionIcon>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
      vsync: this, duration: Duration(milliseconds: widget.live ? 2400 : 3200));
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final enabled = _foreground &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context);
    if (enabled && !_motion.isAnimating) _motion.repeat();
    if (!enabled) {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: AnimatedBuilder(
          animation: _motion,
          builder: (_, __) {
            final reduced = MediaQuery.disableAnimationsOf(context);
            final wave = reduced ? 0.0 : math.sin(_motion.value * math.pi * 2);
            final color = widget.color ??
                IconTheme.of(context).color ??
                Theme.of(context).colorScheme.primary;
            return SizedBox(
                width: widget.size + (widget.live ? 12 : 4),
                height: widget.size + (widget.live ? 12 : 4),
                child: Stack(alignment: Alignment.center, children: [
                  if (widget.live)
                    CustomPaint(
                        size: Size.square(widget.size + 12),
                        painter:
                            _LiveOrbit(color, reduced ? 0 : _motion.value)),
                  Transform.rotate(
                      angle: wave * .09,
                      child: Transform.scale(
                          scale: 1 + wave.abs() * .055,
                          child: Icon(widget.icon,
                              size: widget.size, color: color))),
                ]));
          }));
}

class _LiveOrbit extends CustomPainter {
  const _LiveOrbit(this.color, this.phase);
  final Color color;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.width / 2 - 2;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    final angle = phase * math.pi * 2 - math.pi / 2;
    canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        2.5,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LiveOrbit old) =>
      phase != old.phase || color != old.color;
}

IconData collectionIcon(String label) {
  final text = label.toLowerCase();
  if (text.contains('fruit')) return Icons.apple_rounded;
  if (text.contains('unique') || text.contains('rare')) {
    return Icons.auto_awesome;
  }
  if (text.contains('outdoor') || text.contains('world')) {
    return Icons.park_outlined;
  }
  if (text.contains('indoor')) return Icons.other_houses_outlined;
  if (text.contains('water')) return Icons.water_drop_outlined;
  if (text.contains('light') || text.contains('desert')) {
    return Icons.wb_sunny_outlined;
  }
  if (text.contains('flower') || text.contains('colour')) {
    return Icons.local_florist_outlined;
  }
  if (text.contains('herb') || text.contains('kitchen')) {
    return Icons.restaurant_outlined;
  }
  return Icons.spa_outlined;
}

import 'package:flutter/material.dart';

import '../../utils/bl_colors.dart';

/// Fades a child in while it rises a few pixels. Use [delay] to make a list
/// arrive one item after another. It runs once, when the item first appears,
/// and costs nothing afterwards. People who turn on "reduce motion" see the
/// child at once.
class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double rise;
  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.rise = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay + duration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: _Delayed(
          delay.inMicroseconds / total.inMicroseconds, Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
            offset: Offset(0, (1 - t) * rise), child: child),
      ),
    );
  }
}

/// Holds still for the first [start] part of the animation, then eases.
class _Delayed extends Curve {
  final double start;
  final Curve curve;
  const _Delayed(this.start, this.curve);

  @override
  double transformInternal(double t) =>
      t <= start ? 0 : curve.transform((t - start) / (1 - start));
}

/// A grey placeholder that softly pulses while real content loads. It tells
/// people something is coming, and what shape, without a jumpy spinner.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const Skeleton(
      {super.key, required this.height, this.width, this.radius = 14});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(BL.hairline, const Color(0xFFF4EFEF),
                still ? 0.5 : Curves.easeInOut.transform(_c.value)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// The shape of a bus card while the buses are being found.
class BusCardSkeleton extends StatelessWidget {
  const BusCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BL.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BL.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 22, width: 180, radius: 8),
          SizedBox(height: 10),
          Skeleton(height: 16, width: 120, radius: 8),
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(height: 34, width: 90, radius: 8),
              Skeleton(height: 6, width: 56, radius: 3),
              Skeleton(height: 34, width: 90, radius: 8),
            ],
          ),
          SizedBox(height: 22),
          Skeleton(height: 52, radius: 26),
        ],
      ),
    );
  }
}

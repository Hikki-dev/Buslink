import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';

/// White rounded card with the soft red shadow used across the redesign.
BoxDecoration blCard(double r) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      boxShadow: const [
        BoxShadow(
            color: Color(0x14660708), blurRadius: 10, offset: Offset(0, 2))
      ],
    );

/// The big red pill button.
class BlPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const BlPrimaryButton(
      {super.key,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: const Color(0xFFE3DADB),
            shape: const StadiumBorder(),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          child: Text(label),
        ),
      );
}

/// The 1, 2, 3 strip on the booking pages (desktop).
class BookingSteps extends StatelessWidget {
  final int current; // 0 based
  const BookingSteps({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Choose a bus', 'Choose seats', 'Pay and get your ticket'];
    return Wrap(
      spacing: 32,
      runSpacing: 12,
      children: [
        for (var i = 0; i < labels.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < current
                      ? BL.success
                      : (i == current ? BL.crimson : null),
                  shape: BoxShape.circle,
                  border: i > current
                      ? Border.all(color: const Color(0xFF8A95A3), width: 2)
                      : null,
                ),
                child: i < current
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text('${i + 1}',
                        style: TextStyle(
                            color: i == current ? Colors.white : BL.ink,
                            fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          i == current ? FontWeight.w700 : FontWeight.w400,
                      color: i == current ? BL.crimson : BL.muted)),
            ],
          ),
      ],
    );
  }
}

/// The red page header: back arrow, title, optional line under it and
/// buttons on the right (mockups' "Go back" bar).
class BlHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottom;
  const BlHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BL.crimson,
      padding: EdgeInsets.fromLTRB(
          showBack ? 8 : 20, MediaQuery.paddingOf(context).top + 4, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: 'Go back',
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              if (showBack) const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: showBack ? 0 : 8),
                      child: Text(title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: showBack ? 22 : 26,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// An empty or "nothing to show" message with a round icon.
class BlEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  const BlEmpty(
      {super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFDEEEE), shape: BoxShape.circle),
                  child: Icon(icon, size: 30, color: BL.crimson),
                ),
                const SizedBox(height: 14),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, height: 1.35, color: BL.muted)),
                ],
              ],
            ),
          ),
        ),
      );
}

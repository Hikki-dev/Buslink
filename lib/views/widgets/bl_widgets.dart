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

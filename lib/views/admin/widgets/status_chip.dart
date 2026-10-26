import 'package:flutter/material.dart';
import '../../../utils/bl_colors.dart';

/// Colour, icon and label for a booking / trip / refund status. Every status
/// gets an icon and a word as well as a colour, so it still reads for people
/// who cannot tell red from green.
class StatusStyle {
  final String label;
  final IconData icon;
  final Color color;
  const StatusStyle(this.label, this.icon, this.color);
}

StatusStyle statusStyle(String? raw) {
  final key = (raw ?? '').toLowerCase().replaceAll(' ', '_');
  switch (key) {
    case 'confirmed':
      return StatusStyle(
          'Confirmed', Icons.check_circle, Colors.green.shade800);
    case 'boarded':
      return StatusStyle('Boarded', Icons.directions_bus, Colors.teal.shade800);
    case 'completed':
    case 'arrived':
    case 'processed':
      return StatusStyle(key == 'processed' ? 'Refunded' : 'Completed',
          Icons.task_alt, Colors.blue.shade800);
    case 'cancelled':
      return StatusStyle('Cancelled', Icons.cancel, Colors.red.shade800);
    case 'rejected':
      return StatusStyle('Rejected', Icons.block, Colors.red.shade800);
    case 'failed':
      return StatusStyle('Failed', Icons.error, Colors.red.shade800);
    case 'refund_requested':
    case 'pending':
      return StatusStyle(key == 'pending' ? 'Pending' : 'Refund requested',
          Icons.hourglass_top, Colors.orange.shade900);
    case 'approved':
      return StatusStyle('Approved', Icons.thumb_up, Colors.green.shade800);
    case 'refunded':
      return StatusStyle('Refunded', Icons.undo, Colors.purple.shade800);
    case 'delayed':
      return StatusStyle('Delayed', Icons.schedule, Colors.orange.shade900);
    case 'scheduled':
    case 'on_time':
    case 'ontime':
      return StatusStyle('On time', Icons.schedule, Colors.green.shade800);
    case 'boarding':
      return StatusStyle(
          'Boarding', Icons.directions_bus, Colors.teal.shade800);
    case 'departed':
    case 'started':
    case 'in_progress':
    case 'inprogress':
      return StatusStyle('On the way', Icons.near_me, Colors.blue.shade800);
    default:
      final text = key.isEmpty ? 'Unknown' : key.replaceAll('_', ' ');
      return StatusStyle(text[0].toUpperCase() + text.substring(1),
          Icons.help_outline, Colors.grey.shade700);
  }
}

/// Small pill: icon + word on a tinted background.
class StatusChip extends StatelessWidget {
  final String? status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = statusStyle(status);
    return Semantics(
      label: 'Status: ${s.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, size: 16, color: s.color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(s.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: s.color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1 Route · 2 Schedule · 3 Fare & bus" progress strip for the trip form.
class TripFormSteps extends StatelessWidget {
  final int current;
  static const labels = ['Route', 'Schedule', 'Fare & bus'];
  const TripFormSteps({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    const red = BL.crimson;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Semantics(
      label: 'Step ${current + 1} of ${labels.length}: ${labels[current]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                  child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color:
                          i <= current ? red : muted.withValues(alpha: 0.3))),
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  i <= current ? red : muted.withValues(alpha: 0.25),
              child: i < current
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text('${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: i == current ? Colors.white : muted)),
            ),
            if (i == current)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(labels[i],
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
          ],
        ],
      ),
    );
  }
}

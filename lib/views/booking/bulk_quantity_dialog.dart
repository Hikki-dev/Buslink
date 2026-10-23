import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import '../../models/trip_model.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';

class BulkQuantityDialog extends StatefulWidget {
  final Trip trip;
  final int days;
  final Function(int qty) onConfirm;

  const BulkQuantityDialog({
    super.key,
    required this.trip,
    required this.days,
    required this.onConfirm,
  });

  @override
  State<BulkQuantityDialog> createState() => _BulkQuantityDialogState();
}

class _BulkQuantityDialogState extends State<BulkQuantityDialog> {
  late int _qty;
  static const int maxSeats = 50; // Safety limit

  @override
  void initState() {
    super.initState();
    final ctrl = Provider.of<TripController>(context, listen: false);
    _qty = ctrl.bulkPassengers > 0 ? ctrl.bulkPassengers : 1;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final total = widget.trip.price * widget.days * _qty;

    Widget round(IconData icon, String tip, VoidCallback onTap,
            {required bool filled}) =>
        Semantics(
          button: true,
          label: tip,
          child: Material(
            color: filled ? BL.crimson : Colors.white,
            shape: CircleBorder(
                side: filled
                    ? BorderSide.none
                    : const BorderSide(color: BL.crimson, width: 2)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon,
                    size: 28, color: filled ? Colors.white : BL.crimson),
              ),
            ),
          ),
        );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select Passengers',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  'How many people are travelling on each of the ${widget.days} days?',
                  style: const TextStyle(fontSize: 17, color: BL.muted)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  round(Icons.remove, 'One fewer passenger', () {
                    if (_qty > 1) setState(() => _qty--);
                  }, filled: false),
                  const SizedBox(width: 28),
                  Column(
                    children: [
                      Text('$_qty',
                          style: const TextStyle(
                              fontSize: 60,
                              height: 1,
                              fontWeight: FontWeight.w800)),
                      Text(_qty == 1 ? 'passenger' : 'passengers',
                          style:
                              const TextStyle(fontSize: 16, color: BL.muted)),
                    ],
                  ),
                  const SizedBox(width: 28),
                  round(Icons.add, 'One more passenger', () {
                    if (_qty < maxSeats) setState(() => _qty++);
                  }, filled: true),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFDEEEE),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Price',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(
                              '$_qty × ${widget.days} days × LKR ${fmt.format(widget.trip.price)}',
                              style: const TextStyle(
                                  fontSize: 14, color: BL.muted)),
                        ],
                      ),
                    ),
                    Text('LKR ${fmt.format(total)}',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BL.crimson)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              BlPrimaryButton(
                  label: 'Proceed to Payment',
                  color: BL.crimson,
                  onTap: () => widget.onConfirm(_qty)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: BL.muted,
                    minimumSize: const Size(0, 48),
                    textStyle: const TextStyle(fontSize: 16)),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

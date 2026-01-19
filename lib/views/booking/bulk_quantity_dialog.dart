import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
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
    final double perPerson = widget.trip.price * widget.days;
    final double total = perPerson * _qty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Passengers",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "For ${widget.days} days",
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBtn(Icons.remove, () {
                  if (_qty > 1) setState(() => _qty--);
                }),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    "$_qty",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildBtn(Icons.add, () {
                  if (_qty < maxSeats) setState(() => _qty++);
                }),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Price",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    "LKR ${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onConfirm(_qty),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Proceed to Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }
}

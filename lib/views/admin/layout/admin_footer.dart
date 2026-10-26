import 'package:flutter/material.dart';
import '../../../utils/bl_colors.dart';

class AdminFooter extends StatelessWidget {
  const AdminFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: BL.fill,
      child: Center(
        child: Text(
          "© 2025 BusLink Admin Panel. Restricted Access.",
          style: TextStyle(color: BL.faint, fontSize: 12),
        ),
      ),
    );
  }
}

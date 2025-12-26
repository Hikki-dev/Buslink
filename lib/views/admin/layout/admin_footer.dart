import 'package:flutter/material.dart';

class AdminFooter extends StatelessWidget {
  const AdminFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.grey.shade100,
      child: const Center(
        child: Text(
          "© 2025 BusLink Admin Panel. Restricted Access.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

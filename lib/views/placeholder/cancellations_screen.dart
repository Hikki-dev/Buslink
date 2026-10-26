// lib/views/placeholder/cancellations_screen.dart
import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';

class CancellationsScreen extends StatelessWidget {
  const CancellationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancellations')),
      body: Center(
        child: Text(
          'This page will be used to manage ticket cancellations.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: BL.faint),
        ),
      ),
    );
  }
}

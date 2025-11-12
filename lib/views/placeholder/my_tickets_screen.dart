// lib/views/placeholder/my_tickets_screen.dart
import 'package:flutter/material.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: const Center(
        child: Text(
          'This page will show a list of your booked tickets.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

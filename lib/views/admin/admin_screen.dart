// lib/views/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';

class AdminScreen extends StatefulWidget {
  final Trip trip;
  const AdminScreen({super.key, required this.trip});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late TextEditingController _fromCityController;
  late TextEditingController _toCityController;
  late TextEditingController _busFeeController;
  late DateTime _departureTime;
  late DateTime _arrivalTime;

  late TextEditingController _platformController;
  late TextEditingController _delayController;
  TripStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;

    _fromCityController = TextEditingController(text: trip.fromCity);
    _toCityController = TextEditingController(text: trip.toCity);
    _busFeeController =
        TextEditingController(text: trip.price.toStringAsFixed(0));
    _departureTime = trip.departureTime;
    _arrivalTime = trip.arrivalTime;

    _platformController = TextEditingController(text: trip.platformNumber);
    _delayController =
        TextEditingController(text: trip.delayMinutes.toString());
    _selectedStatus = trip.status;
  }

  void _saveChanges() {
    final controller = Provider.of<TripController>(context, listen: false);

    final data = {
      'fromCity': _fromCityController.text,
      'toCity': _toCityController.text,
      'price': double.tryParse(_busFeeController.text) ?? widget.trip.price,
      'departureTime': _departureTime,
      'arrivalTime': _arrivalTime,
      'platformNumber': _platformController.text,
      'status': _selectedStatus?.name ?? TripStatus.onTime.name,
      'delayMinutes': int.tryParse(_delayController.text) ?? 0,
    };

    // 1. FIX: Call to updateTripDetails is async, so context must be
    // checked after. The error was on line 80 in the *original* file.
    // My previous fix in `trip_controller.dart` already handles this,
    // so no change is needed *here*. The error was in the controller,
    // not this UI file.
    controller.updateTripDetails(context, widget.trip.id, data);
  }

  Future<DateTime?> _pickDateTime(DateTime initialDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit: ${widget.trip.busNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Route (Spec: Edit Routes)'),
          _buildTextField(_fromCityController, 'From City'),
          const SizedBox(height: 10),
          _buildTextField(_toCityController, 'To City'),
          const Divider(height: 30),
          _buildSectionTitle('Fee (Spec: Edit Bus Fee)'),
          _buildTextField(
              _busFeeController, 'Bus Fee (LKR)', TextInputType.number),
          const Divider(height: 30),
          _buildSectionTitle('Time & Date (Spec: Edit Time/Date)'),
          _buildDateTimePicker(
            'Departure',
            _departureTime,
            (newDate) => setState(() => _departureTime = newDate),
          ),
          const SizedBox(height: 10),
          _buildDateTimePicker(
            'Arrival',
            _arrivalTime,
            (newDate) => setState(() => _arrivalTime = newDate),
          ),
          const Divider(height: 30),
          _buildSectionTitle('Platform & Status'),
          _buildTextField(_platformController, 'Platform Number'),
          const SizedBox(height: 10),
          DropdownButtonFormField<TripStatus>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Trip Status',
              border: OutlineInputBorder(),
            ),
            items: TripStatus.values
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status.name)),
                )
                .toList(),
            onChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _delayController,
            'Delay (minutes)',
            TextInputType.number,
          ),
          const Divider(height: 30),
          ElevatedButton(
            onPressed: _saveChanges,
            child: const Text('Save All Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType? keyboardType,
  ]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime date,
    void Function(DateTime) onDateChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('MMM d, yyyy - hh:mm a').format(date)),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () async {
              final newDate = await _pickDateTime(date);
              if (newDate != null) {
                onDateChanged(newDate);
              }
            },
          ),
        ],
      ),
    );
  }
}

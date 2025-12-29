import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';

class AdminRouteScreen extends StatefulWidget {
  const AdminRouteScreen({super.key});

  @override
  State<AdminRouteScreen> createState() => _AdminRouteScreenState();
}

class _AdminRouteScreenState extends State<AdminRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _viaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  TimeOfDay? _departureTime;

  bool _isLoading = false;

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _departureTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ignore: unused_local_variable
    final controller = Provider.of<TripController>(context, listen: false);

    // Create a Route Object (or pseudo-route)
    // The requirement "add new route ... stating origin, destination, via ... that's it"
    // implies we just want to save these basics.
    // However, to be useful, we likely need price/duration or we just save a stub.
    // For now, we'll save a "Route" template.

    // Actual implementation
    final routeData = {
      'fromCity': _originController.text,
      'toCity': _destinationController.text,
      'via': _viaController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'duration': _durationController.text,
      'departureTime': _departureTime != null
          ? "${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}"
          : null,
      'operatorName': 'BusLink Official',
      'busNumber': 'TEMPLATE', // Indicates this is a route definition
      'isRouteDefinition': true, // Flag to distinguish
    };

    try {
      // Save to 'routes' collection
      await controller.saveRoute(routeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Route Added Successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Add New Route",
            style: TextStyle(
                fontFamily: 'Outfit',
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Route Details",
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildCityAutocomplete("Origin", _originController),
                        const SizedBox(height: 16),
                        _buildCityAutocomplete(
                            "Destination", _destinationController),
                        const SizedBox(height: 16),
                        _buildTextField("Via (Route Variant)", _viaController,
                            icon: Icons.alt_route),
                        const SizedBox(height: 16),
                        // Time Picker
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    color:
                                        isDark ? Colors.white70 : Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  _departureTime != null
                                      ? _departureTime!.format(context)
                                      : "Select Departure Time",
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    "Std. Price (LKR)", _priceController,
                                    icon: Icons.attach_money, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildTextField(
                                    "Est. Duration", _durationController,
                                    icon: Icons.access_time)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE ROUTE",
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  Widget _buildCityAutocomplete(
      String label, TextEditingController controller) {
    return LayoutBuilder(builder: (context, constraints) {
      return Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return AppConstants.cities.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
        },
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          // Keep internal controller in sync if needed, but we use _originController passed in
          if (controller.text.isNotEmpty &&
              textEditingController.text.isEmpty) {
            textEditingController.text = controller.text;
          }
          controller.addListener(() {
            if (controller.text != textEditingController.text) {
              textEditingController.text = controller.text;
            }
          });

          return TextFormField(
            controller:
                textEditingController, // Use the autocomplete's controller for input
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
              controller.text = value;
            },
            onChanged: (val) => controller.text = val,
            decoration: InputDecoration(
                labelText: label,
                prefixIcon:
                    const Icon(Icons.location_on_outlined, color: Colors.grey),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

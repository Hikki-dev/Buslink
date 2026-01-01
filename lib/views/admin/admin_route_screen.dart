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

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ignore: unused_local_variable
    final controller = Provider.of<TripController>(context, listen: false);

    // Construct Duration String - REMOVED
    const String durationStr = "N/A";

    final routeData = {
      'fromCity': _originController.text,
      'toCity': _destinationController.text,
      'via': _viaController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'duration': durationStr,
      // 'departureTime': REMOVED as per request
      'operatorName': 'BusLink Official',
      'busNumber': 'TEMPLATE',
      'isRouteDefinition': true,
    };

    try {
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
    // Theme Awareness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final inputFillColor =
        isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
    final borderColor =
        isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("Add New Route",
            style: TextStyle(
                fontFamily: 'Outfit',
                color: textColor,
                fontWeight: FontWeight.bold)),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? scaffoldColor,
        elevation: 0,
        leading: BackButton(color: textColor),
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
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Route Details",
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 24),
                        _buildCityAutocomplete("Origin", _originController,
                            inputFillColor, borderColor, textColor),
                        const SizedBox(height: 16),
                        _buildCityAutocomplete(
                            "Destination",
                            _destinationController,
                            inputFillColor,
                            borderColor,
                            textColor),
                        const SizedBox(height: 16),
                        _buildTextField("Via (Route Variant)", _viaController,
                            icon: Icons.alt_route,
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            textColor: textColor),

                        // DEPARTURE TIME REMOVED

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Price",
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                        "Amount (LKR)", _priceController,
                                        icon: Icons.attach_money,
                                        isNumber: true,
                                        fillColor: inputFillColor,
                                        borderColor: borderColor,
                                        textColor: textColor),
                                  ],
                                )),
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
      {IconData? icon,
      bool isNumber = false,
      bool isRequired = true,
      Color? fillColor,
      Color? borderColor,
      Color? textColor}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: borderColor ?? Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: fillColor ?? Colors.grey.shade50),
      validator: (v) {
        if (!isRequired) return null;
        return v == null || v.isEmpty ? "Required" : null;
      },
    );
  }

  Widget _buildCityAutocomplete(String label, TextEditingController controller,
      Color fillColor, Color borderColor, Color textColor) {
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
            controller: textEditingController,
            focusNode: focusNode,
            style: TextStyle(color: textColor),
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
              controller.text = value;
            },
            onChanged: (val) => controller.text = val,
            decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon:
                    const Icon(Icons.location_on_outlined, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: fillColor),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
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
                        child: Text(option, style: TextStyle(color: textColor)),
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

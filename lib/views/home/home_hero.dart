// The home screen's photo header and trip search form (mockups "Main" and
// "Desktop-Home"). All state lives in HomeScreen; this only draws it.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/trip_controller.dart';
import '../../utils/bl_colors.dart';

class HomeHero extends StatelessWidget {
  final bool isDesktop;
  final bool isAdminView;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocusNode;
  final FocusNode destinationFocusNode;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onSearchTap;
  final bool isBulkBooking;
  final int bulkDatesCount;
  final ValueChanged<bool> onBulkBookingChanged;

  /// Phone header extras (greeting + log out). Null on desktop.
  final Widget? phoneActions;

  const HomeHero({
    super.key,
    required this.isDesktop,
    required this.isAdminView,
    required this.originController,
    required this.destinationController,
    required this.originFocusNode,
    required this.destinationFocusNode,
    required this.selectedDate,
    required this.onDateTap,
    required this.onSearchTap,
    required this.isBulkBooking,
    required this.bulkDatesCount,
    required this.onBulkBookingChanged,
    this.phoneActions,
  });

  bool get _sameCity =>
      originController.text.trim().isNotEmpty &&
      originController.text.trim().toLowerCase() ==
          destinationController.text.trim().toLowerCase();

  String get _dateText => isBulkBooking
      ? '$bulkDatesCount day${bulkDatesCount == 1 ? '' : 's'} chosen'
      : DateFormat('EEE, d MMM yyyy').format(selectedDate);

  void _swap() {
    final from = originController.text;
    originController.text = destinationController.text;
    destinationController.text = from;
  }

  @override
  Widget build(BuildContext context) =>
      isDesktop ? _desktop(context) : _phone(context);

  // ---------------------------------------------------------------- phone
  Widget _phone(BuildContext context) {
    const photoHeight = 186.0;
    const overlap = 22.0;
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: _HeroPhoto(
              height: photoHeight,
              position: Alignment(0, 0.2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8C460405), Color(0xC7960E12)],
              )),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.paddingOf(context).top + 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BusLink',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                    if (phoneActions != null) phoneActions!,
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Where would you like to go?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.25)),
              ],
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: photoHeight - overlap),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: _cardDecoration(16),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          _CityField(
                              label: 'Leaving from',
                              hint: 'Where from?',
                              icon: Icons.radio_button_unchecked,
                              controller: originController,
                              focusNode: originFocusNode,
                              height: 50),
                          const SizedBox(height: 10),
                          _CityField(
                              label: 'Going to',
                              hint: 'Where to?',
                              icon: Icons.location_on,
                              controller: destinationController,
                              focusNode: destinationFocusNode,
                              height: 50),
                        ],
                      ),
                      Positioned(
                          top: 48, right: 8, child: _SwapButton(onTap: _swap)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DateField(
                      label: isBulkBooking ? 'Days of travel' : 'Day of travel',
                      value: _dateText,
                      onTap: onDateTap,
                      height: 50),
                  const SizedBox(height: 8),
                  _BulkToggle(
                      value: isBulkBooking, onChanged: onBulkBookingChanged),
                  const SizedBox(height: 8),
                  _SearchButton(
                      enabled: !_sameCity,
                      label: _sameCity
                          ? 'Pick two different places'
                          : 'Search Buses',
                      height: 54,
                      onTap: onSearchTap),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------- desktop
  Widget _desktop(BuildContext context) {
    final photoHeight = isAdminView ? 380.0 : 580.0;
    const overlap = 92.0;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: const _HeroPhoto(
              height: 0,
              position: Alignment(0, 0.1),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xD13C0304),
                  Color(0x73960E12),
                  Color(0x1A960E12)
                ],
                stops: [0, 0.55, 1],
              )),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24, isAdminView ? 24 : 40, 24, overlap + 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COLOMBO · KANDY · GALLE · NUWARA ELIYA AND MORE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.7)),
                        SizedBox(height: 12),
                        Text('Travel Sri Lanka by bus, the easy way',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 58,
                                height: 1.08,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 18),
                        Text(
                            'Pick where you are going, choose your seat, and keep your ticket on your phone.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(height: photoHeight - overlap),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                                child: _CityField(
                                    label: 'Leaving from',
                                    hint: 'Where from?',
                                    icon: Icons.radio_button_unchecked,
                                    controller: originController,
                                    focusNode: originFocusNode,
                                    height: 56)),
                            const SizedBox(width: 16),
                            _SwapButton(onTap: _swap, outlined: true),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _CityField(
                                    label: 'Going to',
                                    hint: 'Where to?',
                                    icon: Icons.location_on,
                                    controller: destinationController,
                                    focusNode: destinationFocusNode,
                                    height: 56)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _DateField(
                                    label: isBulkBooking
                                        ? 'Days of travel'
                                        : 'Day of travel',
                                    value: _dateText,
                                    onTap: onDateTap,
                                    height: 56)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 200,
                              child: _SearchButton(
                                  enabled: !_sameCity,
                                  label: _sameCity
                                      ? 'Pick two different places'
                                      : 'Search Buses',
                                  height: 56,
                                  onTap: onSearchTap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BulkToggle(
                              value: isBulkBooking,
                              onChanged: onBulkBookingChanged),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration(double radius) => BoxDecoration(
      color: BL.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
            color: Color(0x29660708), blurRadius: 24, offset: Offset(0, 8))
      ],
    );

class _HeroPhoto extends StatelessWidget {
  final double height;
  final Alignment position;
  final Gradient gradient;
  const _HeroPhoto(
      {required this.height, required this.position, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height == 0 ? null : height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: 'A blue train crossing the Nine Arches Bridge near Ella',
            image: true,
            child: Image.asset('assets/images/home/ella_train.jpg',
                fit: BoxFit.cover, alignment: position),
          ),
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: BL.ink)),
      );
}

BoxDecoration _fieldBox() => BoxDecoration(
      border: Border.all(color: BL.border, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );

class _CityField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double height;
  const _CityField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _fieldBox(),
          child: Row(
            children: [
              Icon(icon, color: BL.link, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(builder: (context, box) {
                  return RawAutocomplete<String>(
                    textEditingController: controller,
                    focusNode: focusNode,
                    optionsBuilder: (value) {
                      final cities =
                          context.read<TripController>().availableCities;
                      final q = value.text.trim().toLowerCase();
                      if (q.isEmpty) return cities;
                      return cities.where((c) => c.toLowerCase().contains(q));
                    },
                    fieldViewBuilder: (context, c, f, onSubmit) => TextField(
                      controller: c,
                      focusNode: f,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => onSubmit(),
                      style: TextStyle(fontSize: 18, color: BL.ink),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(fontSize: 18, color: BL.faint),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        color: BL.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 240,
                              maxWidth:
                                  box.maxWidth < 260 ? 260 : box.maxWidth),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, i) {
                              final city = options.elementAt(i);
                              return InkWell(
                                onTap: () => onSelected(city),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 48),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(city,
                                      style: TextStyle(
                                          fontSize: 18, color: BL.ink)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final double height;
  const _DateField(
      {required this.label,
      required this.value,
      required this.onTap,
      required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Semantics(
          button: true,
          label: '$label: $value. Tap to change',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: _fieldBox(),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: BL.link, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, color: BL.ink)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool outlined;
  const _SwapButton({required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final size = outlined ? 56.0 : 48.0;
    return Semantics(
      button: true,
      label: 'Swap the two cities',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(color: BL.surface, spreadRadius: 4),
                  BoxShadow(
                      color: Color(0x2E660708),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
        ),
        child: Material(
          color: BL.surface,
          shape: CircleBorder(
              side: BorderSide(
                  color: outlined ? BL.crimson : BL.border, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(outlined ? Icons.swap_horiz : Icons.swap_vert,
                  color: BL.link, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _BulkToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                color: value ? BL.crimson : BL.muted, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Text('Bulk booking (several days)',
                  style: TextStyle(fontSize: 16, color: BL.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final double height;
  final VoidCallback onTap;
  const _SearchButton(
      {required this.enabled,
      required this.label,
      required this.height,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: BL.crimson,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BL.fill,
          disabledForegroundColor: BL.muted,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

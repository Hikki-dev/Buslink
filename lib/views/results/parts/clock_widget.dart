part of '../bus_list_screen.dart';

class _ClockWidget extends StatefulWidget {
  final double fontSize;
  const _ClockWidget({this.fontSize = 24});

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('hh:mm:ss a').format(_currentTime),
      style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize,
          color: AppTheme.primaryColor),
    );
  }
}

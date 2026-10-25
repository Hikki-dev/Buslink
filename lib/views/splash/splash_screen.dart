import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'bus_glyph.dart';
import 'route_painter.dart';

/// The colours of the start-up screen, light and dark. They match the splash in
/// web/index.html and the "Starting up" boards on the design canvas.
class SplashColors {
  const SplashColors._(this.background, this.blush, this.word, this.muted,
      this.ink, this.road, this.stop, this.accent);

  final Color background, blush, word, muted, ink, road, stop, accent;

  static const light = SplashColors._(
    Color(0xFFFFFFFF),
    Color(0xFFFDEEEE),
    Color(0xFFBA181B),
    Color(0xFF5A626A),
    Color(0xFF0B090A),
    Color(0xFFE7D3D4),
    Color(0xFFFFFFFF),
    Color(0xFFBA181B),
  );

  static const dark = SplashColors._(
    Color(0xFF0A0B10),
    Color(0xFF1C0F10),
    Color(0xFFFF5A5D),
    Color(0xFFA9B0B8),
    Color(0xFFF3F4F6),
    Color(0xFF3A2A2C),
    Color(0xFF0A0B10),
    Color(0xFFFF5A5D),
  );

  static SplashColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// The start-up screen: the logo, the name, and a bus driving from Colombo to
/// Kandy to Ella while the app gets ready. It replaces a plain spinner.
///
/// * [slow] swaps the status line for "Still getting ready" and a reason.
/// * [playIntro] is false when this screen appears in place of another splash
///   (for example while the profile loads), so the logo does not pop in twice.
/// * If the phone is set to reduce motion, nothing moves: the same picture is
///   held still.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.status = 'Getting things ready',
    this.slow = false,
    this.playIntro = true,
  });

  final String status;
  final bool slow;
  final bool playIntro;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Seconds since the screen appeared. The whole animation is a pure function
  // of this one number, so it is easy to reason about and to test.
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) {
    _t.value =
        _offset + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  });

  // Skips the entrance when this screen replaces another splash.
  double get _offset => widget.playIntro ? 0 : SplashTimeline.introEnd;

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _ticker.stop();
      _t.value = SplashTimeline.stillAt;
    } else if (!_ticker.isActive) {
      _t.value = _offset;
      _ticker.start();
    }
    _reduceMotion = reduce;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SplashColors.of(context);
    final label = widget.slow
        ? 'Still getting ready. Your connection looks slow.'
        : widget.status;

    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.16),
              radius: 0.95,
              colors: [colors.blush, colors.background],
              stops: const [0, 0.62],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: ValueListenableBuilder<double>(
                valueListenable: _t,
                builder: (context, t, _) => _content(colors, t),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(SplashColors c, double t) {
    final intro = SplashTimeline.intro(t);
    final pulse = _reduceMotion ? null : SplashTimeline.pulse(t);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pulse != null)
                Opacity(
                  opacity: pulse.opacity,
                  child: Transform.scale(
                    scale: pulse.scale,
                    child: const _Tile(color: Color(0xFFBA181B), glyph: false),
                  ),
                ),
              Opacity(
                opacity: intro.logo.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.7 + 0.3 * intro.logoScale,
                  child: const _Tile(color: Color(0xFFBA181B), shadow: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Opacity(
          opacity: intro.word,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - intro.word)),
            child: Text(
              'BusLink',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
                fontSize: 44,
                letterSpacing: -1,
                height: 1,
                color: c.word,
              ),
            ),
          ),
        ),
        const SizedBox(height: 38),
        Opacity(
          opacity: intro.route,
          child: SizedBox(
            width: 286,
            height: 132,
            child: CustomPaint(
              painter: RoutePainter(
                colors: c,
                cycle: _reduceMotion ? null : SplashTimeline.cycle(t),
                still: _reduceMotion,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Opacity(
          opacity: intro.message,
          // At least 76 high so the screen does not jump, but free to grow:
          // the "slow" message wraps onto more lines than the status line.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76, maxWidth: 300),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.slow
                  ? _SlowMessage(key: const ValueKey('slow'), colors: c)
                  : _StatusLine(
                      key: const ValueKey('status'),
                      text: widget.status,
                      colors: c,
                      t: t,
                      animateDots: !_reduceMotion,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// All the timing of the splash, in one place. Seconds since it appeared.
@visibleForTesting
class SplashTimeline {
  const SplashTimeline._();

  /// The entrance (logo, name, route, message) is finished by here.
  static const double introEnd = 1.6;

  /// The length of one bus journey, and the pause that follows it.
  static const double cycleSeconds = 3.6;

  /// The moment the first journey starts.
  static const double loopStart = 1.0;

  /// The time that is shown when the phone asks for less motion.
  static const double stillAt = introEnd;

  static double _ramp(double t, double start, double length) =>
      ((t - start) / length).clamp(0.0, 1.0);

  static ({
    double logo,
    double logoScale,
    double word,
    double route,
    double message
  }) intro(double t) {
    final logoT = _ramp(t, 0, 0.75);
    return (
      logo: logoT,
      logoScale: const Cubic(0.2, 0.9, 0.3, 1.15).transform(logoT),
      word: Curves.easeOut.transform(_ramp(t, 0.3, 0.6)),
      route: _ramp(t, 0.7, 0.6),
      message: _ramp(t, 1.0, 0.6),
    );
  }

  /// 0..1 through the current journey, or null before the first one starts.
  static double? cycle(double t) {
    if (t < loopStart) return null;
    return ((t - loopStart) % cycleSeconds) / cycleSeconds;
  }

  /// The soft ring that breathes out from the logo.
  static ({double scale, double opacity})? pulse(double t) {
    if (t < loopStart) return null;
    final p = ((t - loopStart) % 2.6) / 2.6;
    return (scale: 1 + 0.75 * p, opacity: 0.35 * (1 - p));
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, this.glyph = true, this.shadow = false});

  final Color color;
  final bool glyph;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(34),
        boxShadow: shadow
            ? const [
                BoxShadow(
                    color: Color(0x47BA181B),
                    blurRadius: 30,
                    offset: Offset(0, 14))
              ]
            : null,
      ),
      child: glyph
          ? Center(child: BusGlyph(size: 64, body: Colors.white, cutout: color))
          : null,
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    super.key,
    required this.text,
    required this.colors,
    required this.t,
    required this.animateDots,
  });

  final String text;
  final SplashColors colors;
  final double t;
  final bool animateDots;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: colors.muted,
    );

    // Three dots that take turns, like the page splash: a 1.2 second beat,
    // 0.2 seconds apart. They are part of the text, so the line wraps and
    // follows the phone's text size like any other text.
    TextSpan dot(int i) {
      var alpha = 1.0;
      if (animateDots) {
        final p = (((t - 0.2 * i) % 1.2) + 1.2) % 1.2 / 1.2;
        final lit = p < 0.4 ? p / 0.4 : 1 - (p - 0.4) / 0.6;
        alpha = 0.25 + 0.75 * lit.clamp(0.0, 1.0);
      }
      return TextSpan(
          text: '.',
          style: TextStyle(color: colors.muted.withValues(alpha: alpha)));
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Text.rich(
        TextSpan(
            style: base,
            children: [TextSpan(text: text), dot(0), dot(1), dot(2)]),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SlowMessage extends StatelessWidget {
  const _SlowMessage({super.key, required this.colors});

  final SplashColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Still getting ready',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your connection looks slow. The first time can take a little longer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17,
            height: 1.45,
            color: colors.muted,
          ),
        ),
      ],
    );
  }
}

/// Shown when the app could not start at all (for example Firebase did not
/// answer). Plain words, and one big button.
class StartupFailedScreen extends StatelessWidget {
  const StartupFailedScreen({super.key, required this.onRetry, this.detail});

  final VoidCallback onRetry;

  /// What went wrong, for the person who owns the app. Only shown in debug.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = SplashColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.16),
          radius: 0.95,
          colors: [c.blush, c.background],
          stops: const [0, 0.62],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Tile(color: Color(0xFF8A8F95)),
                const SizedBox(height: 28),
                Text(
                  "We couldn't start BusLink",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    height: 1.15,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your internet connection, then try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    height: 1.45,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 300,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 22),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFBA181B),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 19,
                          fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(29)),
                    ),
                  ),
                ),
                if (kDebugMode && detail != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: c.muted,
                        fontFamily: 'monospace',
                        height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

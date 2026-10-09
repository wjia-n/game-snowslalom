import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import 'menu_screen.dart';

/// Launch splash, single flow in two beats:
///  1. WAJIHA company moment (official winged-W logo, untouched asset).
///  2. Game splash: logo + name, animated loading line, "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Beat 1: company splash moment.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _companyMoment = false);
    // Beat 2: game splash with animated loading line.
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_companyMoment) return _companySplash();
    return _gameSplash();
  }

  /// The WAJIHA company moment: official logo, untouched, on black.
  Widget _companySplash() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const Text(
              'WAJIHA',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameSplash() {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2E),
      body: AlpineBackdrop(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: theme.accent.withValues(alpha: 0.9), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/snowslalom_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('SNOW SLALOM',
                  style: Alpine.display(44, theme: theme)),
              const SizedBox(height: 6),
              Text('CARVE THE MOUNTAIN',
                  style: Alpine.label(13, theme: theme)),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent
                                  .withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: theme.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Waxing the skis…'
                            : 'Ready!',
                        style: Alpine.body(13,
                            theme: theme,
                            color: theme.hudText
                                .withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text('Credits: WAJIHA',
                      style: Alpine.label(14, theme: theme)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

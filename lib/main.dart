import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SlalomSettings();
  await settings.load();
  final audio = SlalomAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SnowSlalomApp(settings: settings, audio: audio));
}

class SnowSlalomApp extends StatefulWidget {
  final SlalomSettings settings;
  final SlalomAudio audio;
  const SnowSlalomApp(
      {super.key, required this.settings, required this.audio});

  @override
  State<SnowSlalomApp> createState() => _SnowSlalomAppState();
}

class _SnowSlalomAppState extends State<SnowSlalomApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally freezes its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Snow Slalom',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor:
              widget.settings.theme.skyTop,
        ),
        home: Builder(
          builder: (ctx) {
            // Keep the status bar readable over any mountain sky.
            final t = widget.settings.theme;
            final dark = t.night ||
                t.skyTop.computeLuminance() < 0.35;
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
              ),
            );
            return SplashScreen(
                audio: widget.audio,
                settings: widget.settings);
          },
        ),
      ),
    );
  }
}

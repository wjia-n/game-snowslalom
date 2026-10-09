import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/slalom_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import '../theme/mountain_themes.dart';

/// The race screen: custom-painted alpine slope, HUD, steering, pause,
/// results with share + review. The [SlalomEngine] owns all state.
class SlalomGameScreen extends StatefulWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;
  final SlalomEngine engine;

  const SlalomGameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
  });

  @override
  State<SlalomGameScreen> createState() => _SlalomGameScreenState();
}

class _SlalomGameScreenState extends State<SlalomGameScreen>
    with WidgetsBindingObserver {
  SlalomEngine get _e => widget.engine;
  MountainThemeDef get _t => widget.settings.theme;
  bool _shared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _e.onEvent = _onEvent;
    widget.audio.startGameMusic();
    _e.startRace();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.onEvent = null;
    _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _e.racing && !_e.paused) {
      _e.setPaused(true);
    }
  }

  void _onEvent(SlalomEvent ev) {
    final a = widget.audio;
    switch (ev) {
      case SlalomEvent.countdownBeep:
        a.beep();
        break;
      case SlalomEvent.go:
        a.beep(finalTick: true);
        a.gameStart();
        break;
      case SlalomEvent.gateHit:
        a.gate();
        break;
      case SlalomEvent.gateNear:
        a.nearMiss();
        break;
      case SlalomEvent.gateMiss:
        a.miss();
        break;
      case SlalomEvent.crash:
        a.crash();
        break;
      case SlalomEvent.carve:
        a.carve();
        break;
      case SlalomEvent.runDone:
        a.click();
        break;
      case SlalomEvent.raceDone:
        _onRaceDone();
        break;
      case SlalomEvent.newBest:
        break;
    }
  }

  Future<void> _onRaceDone() async {
    final s = widget.settings;
    final e = _e;
    if (e.isScoreMode) {
      e.lastWasBest =
          await s.recordScore(s.diff.id, e.scoreTotals[e.winnerIndex ?? 0]);
    } else {
      e.lastWasBest =
          await s.recordTime(s.diff.id, e.totals[e.winnerIndex ?? 0]);
    }
    if (e.runnerNames.length > 1) {
      // Pass & Play winner counts as a win for the stats.
      await s.recordWin();
    }
    widget.audio.win();
    // Sensible review moment: 3+ finished games or a fresh best.
    if ((s.gamesPlayed >= 3 && s.gamesPlayed % 3 == 0) || e.lastWasBest) {
      _maybeReview();
    }
  }

  Future<void> _maybeReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {}
  }

  void _share() {
    if (_shared) return;
    _shared = true;
    final e = _e;
    final result = e.isScoreMode
        ? '${e.scoreTotals[e.winnerIndex ?? 0]} pts'
        : '${e.totals[e.winnerIndex ?? 0].toStringAsFixed(1)}s';
    Share.share(
      'I carved $result in Snow Slalom ⛷️! Think you can beat me?\n'
      'https://play.google.com/store/apps/details?id=com.gameswajiha.snowslalom',
    );
  }

  void _pauseDialog() {
    widget.audio.click();
    _e.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(
        theme: _t,
        onResume: () {
          widget.audio.click();
          Navigator.of(context).pop();
          _e.setPaused(false);
        },
        onRestart: () {
          widget.audio.click();
          Navigator.of(context).pop();
          _e.setPaused(false);
          _e.startRace();
        },
        onQuit: () {
          widget.audio.click();
          Navigator.of(context).pop();
          widget.audio.startMenuMusic();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _steer(DragUpdateDetails d, double width) {
    if (!_e.racing || _e.paused) return;
    // Absolute horizontal position -> steer; vertical flick -> tuck.
    final x = (d.localPosition.dx / width * 2 - 1).clamp(-1.0, 1.0);
    _e.steer = x;
    if (d.delta.dy < -6) {
      _e.tuck = true;
    } else if (d.delta.dy > 6) {
      _e.tuck = false;
    }
  }

  void _endSteer() {
    _e.steer = 0;
    _e.tuck = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ListenableBuilder(
      listenable: _e,
      builder: (_, _) => Scaffold(
        backgroundColor: t.skyTop,
        body: SafeArea(
          child: Column(
            children: [
              _hud(t),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (d) =>
                      _steer(d, MediaQuery.of(context).size.width),
                  onPanEnd: (_) => _endSteer(),
                  onPanCancel: _endSteer,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MountainPainter(
                            engine: _e,
                            theme: t,
                            skier: widget.settings.skierStyle,
                            time: DateTime.now()
                                    .millisecondsSinceEpoch /
                                1000,
                          ),
                        ),
                      ),
                      _banner(t),
                      if (_e.phase == Phase.countdown)
                        Center(
                          child: Text(
                            '${_e.countdown}',
                            style: Alpine.display(110, theme: t),
                          ),
                        ),
                      if (_e.phase == Phase.over) _results(t),
                    ],
                  ),
                ),
              ),
              _controls(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud(MountainThemeDef t) {
    final e = _e;
    final main = e.isScoreMode
        ? '${e.score} pts'
        : '${e.runTime.toStringAsFixed(1)}s';
    final sub = e.isScoreMode
        ? 'streak x${e.streak}'
        : '✅${e.hits} ❌${e.misses}';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.hud.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.hudText.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.pause_rounded, color: t.hudText),
            onPressed: (e.racing || e.phase == Phase.countdown) && !e.paused
                ? _pauseDialog
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.runnerName,
                    style: Alpine.label(11, theme: t),
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Run ${e.runNumber}/${e.totalRuns} • $sub',
                  style: Alpine.body(12, theme: t,
                      color: t.hudText.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Text(main, style: Alpine.title(22, theme: t)),
        ],
      ),
    );
  }

  Widget _banner(MountainThemeDef t) {
    if (_e.banner.isEmpty || _e.phase == Phase.over) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.accent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_e.banner,
                  style: Alpine.title(17, theme: t),
                  textAlign: TextAlign.center),
              if (_e.subBanner.isNotEmpty)
                Text(_e.subBanner,
                    style: Alpine.body(12, theme: t,
                        color: t.hudText.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(MountainThemeDef t) {
    if (_e.phase == Phase.over) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tuck button (also drag up).
          GestureDetector(
            onTapDown: (_) {
              if (_e.racing) _e.tuck = true;
            },
            onTapUp: (_) => _e.tuck = false,
            onTapCancel: () => _e.tuck = false,
            child: _ctrlCircle(t, Icons.bolt_rounded, 'TUCK', _e.tuck),
          ),
          Text(
            _e.racing
                ? 'Drag to steer • hold TUCK for speed'
                : 'Get ready…',
            style: Alpine.body(12, theme: t,
                color: t.hudText.withValues(alpha: 0.85)),
          ),
          // Brake button (also drag down).
          GestureDetector(
            onTapDown: (_) {
              if (_e.racing) _e.tuck = false;
            },
            child: _ctrlCircle(t, Icons.slow_motion_video_rounded,
                'EASY', false),
          ),
        ],
      ),
    );
  }

  Widget _ctrlCircle(
      MountainThemeDef t, IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? t.accent : t.hud.withValues(alpha: 0.9),
            border: Border.all(
                color: active ? t.accentDark : t.hudText.withValues(alpha: 0.4),
                width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 4),
        Text(label, style: Alpine.label(10, theme: t)),
      ],
    );
  }

  Widget _results(MountainThemeDef t) {
    final e = _e;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Alpine.panel(
              theme: t,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏁', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 6),
                  Text('Race complete!',
                      style: Alpine.display(26, theme: t)),
                  const SizedBox(height: 4),
                  Text(e.banner,
                      style: Alpine.title(17, theme: t),
                      textAlign: TextAlign.center),
                  if (e.lastWasBest)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: t.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('NEW BEST! 🏆',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ...[
                    for (var i = 0; i < e.runnerNames.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${i == e.winnerIndex ? '👑 ' : ''}${e.runnerNames[i]}',
                              style: Alpine.body(15, theme: t),
                            ),
                            Text(
                              e.isScoreMode
                                  ? '${e.scoreTotals[i]} pts'
                                  : '${e.totals[i].toStringAsFixed(1)}s',
                              style: Alpine.title(16, theme: t),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      Alpine.button(
                        theme: t,
                        label: 'Race again',
                        emoji: '⛷️',
                        primary: true,
                        onTap: () {
                          widget.audio.click();
                          _shared = false;
                          e.startRace();
                        },
                      ),
                      Alpine.button(
                        theme: t,
                        label: 'Share',
                        emoji: '📣',
                        onTap: () {
                          widget.audio.click();
                          _share();
                        },
                      ),
                      Alpine.button(
                        theme: t,
                        label: 'Menu',
                        emoji: '🏠',
                        onTap: () {
                          widget.audio.click();
                          widget.audio.startMenuMusic();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseDialog extends StatelessWidget {
  final MountainThemeDef theme;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const _PauseDialog({
    required this.theme,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Alpine.panel(
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused ⏸️', style: Alpine.display(24, theme: theme)),
            const SizedBox(height: 16),
            Alpine.button(
                theme: theme,
                label: 'Resume',
                emoji: '▶️',
                primary: true,
                onTap: onResume),
            const SizedBox(height: 10),
            Alpine.button(
                theme: theme,
                label: 'Restart race',
                emoji: '🔄',
                onTap: onRestart),
            const SizedBox(height: 10),
            Alpine.button(
                theme: theme,
                label: 'Quit to menu',
                emoji: '🏠',
                onTap: onQuit),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The mountain: hand-painted pseudo-3D slope. Sky, peaks, snow with depth,
// pines, wooden gate poles with waving fabric flags, and the skier — all
// drawn per the active mountain theme + skier style.
// ---------------------------------------------------------------------------
class _MountainPainter extends CustomPainter {
  final SlalomEngine engine;
  final MountainThemeDef theme;
  final SkierStyle skier;
  final double time;

  _MountainPainter({
    required this.engine,
    required this.theme,
    required this.skier,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky.
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [theme.skyTop, theme.skyBottom],
    );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.42), Paint()..shader = sky.createShader(Rect.fromLTWH(0, 0, w, h * 0.42)));

    if (theme.night) _drawStars(canvas, w, h);
    _drawPeaks(canvas, w, h);

    // Snow slope with physical depth shading.
    final snow = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.snowLight, theme.snowShadow],
    );
    final slope = Path()
      ..moveTo(0, h * 0.30)
      ..quadraticBezierTo(w * 0.5, h * 0.22, w, h * 0.30)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(slope, Paint()..shader = snow.createShader(Rect.fromLTWH(0, h * 0.2, w, h * 0.8)));
    // Slope side shading for depth.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.30)
        ..quadraticBezierTo(w * 0.2, h * 0.26, 0, h)
        ..lineTo(0, h * 0.30)
        ..close(),
      Paint()..color = theme.snowShadow.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.30)
        ..quadraticBezierTo(w * 0.8, h * 0.26, w, h)
        ..lineTo(w, h * 0.30)
        ..close(),
      Paint()..color = theme.snowShadow.withValues(alpha: 0.5),
    );

    // Carved grooves trailing behind the skier.
    _drawGrooves(canvas, w, h);

    for (final t in engine.trees) {
      _drawTree(canvas, w, h, t);
    }
    for (final g in engine.gates) {
      _drawGate(canvas, w, h, g);
    }
    _drawParticles(canvas, w, h);

    final speedLines = engine.tuck && engine.racing;
    _drawSkier(canvas, w, h, speedLines);
    if (speedLines) _drawSpeedLines(canvas, w, h);
  }

  void _drawStars(Canvas canvas, double w, double h) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final r = Random(7);
    for (int i = 0; i < 60; i++) {
      final x = r.nextDouble() * w;
      final y = r.nextDouble() * h * 0.28;
      final s = 0.8 + r.nextDouble() * 1.4;
      final tw = 0.5 + 0.5 * sin(time * 2 + i);
      canvas.drawCircle(Offset(x, y), s * tw.clamp(0.2, 1.0), p);
    }
    // Moon.
    canvas.drawCircle(Offset(w * 0.82, h * 0.10), 22,
        Paint()..color = const Color(0xFFF5F0DC));
    canvas.drawCircle(Offset(w * 0.82 - 7, h * 0.10 - 4), 18,
        Paint()..color = theme.skyTop);
  }

  void _drawPeaks(Canvas canvas, double w, double h) {
    final base = h * 0.34;
    final r = Random(42);
    // Far ridge.
    final far = Path()..moveTo(0, base);
    for (int i = 0; i <= 8; i++) {
      final x = w * i / 8;
      final y = base - (i.isEven ? 1 : 0.45) * (0.10 + r.nextDouble() * 0.08) * h;
      far.lineTo(x, y);
    }
    far.lineTo(w, base);
    far.close();
    canvas.drawPath(far, Paint()..color = theme.peakFar);
    // Near ridge with snow caps.
    final near = Path()..moveTo(0, base + h * 0.04);
    final caps = <Offset>[];
    for (int i = 0; i <= 6; i++) {
      final x = w * i / 6;
      final y = base + h * 0.04 - (i.isEven ? 1 : 0.5) * (0.12 + r.nextDouble() * 0.06) * h;
      near.lineTo(x, y);
      if (i.isEven) caps.add(Offset(x, y));
    }
    near.lineTo(w, base + h * 0.04);
    near.close();
    canvas.drawPath(near, Paint()..color = theme.peakNear);
    for (final c in caps) {
      canvas.drawCircle(c, 10, Paint()..color = theme.snowLight.withValues(alpha: 0.9));
    }
  }

  void _drawGrooves(Canvas canvas, double w, double h) {
    // A fading trail behind the skier, like real carved tracks.
    final p = Paint()
      ..color = theme.groove
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final sx = w * 0.5 + engine.skierX * w * 0.42;
    final sy = SlalomEngine.skierY * h;
    for (int i = 1; i <= 6; i++) {
      final t = i / 6;
      final y = sy - t * h * 0.28;
      final sway = sin(time * 3 - i * 0.9) * 10 * t;
      canvas.drawCircle(
          Offset(sx + sway, y),
          5 * (1 - t) + 1,
          p..color = theme.groove.withValues(alpha: 0.55 * (1 - t)));
    }
  }

  void _drawTree(Canvas canvas, double w, double h, Tree t) {
    final x = w * 0.5 + t.x * w * 0.48;
    final y = t.y * h;
    final s = t.size * (0.7 + t.y * 0.5) * 34;
    if (y < -s || y > h + s) return;
    final trunk = Paint()..color = theme.pole;
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y + s * 0.42), width: s * 0.14, height: s * 0.3), trunk);
    final leaf = Paint()..color = theme.treeDark;
    final snow = Paint()..color = theme.treeSnow;
    for (int i = 0; i < 3; i++) {
      final ty = y - s * 0.35 + i * s * 0.32;
      final tw = s * (0.75 - i * 0.16);
      final tri = Path()
        ..moveTo(x, ty - s * 0.34)
        ..lineTo(x - tw / 2, ty + s * 0.14)
        ..lineTo(x + tw / 2, ty + s * 0.14)
        ..close();
      canvas.drawPath(tri, leaf);
      // Snow dusting on each tier.
      canvas.drawPath(
        Path()
          ..moveTo(x, ty - s * 0.34)
          ..lineTo(x - tw / 4, ty - s * 0.08)
          ..lineTo(x + tw / 4, ty - s * 0.08)
          ..close(),
        snow,
      );
    }
    // Soft shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 4, y + s * 0.58), width: s * 0.7, height: s * 0.16),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
  }

  void _drawGate(Canvas canvas, double w, double h, Gate g) {
    final cx = w * 0.5 + g.x * w * 0.42;
    final y = g.y * h;
    final s = (0.55 + g.y * 0.65); // grows as it approaches
    if (y < -80 || y > h + 80) return;
    final gap = 52.0 * s;
    final poleH = 64.0 * s;
    final judged = g.judged;
    final alpha = judged ? 0.45 : 1.0;
    final polePaint = Paint()..color = theme.pole.withValues(alpha: alpha);
    final flagColor = (g.red ? theme.gateRed : theme.gateBlue).withValues(alpha: alpha);

    for (final side in [-1, 1]) {
      final px = cx + side * gap;
      // Wooden pole with highlight.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(px, y - poleH / 2), width: 7 * s, height: poleH),
            Radius.circular(3 * s)),
        polePaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(px - 1.5 * s, y - poleH / 2), width: 2 * s, height: poleH),
        Paint()..color = Colors.white.withValues(alpha: 0.25 * alpha),
      );
    }
    // Fabric flag waving between the poles.
    final wave = sin(time * 6 + g.x * 8) * 4 * s;
    final flag = Path()
      ..moveTo(cx - gap, y - poleH + 6 * s)
      ..quadraticBezierTo(cx, y - poleH + 6 * s + wave, cx + gap, y - poleH + 6 * s)
      ..lineTo(cx + gap, y - poleH + 30 * s)
      ..quadraticBezierTo(cx, y - poleH + 30 * s + wave, cx - gap, y - poleH + 30 * s)
      ..close();
    canvas.drawPath(flag, Paint()..color = flagColor);
    // Flag shading fold.
    canvas.drawPath(
      Path()
        ..moveTo(cx - gap * 0.4, y - poleH + 6 * s + wave * 0.4)
        ..lineTo(cx - gap * 0.1, y - poleH + 6 * s + wave * 0.4)
        ..lineTo(cx - gap * 0.1, y - poleH + 30 * s + wave * 0.4)
        ..lineTo(cx - gap * 0.4, y - poleH + 30 * s + wave * 0.4)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.12 * alpha),
    );

    // Judgement flash: bright ring on hit, red X on miss.
    if (g.judgeFlash > 0) {
      if (g.hit) {
        canvas.drawCircle(
          Offset(cx, y - poleH / 2),
          30 * s * g.judgeFlash,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7 * g.judgeFlash)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        _drawCheck(canvas, Offset(cx, y - poleH - 20 * s), 14 * s,
            Colors.white.withValues(alpha: g.judgeFlash));
      } else {
        final p = Paint()
          ..color = const Color(0xFFE0442E).withValues(alpha: g.judgeFlash)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
        final c = Offset(cx, y - poleH - 20 * s);
        const r = 12.0;
        canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), p);
        canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), p);
      }
    }
  }

  void _drawCheck(Canvas canvas, Offset c, double s, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s * 0.45
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c + Offset(-s, 0), c + Offset(-s * 0.2, s * 0.7), p);
    canvas.drawLine(c + Offset(-s * 0.2, s * 0.7), c + Offset(s, -s * 0.8), p);
  }

  void _drawParticles(Canvas canvas, double w, double h) {
    final p = Paint()..color = Colors.white;
    for (final pt in engine.particles) {
      final a = (pt.life * 2.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(w * 0.5 + pt.x * w * 0.42, pt.y * h),
        3.2,
        p..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  void _drawSkier(Canvas canvas, double w, double h, bool speedLines) {
    final x = w * 0.5 + engine.skierX * w * 0.42;
    final y = SlalomEngine.skierY * h;
    final lean = engine.skierVX * 0.22 + engine.steer * 0.15;
    final tucked = engine.tuck;
    final s = 1.0; // scale

    // Drop shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 6, y + 26 * s), width: 64 * s, height: 14 * s),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(lean);

    final suit = Paint()..color = skier.suit;
    final pants = Paint()..color = skier.pants;
    final helmet = Paint()..color = skier.helmet;
    final skiPaint = Paint()..color = skier.skis;
    final skin = Paint()..color = const Color(0xFFF2C9A0);

    final crouch = tucked ? 10.0 : 0.0;

    // Skis.
    for (final off in [-9.0, 9.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(off * s, 24 * s), width: 7 * s, height: 58 * s),
            Radius.circular(3.5 * s)),
        skiPaint,
      );
      // Ski tip curl.
      canvas.drawCircle(Offset(off * s, -5 * s), 3.5 * s, skiPaint);
    }
    // Boots.
    canvas.drawRect(Rect.fromCenter(center: const Offset(-9, 12), width: 10, height: 8), Paint()..color = const Color(0xFF2B2B33));
    canvas.drawRect(Rect.fromCenter(center: const Offset(9, 12), width: 10, height: 8), Paint()..color = const Color(0xFF2B2B33));

    // Legs (pants).
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-7 * s, 2 * s + crouch * 0.4), width: 11 * s, height: 24 * s), Radius.circular(5 * s)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(7 * s, 2 * s + crouch * 0.4), width: 11 * s, height: 24 * s), Radius.circular(5 * s)),
      pants,
    );
    // Torso (suit) — leaned forward.
    canvas.save();
    canvas.rotate(-0.25 - (tucked ? 0.35 : 0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -18 * s + crouch * 0.6), width: 24 * s, height: 30 * s), Radius.circular(10 * s)),
      suit,
    );
    // Suit highlight.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-6 * s, -18 * s + crouch * 0.6), width: 6 * s, height: 26 * s), Radius.circular(3 * s)),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.restore();

    // Arms with poles.
    for (final side in [-1, 1]) {
      canvas.drawLine(Offset(side * 12 * s, -14 * s + crouch * 0.5),
          Offset(side * 22 * s, 6 * s), suit..strokeWidth = 7 * s);
      canvas.drawLine(Offset(side * 22 * s, 6 * s),
          Offset(side * 26 * s, 26 * s), Paint()..color = const Color(0xFF2B2B33)..strokeWidth = 3 * s);
    }

    // Head + helmet + goggles.
    canvas.drawCircle(Offset(0, -40 * s + crouch * 0.7), 11 * s, skin);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, -42 * s + crouch * 0.7), radius: 12 * s),
        pi, 2 * pi, false, helmet..strokeWidth = 9 * s..style = PaintingStyle.stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(2 * s, -40 * s + crouch * 0.7), width: 20 * s, height: 8 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF1B2A3A),
    );

    canvas.restore();
  }

  void _drawSpeedLines(Canvas canvas, double w, double h) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final r = Random(3);
    for (int i = 0; i < 8; i++) {
      final y = r.nextDouble() * h;
      final x = r.nextDouble() * w;
      final len = 30 + r.nextDouble() * 50;
      canvas.drawLine(Offset(x, y), Offset(x, y + len), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MountainPainter old) => true;
}

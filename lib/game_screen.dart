import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Ski slalom: steer through gates, 3 runs, lowest total time wins.
class SnowSlalomScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const SnowSlalomScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SnowSlalomScreen> createState() => _SnowSlalomScreenState();
}

class _Gate {
  double x; // center, -1..1
  double y; // -0.2..1.2, grows as it approaches
  bool judged = false;
  _Gate(this.x, this.y);
}

class _SnowSlalomScreenState extends State<SnowSlalomScreen> {
  static const _bestKey = 'snowslalom_best';
  static const runs = 3;
  static const gatesPerRun = 18;
  static const missPenalty = 5.0;

  final _rand = Random();
  Ticker? _ticker;
  double _lastT = 0;

  bool racing = false;
  bool over = false;
  int run = 0;
  double runTime = 0;
  double totalTime = 0;
  int gatesHit = 0;
  int gatesMissed = 0;
  List<double> runTotals = [];
  double best = 0;

  double skierX = 0;
  double speedMul = 1.0; // 0.7 brake .. 1.6 tuck
  List<_Gate> gates = [];
  List<double> trees = []; // decorative tree y positions
  double _treeSeed = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => best = prefs.getDouble(_bestKey) ?? 0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _startRace() {
    Sfx.click();
    setState(() {
      racing = true;
      over = false;
      run = 0;
      totalTime = 0;
      runTotals = [];
    });
    _startRun();
  }

  void _startRun() {
    run++;
    runTime = 0;
    gatesHit = 0;
    gatesMissed = 0;
    skierX = 0;
    speedMul = 1.0;
    gates = List.generate(gatesPerRun, (i) => _Gate(_rand.nextDouble() * 1.4 - 0.7, -0.25 - i * 0.55));
    trees = List.generate(14, (_) => _rand.nextDouble() * 1.2);
    _treeSeed = _rand.nextDouble();
    _lastT = 0;
    _ticker?.dispose();
    _ticker = Ticker(_tick)..start();
    if (mounted) setState(() {});
    Sfx.move();
  }

  void _tick(Duration d) {
    final t = d.inMicroseconds / 1e6;
    final dt = _lastT == 0 ? 0.016 : min(0.05, t - _lastT);
    _lastT = t;
    if (!mounted || !racing) return;
    if (ModalRoute.of(context)?.isCurrent != true) return; // freeze under dialogs
    setState(() {
      runTime += dt;
      const baseSpeed = 0.42;
      final dy = baseSpeed * speedMul * dt;
      for (final g in gates) {
        g.y += dy;
        if (!g.judged && g.y >= 0.78) {
          g.judged = true;
          if ((skierX - g.x).abs() < 0.22) {
            gatesHit++;
            Sfx.tap();
          } else {
            gatesMissed++;
            runTime += missPenalty;
            Sfx.lose();
          }
        }
      }
      for (var i = 0; i < trees.length; i++) {
        trees[i] += dy * 1.4;
        if (trees[i] > 1.25) trees[i] = -0.15;
      }
      gates.removeWhere((g) => g.y > 1.25);
      if (gatesHit + gatesMissed >= gatesPerRun) _endRun();
    });
  }

  void _endRun() {
    _ticker?.stop();
    final total = runTime;
    runTotals.add(total);
    totalTime += total;
    widget.players[0].score = totalTime.round();
    widget.callbacks.refreshHud();
    Sfx.win();
    if (run >= runs) {
      _finishRace();
    } else {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && racing && !over) _startRun();
      });
    }
    setState(() {});
  }

  Future<void> _finishRace() async {
    over = true;
    racing = false;
    final isBest = best == 0 || totalTime < best;
    if (isBest) {
      best = totalTime;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_bestKey, best);
    }
    if (!mounted) return;
    final runs = runTotals.map((r) => '${r.toStringAsFixed(1)}s').join(' • ');
    widget.callbacks.finish(
      headline: 'Finished! Total ${totalTime.toStringAsFixed(1)}s ⛷️',
      subline: 'Runs: $runs${isBest ? ' — NEW BEST! 🏆' : ' — best: ${best.toStringAsFixed(1)}s'}',
    );
  }

  void _steer(DragUpdateDetails d, double width) {
    if (!racing || over) return;
    setState(() {
      skierX = (skierX + d.delta.dx / width * 2.2).clamp(-1.0, 1.0);
      speedMul = (speedMul - d.delta.dy / 400).clamp(0.7, 1.6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return Column(
      children: [
        _hud(theme),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => _steer(d, MediaQuery.of(context).size.width),
            onVerticalDragUpdate: (d) => _steer(d, MediaQuery.of(context).size.width),
            child: _mountain(theme),
          ),
        ),
        const SizedBox(height: 8),
        if (!racing && !over)
          WajihaButton(label: 'Start run 1', emoji: '⛷️', primary: true, onTap: _startRace),
        if (racing)
          Text(
            speedMul > 1.25 ? 'TUCKED! 💨' : speedMul < 0.9 ? 'Braking… 🐢' : 'Drag up = tuck • down = brake',
            style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _hud(GameTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _cell(t, 'Run', racing ? '$run/$runs' : '–'),
          _cell(t, 'Time', '${runTime.toStringAsFixed(1)}s'),
          _cell(t, 'Gates', '✅$gatesHit ❌$gatesMissed'),
          _cell(t, 'Best', best == 0 ? '–' : '${best.toStringAsFixed(1)}s'),
        ],
      ),
    );
  }

  Widget _cell(GameTheme t, String label, String value) => Column(
        children: [
          Text(label, style: TextStyle(color: t.muted, fontSize: 11, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      );

  Widget _mountain(GameTheme t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: t.radius,
        gradient: const LinearGradient(
          colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (ctx, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          const skierY = 0.78;
          return Stack(
            children: [
              for (var i = 0; i < trees.length; i++)
                Positioned(
                  top: trees[i] * h,
                  left: ((i * 0.37 + _treeSeed) % 1.0) * (w - 40),
                  child: const Text('🌲', style: TextStyle(fontSize: 30)),
                ),
              for (final g in gates)
                ..._gateWidgets(g, w, h),
              Positioned(
                top: skierY * h - 20,
                left: w * 0.5 + skierX * w * 0.42 - 20,
                child: Transform.rotate(
                  angle: skierX * 0.5,
                  child: const Text('⛷️', style: TextStyle(fontSize: 40)),
                ),
              ),
              if (!racing && !over)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                    child: const Text('Drag to steer through the gates! 🎿',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16), textAlign: TextAlign.center),
                  ),
                ),
              if (racing && gatesHit + gatesMissed >= gatesPerRun && run < runs)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
                    child: Text('Run $run done: ${runTotals.isNotEmpty ? runTotals.last.toStringAsFixed(1) : ''}s! ✅$gatesHit ❌$gatesMissed',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _gateWidgets(_Gate g, double w, double h) {
    final cx = w * 0.5 + g.x * w * 0.42;
    const gapPx = 46.0;
    final alpha = g.judged ? 0.35 : 1.0;
    return [
      Positioned(
        top: g.y * h - 24,
        left: cx - gapPx - 14,
        child: Opacity(opacity: alpha, child: const Text('🚩', style: TextStyle(fontSize: 28))),
      ),
      Positioned(
        top: g.y * h - 24,
        left: cx + gapPx - 14,
        child: Opacity(opacity: alpha, child: const Text('🚩', style: TextStyle(fontSize: 28))),
      ),
    ];
  }
}

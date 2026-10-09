import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../theme/mountain_themes.dart';

/// Race phases owned entirely by the engine. The UI only renders.
/// No silent scoring: every gate judgement, crash and phase change emits
/// a [SlalomEvent] and updates [banner], so feedback is always visible.
enum Phase { idle, countdown, racing, runSummary, over }

enum SlalomEvent {
  countdownBeep,
  go,
  gateHit,
  gateNear,
  gateMiss,
  crash,
  carve,
  runDone,
  raceDone,
  newBest,
}

/// A slalom gate: two poles with a fabric flag between them.
class Gate {
  double x; // center, -1..1
  double y; // world y; grows as it approaches the skier
  final bool red; // red or blue flag
  bool judged = false;
  bool hit = false;
  double judgeFlash = 0; // 1 -> 0 decay for the judgement flash

  Gate(this.x, this.y, this.red);
}

class Tree {
  double x;
  double y;
  final double size;
  Tree(this.x, this.y, this.size);
}

class Particle {
  double x, y, vx, vy, life;
  Particle(this.x, this.y, this.vx, this.vy, this.life);
}

/// Engine-owned race state machine with a stuck-state watchdog.
///
/// Physics, gate judging, scoring and phase transitions all live here;
/// UI timers never drive game logic. [SlalomEngine.step] advances one
/// physics step; the periodic tick is just a driver that can be paused,
/// cancelled and re-armed without ever losing the logical state.
class SlalomEngine extends ChangeNotifier {
  final SlalomDifficulty diff;
  final String modeId; // timetrial | scoreattack | passplay
  final List<String> runnerNames;

  static const double skierY = 0.78;
  static const double hitWindow = 0.24;
  static const double nearWindow = 0.44;
  static const double missPenalty = 5.0; // seconds added per missed gate
  static const double crashPenalty = 2.0; // seconds added per tree crash
  static const int runsPerRunnerTimeTrial = 3;

  Phase phase = Phase.idle;
  bool paused = false;
  bool over = false;

  // Skier state.
  double skierX = 0;
  double skierVX = 0;
  double steer = 0; // -1..1 set by the UI
  bool tuck = false; // set by the UI

  // Run state.
  int runnerIndex = 0;
  int runIndex = 0; // 0-based run number for the current runner
  double runTime = 0;
  int hits = 0;
  int misses = 0;
  int nears = 0;
  int judgedGates = 0; // every gate judges exactly once (hit/near/miss)
  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  String banner = '';
  String subBanner = '';

  List<Gate> gates = [];
  List<Tree> trees = [];
  final List<Particle> particles = [];

  // Race totals.
  final List<List<double>> runTimes = []; // per runner: per-run times
  final List<List<int>> runScores = []; // per runner: per-run scores
  List<double> totals = []; // per runner: time total (timetrial/passplay)
  List<int> scoreTotals = []; // per runner: score total (scoreattack)
  int? winnerIndex;
  bool lastWasBest = false; // set by the screen after persisting

  int countdown = 3;

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(SlalomEvent event)? onEvent;

  final Random _rand;
  Timer? _phaseTimer; // single countdown / summary timer
  Timer? _tick; // physics tick driver
  Timer? _watchdog; // stuck-state recovery
  final Stopwatch _clock = Stopwatch();
  double _lastTickS = 0;
  double _stumble = 0; // tree-crash stumble timer (input frozen)
  double _crashCooldown = 0;
  double _carveCooldown = 0;
  bool _disposed = false;
  final bool _autoTick;

  int get runsPerRunner =>
      modeId == 'timetrial' ? runsPerRunnerTimeTrial : 1;
  int get totalRuns => runnerNames.length * runsPerRunner;
  int get runNumber => runnerIndex * runsPerRunner + runIndex + 1;
  String get runnerName => runnerNames[runnerIndex];
  bool get isScoreMode => modeId == 'scoreattack';
  bool get racing => phase == Phase.racing;

  SlalomEngine({
    required this.diff,
    required this.modeId,
    required this.runnerNames,
    int? seed,
    bool autoTick = true,
  })  : _rand = Random(seed),
        _autoTick = autoTick {
    banner = 'Get ready, ${runnerNames.first}!';
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  // ------------------------------------------------------------ lifecycle
  @override
  void dispose() {
    _disposed = true;
    _phaseTimer?.cancel();
    _tick?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _armPhase(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _phaseTimer?.cancel();
    _phaseTimer = Timer(d, () {
      _phaseTimer = null;
      if (!_disposed && !paused) fn();
    });
  }

  void _startTick() {
    if (_disposed || !_autoTick) return;
    _tick?.cancel();
    _clock
      ..reset()
      ..start();
    _lastTickS = 0;
    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_disposed || paused || phase != Phase.racing) return;
      final t = _clock.elapsedMicroseconds / 1e6;
      final dt = (t - _lastTickS).clamp(0.0, 0.05);
      _lastTickS = t;
      step(dt);
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
    _clock.stop();
  }

  /// Watchdog: re-arm any phase whose timer died without progress.
  /// Stuck states are impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused) return;
    if (phase == Phase.racing && _tick == null && _autoTick) {
      _startTick();
    } else if (phase == Phase.countdown && _phaseTimer == null) {
      _countdownStep();
    } else if (phase == Phase.runSummary && _phaseTimer == null) {
      _advanceAfterSummary();
    }
  }

  /// Pause: freeze physics + phase timers. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _phaseTimer?.cancel();
      _phaseTimer = null;
      _stopTick();
    } else {
      _recover();
      if (phase == Phase.racing) _startTick();
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- race flow
  void startRace() {
    if (_disposed) return;
    runnerIndex = 0;
    runIndex = 0;
    runTimes.clear();
    runScores.clear();
    for (var i = 0; i < runnerNames.length; i++) {
      runTimes.add([]);
      runScores.add([]);
    }
    totals = List.filled(runnerNames.length, 0);
    scoreTotals = List.filled(runnerNames.length, 0);
    winnerIndex = null;
    over = false;
    lastWasBest = false;
    _startCountdown();
  }

  void _startCountdown() {
    phase = Phase.countdown;
    countdown = 3;
    banner = '${runnerName} — run ${runIndex + 1}/${runsPerRunner}';
    subBanner = 'Get ready…';
    notifyListeners();
    _countdownStep();
  }

  void _countdownStep() {
    if (_disposed || paused || phase != Phase.countdown) return;
    if (countdown > 0) {
      onEvent?.call(SlalomEvent.countdownBeep);
      notifyListeners();
      _armPhase(const Duration(milliseconds: 700), () {
        countdown--;
        _countdownStep();
      });
    } else {
      onEvent?.call(SlalomEvent.go);
      _beginRun();
    }
  }

  void _beginRun() {
    runTime = 0;
    hits = 0;
    misses = 0;
    nears = 0;
    judgedGates = 0;
    score = 0;
    streak = 0;
    bestStreak = 0;
    skierX = 0;
    skierVX = 0;
    steer = 0;
    tuck = false;
    _stumble = 0;
    _crashCooldown = 0;
    _carveCooldown = 0;
    particles.clear();
    banner = 'GO!';
    subBanner = isScoreMode ? 'Thread gates for points!' : 'Thread every gate!';
    // Lay out gates down the slope.
    gates = List.generate(diff.gates, (i) {
      final x = (_rand.nextDouble() * 2 - 1) * diff.wander;
      return Gate(x.clamp(-0.95, 0.95), -0.25 - i * diff.gateGap,
          i.isEven);
    });
    trees = List.generate(diff.trees, (_) {
      return Tree(_rand.nextDouble() * 2 - 1, _rand.nextDouble() * 1.4 - 0.2,
          0.7 + _rand.nextDouble() * 0.6);
    });
    phase = Phase.racing;
    notifyListeners();
    _startTick();
  }

  /// One physics step. Also callable from tests with [_autoTick] = false.
  @visibleForTesting
  void step(double dt) {
    if (phase != Phase.racing || paused || _disposed || over) return;
    runTime += dt;

    // --- skier steering: velocity follows input, giving weighty carves.
    final frozen = _stumble > 0;
    final targetV = frozen ? 0.0 : steer * 2.6;
    skierVX += (targetV - skierVX) * min(1.0, dt * 8);
    skierX += skierVX * dt * 0.55;
    if (skierX < -1) {
      skierX = -1;
      skierVX = skierVX.abs() * 0.4;
    } else if (skierX > 1) {
      skierX = 1;
      skierVX = -skierVX.abs() * 0.4;
    }

    // Carve spray + sound on hard turns.
    _carveCooldown -= dt;
    if (!frozen && skierVX.abs() > 1.7 && _carveCooldown <= 0) {
      _carveCooldown = 0.45;
      _spray(skierX, skierY, 6, -sign(skierVX));
      onEvent?.call(SlalomEvent.carve);
    }

    // --- world scroll.
    final speedMul = frozen ? 0.25 : (tuck ? 1.55 : 1.0);
    final dy = diff.speed * speedMul * dt;
    for (final g in gates) {
      g.y += dy;
      g.judgeFlash = max(0.0, g.judgeFlash - dt * 2.2);
      if (!g.judged && g.y >= skierY) _judgeGate(g);
    }
    for (final t in trees) {
      t.y += dy * 1.25;
      if (t.y > 1.3) {
        t.y = -0.2;
        t.x = _rand.nextDouble() * 2 - 1;
      }
    }

    // --- tree collision.
    _crashCooldown -= dt;
    _stumble -= dt;
    if (_crashCooldown <= 0 && _stumble <= 0) {
      for (final t in trees) {
        if ((t.y - skierY).abs() < 0.07 && (t.x - skierX).abs() < 0.09) {
          _crashCooldown = 1.4;
          _stumble = 0.9;
          runTime += crashPenalty;
          streak = 0;
          _spray(skierX, skierY, 14, 0);
          banner = 'CRASH! +${crashPenalty.toStringAsFixed(0)}s';
          subBanner = 'Shake it off!';
          onEvent?.call(SlalomEvent.crash);
          break;
        }
      }
    }

    // --- particles.
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += dt * 2.2;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);

    gates.removeWhere((g) => g.y > 1.35);
    // Every gate judges exactly once (hit / near / miss), so the judged
    // count — not hits+misses — is the run-completion signal (RULES.md §12).
    if (judgedGates >= diff.gates) _endRun();
    notifyListeners();
  }

  void _spray(double x, double y, int n, double dir) {
    for (int i = 0; i < n; i++) {
      particles.add(Particle(
        x + (_rand.nextDouble() - 0.5) * 0.06,
        y - 0.02,
        (_rand.nextDouble() - 0.5) * 1.4 + dir * 0.7,
        -_rand.nextDouble() * 1.6 - 0.4,
        0.35 + _rand.nextDouble() * 0.35,
      ));
    }
  }

  void _judgeGate(Gate g) {
    g.judged = true;
    g.judgeFlash = 1;
    judgedGates++;
    final d = (skierX - g.x).abs();
    if (d <= hitWindow) {
      g.hit = true;
      hits++;
      streak++;
      bestStreak = max(bestStreak, streak);
      if (isScoreMode) {
        final pts = 100 + 25 * (streak - 1);
        score += pts;
        banner = 'GATE! +$pts';
      } else {
        banner = streak >= 5 ? '$streak-GATE STREAK! 🔥' : 'Clean gate! ✅';
      }
      subBanner = streak >= 3 ? 'Streak x$streak — keep carving!' : '';
      _spray(g.x, skierY, 8, 0);
      onEvent?.call(SlalomEvent.gateHit);
    } else if (d <= nearWindow) {
      // Squeezed past the gate edge: no penalty, small style bonus.
      nears++;
      if (isScoreMode) {
        score += 25;
        banner = 'NEAR MISS! +25';
      } else {
        banner = 'Whoa — near miss! 😅';
      }
      subBanner = '';
      onEvent?.call(SlalomEvent.gateNear);
    } else {
      misses++;
      streak = 0;
      if (isScoreMode) {
        score = max(0, score - 50);
        banner = 'MISSED! −50';
      } else {
        runTime += missPenalty;
        banner = 'MISSED! +${missPenalty.toStringAsFixed(0)}s ⏱️';
      }
      subBanner = 'Aim between the flags!';
      onEvent?.call(SlalomEvent.gateMiss);
    }
  }

  void _endRun() {
    _stopTick();
    phase = Phase.runSummary;
    runTimes[runnerIndex].add(runTime);
    runScores[runnerIndex].add(score);
    final lastLabel = runNumber >= totalRuns ? 'Final run!' : 'Run $runNumber/$totalRuns done!';
    if (isScoreMode) {
      banner = '$lastLabel $score pts';
    } else {
      banner =
          '$lastLabel ${runTime.toStringAsFixed(1)}s  ✅$hits ❌$misses';
    }
    subBanner = _summaryLine();
    onEvent?.call(SlalomEvent.runDone);
    notifyListeners();
    _armPhase(const Duration(milliseconds: 2300), _advanceAfterSummary);
  }

  String _summaryLine() {
    final bits = <String>[];
    if (nears > 0) bits.add('$nears near ${nears == 1 ? 'miss' : 'misses'}');
    if (bestStreak >= 5) bits.add('best streak x$bestStreak 🔥');
    return bits.join(' • ');
  }

  void _advanceAfterSummary() {
    if (_disposed || paused || phase != Phase.runSummary) return;
    if (runIndex + 1 < runsPerRunner) {
      runIndex++;
      _startCountdown();
    } else if (runnerIndex + 1 < runnerNames.length) {
      runnerIndex++;
      runIndex = 0;
      _startCountdown();
    } else {
      _finishRace();
    }
  }

  void _finishRace() {
    _stopTick();
    over = true;
    phase = Phase.over;
    if (isScoreMode) {
      for (var i = 0; i < runnerNames.length; i++) {
        scoreTotals[i] = runScores[i].fold(0, (a, b) => a + b);
      }
      var best = 0;
      for (var i = 1; i < runnerNames.length; i++) {
        if (scoreTotals[i] > scoreTotals[best]) best = i;
      }
      winnerIndex = best;
      banner = '${runnerNames[best]} wins with ${scoreTotals[best]} pts! 🏆';
    } else {
      for (var i = 0; i < runnerNames.length; i++) {
        totals[i] = runTimes[i].fold(0.0, (a, b) => a + b);
      }
      var best = 0;
      for (var i = 1; i < runnerNames.length; i++) {
        if (totals[i] < totals[best]) best = i;
      }
      winnerIndex = best;
      banner =
          '${runnerNames[best]} wins! ${totals[best].toStringAsFixed(1)}s 🏆';
    }
    subBanner = _podiumLine();
    onEvent?.call(SlalomEvent.raceDone);
    notifyListeners();
  }

  String _podiumLine() {
    final rows = <String>[];
    for (var i = 0; i < runnerNames.length; i++) {
      final v = isScoreMode
          ? '${scoreTotals[i]} pts'
          : '${totals[i].toStringAsFixed(1)}s';
      rows.add('${i + 1}. ${runnerNames[i]} — $v');
    }
    return rows.join('   ');
  }

  double sign(double v) => v == 0 ? 0 : (v > 0 ? 1 : -1);
}

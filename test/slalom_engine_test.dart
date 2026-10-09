import 'package:flutter_test/flutter_test.dart';
import 'package:snowslalom/engine/slalom_engine.dart';
import 'package:snowslalom/theme/mountain_themes.dart';

/// RULES.md §13 test cases for the Snow Slalom engine.
///
/// The engine owns its phase timers; tests drive the public API and wait
/// out the (short) phase durations. Physics is driven directly via
/// [SlalomEngine.step] with autoTick disabled for determinism.
SlalomEngine makeEngine({
  String mode = 'timetrial',
  int diffIndex = 0,
  List<String> runners = const ['Ace'],
}) {
  return SlalomEngine(
    diff: SlalomDifficulty.all[diffIndex],
    modeId: mode,
    runnerNames: runners,
    seed: 1234,
    autoTick: false,
  );
}

Future<void> waitForRacing(SlalomEngine e) async {
  await Future.delayed(const Duration(milliseconds: 2300));
  expect(e.phase, Phase.racing);
}

/// Judge every remaining gate as a clean hit, then wait for the summary.
Future<void> hitAllGates(SlalomEngine e) async {
  for (final g in e.gates) {
    if (g.judged) continue;
    g.y = SlalomEngine.skierY - 0.001;
    e.skierX = g.x;
    e.step(0.016);
  }
  expect(e.phase, Phase.runSummary);
  await Future.delayed(const Duration(milliseconds: 2500));
}

void main() {
  test('1. Countdown 3-2-1-GO always reaches racing', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    expect(e.phase, Phase.countdown);
    await waitForRacing(e);
    expect(e.gates.length, SlalomDifficulty.all[0].gates);
    expect(e.runTime, greaterThanOrEqualTo(0));
  });

  test('2. Gate hit: judged once, streak grows, no penalty', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    final g = e.gates.first;
    g.y = SlalomEngine.skierY - 0.001;
    e.skierX = g.x; // dead center
    e.step(0.016);
    expect(e.hits, 1);
    expect(e.streak, 1);
    expect(g.judged, true);
    final t = e.runTime;
    e.step(0.016); // gate already judged: nothing more happens
    expect(e.hits, 1);
    expect(e.runTime, greaterThanOrEqualTo(t));
  });

  test('3. Near miss: no penalty, streak preserved, +25 in score mode',
      () async {
    final e = makeEngine(mode: 'scoreattack');
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    final g = e.gates.first;
    g.y = SlalomEngine.skierY - 0.001;
    e.skierX = g.x + 0.30; // inside near window, outside hit window
    e.step(0.016);
    expect(e.nears, 1);
    expect(e.hits, 0);
    expect(e.misses, 0);
    expect(e.score, 25);
  });

  test('4. Missed gate: +5s penalty and streak reset (time mode)',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    // First land a hit to build a streak, then miss.
    final g0 = e.gates.first;
    g0.y = SlalomEngine.skierY - 0.001;
    e.skierX = g0.x;
    e.step(0.016);
    expect(e.streak, 1);
    final g1 = e.gates[1];
    g1.y = SlalomEngine.skierY - 0.001;
    e.skierX = (g1.x + 0.9).clamp(-1.0, 1.0);
    final before = e.runTime;
    e.step(0.016);
    expect(e.misses, 1);
    expect(e.streak, 0);
    expect(e.runTime, greaterThanOrEqualTo(before + 4.9));
  });

  test('5. Score mode: hit pays 100 + streak bonus, miss floors at 0',
      () async {
    final e = makeEngine(mode: 'scoreattack');
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    for (var i = 0; i < 2; i++) {
      final g = e.gates[i];
      g.y = SlalomEngine.skierY - 0.001;
      e.skierX = g.x;
      e.step(0.016);
    }
    expect(e.score, 100 + 125); // streak 1 -> 100, streak 2 -> 125
    final g = e.gates[2];
    g.y = SlalomEngine.skierY - 0.001;
    e.skierX = (g.x + 0.9).clamp(-1.0, 1.0);
    e.step(0.016);
    expect(e.score, 225 - 50);
  });

  test('6. Tree crash: +2s, stumble, cooldown blocks double-hit',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    final tree = e.trees.first;
    tree.x = e.skierX;
    tree.y = SlalomEngine.skierY;
    final before = e.runTime;
    e.step(0.016);
    expect(e.banner, contains('CRASH'));
    expect(e.runTime, greaterThanOrEqualTo(before + 1.9));
    // Cooldown: an immediate second step on the same tree adds nothing.
    final afterFirst = e.runTime;
    e.step(0.016);
    expect(e.runTime, lessThan(afterFirst + 1.0));
  });

  test('7. Full race: 3 runs complete, winner declared, totals summed',
      () async {
    final e = makeEngine(runners: ['Ace']);
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    await hitAllGates(e); // run 1 -> countdown run 2
    expect(e.phase, Phase.countdown);
    await waitForRacing(e);
    await hitAllGates(e); // run 2 -> countdown run 3
    await waitForRacing(e);
    await hitAllGates(e); // run 3 -> race over
    expect(e.phase, Phase.over);
    expect(e.over, true);
    expect(e.winnerIndex, 0);
    expect(e.runTimes[0].length, 3);
    final expected = e.runTimes[0].fold(0.0, (a, b) => a + b);
    expect(e.totals[0], expected);
  });

  test('8. Pause freezes physics; resume continues the same phase',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    e.setPaused(true);
    final t = e.runTime;
    e.step(0.5);
    expect(e.runTime, t); // frozen
    e.setPaused(false);
    expect(e.phase, Phase.racing);
    e.step(0.5);
    expect(e.runTime, greaterThan(t));
  });

  test('9. Steering is clamped to the slope, never leaves the course',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    e.steer = -1;
    for (var i = 0; i < 200; i++) {
      e.step(0.016);
    }
    expect(e.skierX, greaterThanOrEqualTo(-1.0));
    expect(e.skierX, lessThanOrEqualTo(1.0));
  });

  test('10. Pass & Play: each runner runs once, lowest time wins',
      () async {
    final e = makeEngine(runners: ['Ace', 'Bea']);
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    await hitAllGates(e); // Ace's run -> Bea's countdown
    expect(e.runnerIndex, 1);
    await waitForRacing(e);
    await hitAllGates(e); // Bea's run -> race over
    expect(e.phase, Phase.over);
    expect(e.winnerIndex, isNotNull);
    expect(e.runTimes[0].length, 1);
    expect(e.runTimes[1].length, 1);
  });

  test('11. Near misses still count toward run completion', () async {
    // Regression: the run must end once every gate is judged (RULES.md
    // §12), even when near misses are in the mix — they are neither hits
    // nor misses, so counting hits+misses would hang the run forever.
    final e = makeEngine();
    addTearDown(e.dispose);
    e.startRace();
    await waitForRacing(e);
    for (final g in e.gates) {
      if (g.judged) continue;
      g.y = SlalomEngine.skierY - 0.001;
      e.skierX = (g.x + 0.30).clamp(-1.0, 1.0); // near window edge
      e.step(0.016);
    }
    expect(e.phase, Phase.runSummary);
    expect(e.judgedGates, SlalomDifficulty.all[0].gates);
  });
}

# Snow Slalom

Carve down the mountain and thread every slalom gate. A complete,
original arcade slalom racer for Android by WAJIHA (wajiha.fun).

Package: `com.gameswajiha.snowslalom` — GitHub: `wjia-n/game-snowslalom`

## Modes

- **Time Trial** — 3 runs, lowest total time wins (missed gate: +5s).
- **Score Attack** (Pro) — 1 run, 100 pts per gate × streak bonus.
- **Pass & Play** — 2–4 skiers, one phone, lowest single-run time wins.

## Difficulties

Bunny Slope → Blue Run → Black Diamond (Pro): gate count, gate spacing,
speed and tree density all scale.

## Controls

- Drag horizontally anywhere to steer (carve turns spray snow).
- Flick up / hold TUCK for +55% speed; flick down / release to cruise.
- Pause, restart and quit from the HUD pause button.

## Features

- Engine-owned race state machine with a 3s stuck-state watchdog.
- 12 mountain themes + 10 skier styles + Pro custom skier creator.
- Renameable skiers, persisted as one order-safe JSON string.
- Synthesized menu music + gameplay BGM + full SFX (cached, busy-guard,
  pause/resume on lifecycle, pre-warmed on splash).
- Free vs Pro comparison screen, real Play Billing
  (`snowslalompro`, `snowslalomcoffee`, `snowslalomchocolate`),
  tip jar, restore purchases, share + in-app review.
- Best times/scores per difficulty, persisted locally.

## Build

```sh
flutter pub get
flutter analyze
flutter build apk --release
flutter build appbundle --release
```

Tests: `flutter test` (engine state machine + name-persistence tests).

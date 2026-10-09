# Snow Slalom — RULES.md
_Authoritative rules. If the implementation conflicts with this document, fix the implementation._

## 1. Objective
Carve down the mountain and thread every slalom gate. In Time Trial / Pass & Play the lowest total time wins; in Score Attack the highest point total wins.

## 2. Setup
- Portrait, touch controls. One race = a sequence of runs on a procedurally generated slope.
- Each run lays out N gates down the slope (N by difficulty: Bunny 14, Blue 18, Black Diamond 24), alternating red/blue fabric flags on wooden poles, plus decorative/collidable pine trees.
- The skier starts centered at the top; a 3-2-1-GO countdown begins every run.

## 3. Turn order
- Time Trial: 1 skier, 3 runs. Pass & Play: 2–4 skiers, 1 run each, passed phone-to-phone. Score Attack: 1 skier, 1 run.
- Runs always execute in runner order, run 1..N per runner. There is no skipping: a run that starts always finishes.

## 4. Legal moves
- Drag horizontally anywhere on the slope to steer (absolute position → steer −1..1).
- Flick up or hold TUCK to tuck for +55% speed; flick down / release to cruise.
- Threading a gate = the skier's center passes the judge line within ±0.24 of the gate center.

## 5. Illegal moves
- None possible by construction: steering is clamped to the slope (−1..1) and soft-bounces off the edges. There is no way to leave the course or skip a gate.

## 6. Captures
- N/A (racing game, no captures).

## 7. Special rules
- **Near miss:** passing within ±0.44 but outside the hit window = no penalty; +25 pts in Score Attack, streak preserved.
- **Missed gate:** Time Trial / Pass & Play: +5.0s time penalty. Score Attack: −50 pts (floor 0). Streak resets.
- **Tree crash:** colliding with a pine = +2.0s penalty, 0.9s stumble (steering frozen, speed cut), streak resets. 1.4s crash cooldown prevents chain-crashes from one tree.
- **Streaks:** consecutive clean gates build a streak; in Score Attack each gate pays 100 + 25×(streak−1).
- **Carving:** hard turns spray snow and play a carve sound (feedback only).

## 8. Scoring
- Time Trial: total = sum of 3 run times (each run time includes gate penalties). Lower is better.
- Pass & Play: total = the single run time per skier. Lower is better.
- Score Attack: points as in §7. Higher is better.

## 9. Winning conditions
- Time Trial / Pass & Play: the skier with the lowest total time. Single skier: beating your saved best.
- Score Attack: beating your saved best score.

## 10. Draw conditions
- Pass & Play: identical totals to 0.1s resolve by run order — the earlier runner wins (first across the line stands). No shared trophies.

## 11. AI strategy
- N/A — no bots. Difficulty is the mountain itself: Bunny Slope (slow, gentle gates), Blue Run (faster, wider wander), Black Diamond (blazing, brutal gate placement, more trees).

## 12. Edge cases
- App backgrounded mid-run: engine pauses (physics + timers freeze); resume re-arms the exact phase. Music pauses and resumes, never restarts.
- Dialog opened mid-run (pause menu, rename): same freeze behavior.
- All gates judged → run ends even if the skier is mid-stumble.
- Watchdog (3s): if any phase timer dies without progress (racing tick lost, countdown stuck, summary stuck), the engine re-arms that phase. Stuck states impossible by construction.
- Missed ALL gates: run still completes; total includes all penalties.

## 13. Test cases
1. Countdown 3→2→1→GO always reaches racing (engine test).
2. Gate judged exactly once when crossing the judge line (hit/near/miss by |dx| thresholds 0.24 / 0.44).
3. Miss adds exactly +5.0s (time modes) / −50 pts (score mode, floor 0).
4. Tree collision adds +2.0s, freezes steering for 0.9s, cooldown blocks double-hit.
5. After the last gate is judged the run ends; after the last run the race ends with a winner.
6. Pause freezes runTime; resume continues from the same phase.
7. Watchdog re-arms a lost racing tick without resetting runTime.
8. Player names persist order-exact across restarts (single JSON string, never StringList).

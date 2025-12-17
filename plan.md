# Think Football – Implementation Plan

Scope: build a strategic, non-player-controlled football game where the player shapes win probabilities via tactics. v0.1 focuses on a deterministic core, outcome-sampling events, and a simple 2.5D viewer with debugging overlays.

## Progress Checklist
- [x] Read `for agent ai/dialog with ai.md` and `for agent ai/spec_game.md` to lock design pillars (probability-first, minimal physics, core/render split).

## Milestones & Tasks

### M0 – Project Scaffolding
- [x] Choose toolchain (C++17/20) and set up CMake project with separate `core` (static lib) and `client` (executable) targets.
- [x] Vendor or link raylib; UI now uses raygui (imgui removed).
- [x] Establish folder layout (`core/`, `client/`, `ui/`, `assets/`, `third_party/`), add minimal README/dev notes.
- [x] Add basic CI or local scripts to build and run (optional if time-constrained).

### M1 – Core Simulation Skeleton
- [x] Define world/state structs: `PlayerState`, `PlayerStats`, `PlayerCondition`, `PlayerIntent`, `BallState`, `TeamState`, `WorldState`, `MatchClock`.
- [x] Implement deterministic tick loop (fixed `dt`), seeded RNG service for outcome sampling/replay.
- [x] Implement pitch zoning (5 lanes × 4 bands + special zones) and helpers to query zones for positions.
- [x] Add JSON save/load for `WorldState` + RNG seed to enable mid-match saves/replays.

### M2 – Movement & Ball Minimal
- [x] Implement `MovementBase` interface and `MovementArcade` stage-0 (seek/arrive, clamp speed, facing lerp).
- [x] Add simple player separation/avoidance to prevent overlap.
- [x] Implement ball state machine (`CONTROLLED`, `FREE_GROUND`, `FREE_AIR`) with light damping; keep Y as render parameter only.
- [x] Promote ball to first-class entity: flight profile (scheduled air trajectory), touch/owner tracking, single BallTick/BallKick*/BallClaimControl API for use by events/replay.

### M3 – AI Architecture
- [x] Implement `PlayerBrain` / `TeamBrain` / `GroupContext` scaffolding; decouple decision (brain) from execution (movement).
- [x] Player tick pipeline: `Brain -> Intent -> Movement -> State` respecting stats/condition constraints.
- [x] Basic team tactics parameters (line height, press intensity, width, directness, tempo) stored in `TeamState`.
- [x] Simple possession brain: chase when off-ball, dribble forward when on-ball, emit pass intents to nearby ahead teammates; central ball-claim/pass handling loop in client.

#### M3.1 – Current Gameplay Loop (ad-hoc)
- [x] Randomized 3v3 spawn per half, basic separation, heading indicators, clamp to pitch with resized render scale.
- [x] Simple goal detection + scoreboard; ball reset on score.
- [x] Pass/shot handling on client (ground kick, shooter/pass blocker to avoid instant reclaim).
- [x] Forward-only pass heuristic + near-goal shooting trigger.
- [x] Vision cones rendered/toggled; per-player awareness scaling.
- [x] Collision/contact: on close approach probabilistic steal/loose ball knock-out.

#### M3.2 – Toward Systemic AI (in progress)
- [ ] Decision lock cadence: cache action/target for ~0.25–0.3s to prevent frame-to-frame jitter; store per-player decision timer. (partially coded, needs clean integration)
- [ ] Player FSM (low tier): explicit states `Chase`, `Possess`, `Support`, `DefendPress`, `RecoverShape`, `Rest`; transitions use ball ownership, pressure distance, breath/fatigue, tactics flags.
- [ ] Priority tree (mid tier): on-ball `Shoot > Pass > Dribble > Hold`, off-ball `Press > BlockLane > RecoverShape`; tactics (width/line/tempo) adjust node weights/thresholds.
- [ ] Space grid (10×6) weighting: forward value, open space, ally/enemy density, touchline safety → suggest support targets and recover anchors.
- [ ] Explicit feasibility/risk checks: pass (4–35m, lane clearance, line safety, cooldown), dribble (corridor width, line risk, low breath/pressure) → selection rules: pass if feasible & dribble risky; else compare scores; escape if both risky.
- [ ] Execution re-validate: receiver still present within 5m; otherwise cancel pass/keep dribble.
- [ ] Tactics modulation & roles: bias support positions by team width/line; press intensity feeds pressure distance; future hook for roles (e.g., CB/FB/MF/FW) to gate behaviors.

#### M3.3 – Positional Logic
- [ ] Formation roles registry: 4-4-2 roles with per-role anchors for defensive/neutral/attacking phases and roaming bounds.
- [ ] Shape maintenance: blend role anchors with space-grid targets; enforce minimum spacing so lines don’t collapse to corners/flags.
- [ ] Phase handling: in-play vs dead-ball; on restarts freeze non-kicker at anchors (not corner flag), unlock after first non-kicker touch.
- [ ] Support via zone behavior: use `ZoneBehavior` (8-dir+hold) to steer support runs; role overrides (FB overlap, CDM hold, ST peel-off).
- [ ] Safety clamps: keep all anchors/targets within pitch margin; separate defenders/attackers by half-space to avoid all-in in one lane.
- [ ] Debug overlays: draw role anchors/roaming boxes and chosen support vectors.
- [ ] Emphasize space distribution: enforce per-line spacing and anchor adherence so players occupy different lanes/bands instead of clustering; validate via overlay.

### M3.4 – Directional/Probabilistic Behaviors (new)
- [ ] Role traits: add aggression, passPref, shootPref, dribblePref to `PlayerStats`; use to weight action choices.
- [ ] Zone×Role direction weights: per-zone (8 dirs + hold) blended with role traits to produce movement/support direction probabilities.
- [ ] Partial tactics layer: line/side-specific modifiers (e.g., overlap left, central press) applied atop zone/role weights; team tactics (width/line/tempo/directness) scale them.
- [ ] Action mapping: sampled direction biases pass/dribble/hold/shoot probabilities; enforce pass/shot distance bounds and lane clearance.
- [ ] Telemetry: expose chosen direction vector, action probabilities for debugging.

### M4 – Event Models & Match Rules
- [ ] Ground pass error model: intent → sampled landing/arrival/bounce using passGround, pressure, fatigue, distance; drive BallKickGround.
- [ ] Lob/cross model: sampled landing + hang time + apex using passLong; drive BallKickLob; integrate heading/contact windows.
- [ ] First-touch/trap/loose: resolve heavy-touch vs control vs lose using firstTouch/composure/pressure/fatigue/bounce; update BallClaimControl/BallKickGround.
- [ ] Set pieces & restarts polish: corner/goal-kick/throw-in routines with 1s delay, kick/passing options, positioning.
- [ ] Event logging hooks per touch/pass/shot for replay/debug.

### M5 – Spatial/Tactical Systems & Debug UI
- [ ] Space grid overlay + support anchors visualization; role/tactic-biased target selection (width/line/tempo).
- [ ] Vision/perception overlays (cones, lane blocks), intent arrows, ball landing markers.
- [ ] Simple control panel to tweak tactics live; start/pause/reset with seed.

### M6 – Determinism, Logging, Testing, Packaging
- [ ] Determinism checks: twin-seed runs, replay validation; unit tests for space grid, decision filters, RNG.
- [ ] Structured logging/tracing for AI decisions and event sampling (toggleable).
- [ ] Packaging/build notes, run scripts, and third-party license notice (raylib/raygui).

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

### M4 – Outcome Sampling (Events)
- [ ] Ground pass model: intent target + error model (distance, passer passGround, pressure, fatigue) → actual landing, arrival time, bounce intensity.
- [ ] Lob/cross model: similar error model using `passLong`; generate landing point + hang time profile → BallKickLob().
- [ ] Trap/first-touch resolution: success vs heavy-touch vs lose, based on firstTouch/composure/pressure/fatigue/bounce → BallClaimControl() or BallKickGround().
- [ ] Heading resolution: contact/on-target/off/whiff using cross quality + jump/targeting/heading + pressure → BallRegisterTouch() + BallKick*().
- [ ] Expose event logs for debugging/replay.

### M5 – Rendering & UI (raylib + raygui)
- [ ] Render pitch/top-down camera, players as circles/billboards, ball with ground/lob presentation.
- [ ] Debug overlays: zones grid, intents (target arrows), ball landing markers, event log panel.
- [ ] Simple control panel to tweak tactics parameters live; ability to start/pause/reset with fixed seed.

### M6 – Dev Experience & Testing
- [ ] Logging/tracing pipeline for outcome sampling and AI decisions (toggleable).
- [ ] Determinism checks: run two seeds to confirm identical outputs; minimal unit tests for utilities (zones, RNG).
- [ ] Packaging instructions: build/run commands in README; note third-party licenses (raygui, raylib).

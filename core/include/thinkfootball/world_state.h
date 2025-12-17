// Basic world/state definitions for Think Football core simulation.
#pragma once

#include <array>
#include <cstdint>
#include <random>
#include <string>
#include <vector>

#include "thinkfootball/types.h"
#include "thinkfootball/ball_state.h"
#include "thinkfootball/pitch_geom.h"

namespace tf
{
struct PlayerStats
{
    float speed{0.8f};
    float accel{0.5f};
    float control{0.5f};
    float passGround{0.5f};
    float passLong{0.5f};
    float shoot{0.5f};
    float defend{0.5f};
    float awareness{0.5f};
    float composure{0.5f};
    float endurance{0.5f};   // breath capacity: slows drain, speeds recovery
    // Behavioral tendencies (0..1): weigh decisions toward certain actions.
    float aggression{0.5f};
    float passPref{0.5f};
    float shootPref{0.5f};
    float dribblePref{0.5f};
    float holdPref{0.5f};
};

struct PlayerCondition
{
    float fatigue{0.0f};
    float pressure01{0.0f};
    float breath{1.0f};  // 0..1 snapshot of current breath/oxygen
};

enum class RequestedAction
{
    None,
    Pass,
    Shoot,
    Tackle,
    Clear
};

struct PlayerIntent
{
    Vec3 targetPos{};
    float desiredSpeed01{0.0f};
    Vec3 faceDir{};
    RequestedAction action{RequestedAction::None};
};

struct PlayerState
{
    Vec3 position{};
    Vec3 velocity{};
    float facingRadians{0.0f};
    bool hasBall{false};

    // Decision cache to reduce jitter.
    float nextDecisionTime{0.0f};
    Vec3 cachedTarget{};
    RequestedAction cachedAction{RequestedAction::None};
};

struct Player
{
    int id{0};
    std::string name{};
    std::string role{};  // short position label (e.g., LB, CAM)
    int teamIndex{0};
    PlayerStats stats{};
    PlayerCondition condition{};
    PlayerIntent intent{};
    PlayerState state{};
    std::mt19937_64 rng;  // per-player RNG
};

struct TeamTactics
{
    float defensiveLineHeight{0.5f};
    float pressIntensity{0.5f};
    float width{0.5f};
    float directness{0.5f};
    float tempo{0.5f};
};

struct Team
{
    std::string name{};
    TeamTactics tactics{};
    std::string formation{"4-4-2"};
    std::string style{"neutral"};
};

struct MatchClock
{
    float timeSeconds{0.0f};
    float deltaSeconds{0.0f};
};

struct WorldState
{
    MatchClock clock{};
    BallState ball{};
    PitchGeometry pitch{};
    std::array<Team, 2> teams{};
    std::vector<Player> players{};
    std::uint64_t rngSeed{0};
    std::mt19937_64 rng;
};

// Advance the deterministic clock; simulation systems are expected to run at fixed dt.
void AdvanceClock(WorldState& world, float dtSeconds);

// Initialize RNG with seed (updates rngSeed and engine).
void SeedRng(WorldState& world, std::uint64_t seed);

// Get reference to RNG engine (callers can draw distributions directly).
inline std::mt19937_64& Rng(WorldState& world) { return world.rng; }

// Fixed-timestep runner helper: advance N steps of dt.
inline void StepSimulation(WorldState& world, float dtSeconds, int steps)
{
    for (int i = 0; i < steps; ++i) AdvanceClock(world, dtSeconds);
}
}  // namespace tf

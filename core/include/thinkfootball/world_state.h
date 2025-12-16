// Basic world/state definitions for Think Football core simulation.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace tf
{
struct Vec3
{
    float x{0.0f};
    float y{0.0f};
    float z{0.0f};
};

enum class BallMode
{
    Controlled,
    FreeGround,
    FreeAir
};

struct PlayerStats
{
    float speed{0.5f};
    float accel{0.5f};
    float control{0.5f};
    float passGround{0.5f};
    float passLong{0.5f};
    float shoot{0.5f};
    float defend{0.5f};
    float awareness{0.5f};
    float composure{0.5f};
};

struct PlayerCondition
{
    float fatigue{0.0f};
    float pressure01{0.0f};
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
};

struct Player
{
    std::string name{};
    int teamIndex{0};
    PlayerStats stats{};
    PlayerCondition condition{};
    PlayerIntent intent{};
    PlayerState state{};
};

struct BallState
{
    Vec3 position{};
    Vec3 velocity{};
    BallMode mode{BallMode::FreeGround};
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
    std::array<Team, 2> teams{};
    std::vector<Player> players{};
    std::uint64_t rngSeed{0};
};

// Advance the deterministic clock; simulation systems are expected to run at fixed dt.
void AdvanceClock(WorldState& world, float dtSeconds);
}  // namespace tf

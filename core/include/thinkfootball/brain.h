#pragma once

#include <array>

#include "thinkfootball/world_state.h"
#include "thinkfootball/movement.h"

namespace tf
{
struct TeamRuntimeTactics
{
    float lineZ{0.0f};
    float speedScale{1.0f};
    float pressScale{1.0f};
    float halfWidth{0.0f};
};

struct GroupContext
{
    Vec3 ballPos{};
    float pitchWidth{0.0f};
    float pitchHeight{0.0f};
    std::array<TeamRuntimeTactics, 2> team{};
};

struct PlayerBrain
{
    virtual ~PlayerBrain() = default;
    virtual void Think(Player& player, const WorldState& world, const GroupContext& ctx, float dtSeconds) = 0;
};

struct TeamBrain
{
    void ThinkTeam(WorldState& world, float dtSeconds);
    void ApplyTactics(const WorldState& world, GroupContext& ctx);
};

// Simple baseline brain: chase ball.
struct BrainChaseBall : PlayerBrain
{
    void Think(Player& player, const WorldState& world, const GroupContext& ctx, float dtSeconds) override;
};

// Simple possession-aware brain: chase when off-ball, dribble forward when on-ball,
// optionally pass to a teammate ahead.
struct BrainSimplePossession : PlayerBrain
{
    void Think(Player& player, const WorldState& world, const GroupContext& ctx, float dtSeconds) override;
};

// Tick a player through brain -> movement pipeline.
void TickPlayerWithBrain(Player& player,
                         const WorldState& world,
                         const GroupContext& ctx,
                         MovementBase& movement,
                         PlayerBrain& brain,
                         float dtSeconds);
}  // namespace tf

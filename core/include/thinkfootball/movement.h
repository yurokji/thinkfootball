// Movement interfaces and simple arcade implementation.
#pragma once

#include "thinkfootball/world_state.h"

namespace tf
{
struct MovementBase
{
    virtual ~MovementBase() = default;
    virtual void Tick(Player& player, const WorldState& world, float dtSeconds) = 0;
};

// Simple stage-0 movement: seek target, clamp speed, basic separation.
struct MovementArcade : public MovementBase
{
    float separationRadius{1.0f};
    float separationStrength{2.0f};
    float turnRateRadPerSec{10.0f};  // how fast the player can rotate body

    void Tick(Player& player, const WorldState& world, float dtSeconds) override;
};
}  // namespace tf

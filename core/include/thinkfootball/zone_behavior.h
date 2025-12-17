// Zone-level direction/hold preferences for positional intent.
#pragma once

#include <array>
#include "thinkfootball/pitch_zones.h"

namespace tf
{
enum class Direction8 : uint8_t
{
    N = 0,
    NE,
    E,
    SE,
    S,
    SW,
    W,
    NW
};

// Per-zone preference weights for movement directions and staying put.
struct ZoneBehavior
{
    std::array<float, 8> dirWeight{0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
    float holdWeight{0.0f};  // “stay/retain” preference

    // Returns a normalized 9-element vector (8 dirs + hold).
    std::array<float, 9> Normalized() const;
};

struct ZoneBehaviorTable
{
    // Index aligns with ZoneIndex (band * lanes + lane).
    std::array<ZoneBehavior, static_cast<int>(Lane::Count) * static_cast<int>(Band::Count)> zones{};
};

// Build a simple default: bias forward (positive X) and center; symmetric for both teams by flipping X.
ZoneBehaviorTable BuildDefaultZoneBehaviors(bool attackPositiveX = true);

// Fetch behavior for a position; returns nullptr if outside base zones.
const ZoneBehavior* GetZoneBehaviorAtPos(const ZoneBehaviorTable& table, const PitchLayout& layout, const Vec3& pos);

// Role bias presets (coarse) that can be added to base zone behaviors.
ZoneBehavior RoleDirectionBias(const std::string& role, bool attackPositiveX = true);
}  // namespace tf

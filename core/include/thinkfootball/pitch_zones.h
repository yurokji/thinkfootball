// Pitch zoning utilities: 5 lanes x 4 bands + special zones.
#pragma once

#include "thinkfootball/world_state.h"
#include <string>
#include <vector>

namespace tf
{
enum class Lane
{
    LeftWing = 0,
    LeftHalf,
    Center,
    RightHalf,
    RightWing,
    Count
};

enum class Band
{
    Defensive = 0,
    MidDefensive,
    MidAttacking,
    Attacking,
    Count
};

struct Zone
{
    int index{0};       // 0..19 for base grid
    Lane lane{};
    Band band{};
};

struct ZoneRect
{
    float x{};
    float z{};
    float width{};
    float height{};
};

struct PitchLayout
{
    float pitchWidth{68.0f};   // meters; adjustable
    float pitchHeight{105.0f}; // meters; adjustable
};

// Compute zone index from lane/band.
inline int ZoneIndex(Lane lane, Band band)
{
    return static_cast<int>(band) * static_cast<int>(Lane::Count) + static_cast<int>(lane);
}

// Get lane/band from zone index.
inline Zone IndexToZone(int index)
{
    Zone z;
    z.index = index;
    z.band = static_cast<Band>(index / static_cast<int>(Lane::Count));
    z.lane = static_cast<Lane>(index % static_cast<int>(Lane::Count));
    return z;
}

// Calculate rectangle for a zone in world coordinates (XZ plane).
ZoneRect GetZoneRect(const PitchLayout& layout, Lane lane, Band band);

// Find base zone index for a given XZ position.
// Supports both center-origin coordinates ([-L/2, +L/2]) and 0-origin ([0, L]).
int GetZoneAtPosition(const PitchLayout& layout, const Vec3& pos);

// Named special zones.
struct SpecialZones
{
    ZoneRect penaltyBoxHome{};
    ZoneRect penaltyBoxAway{};
    ZoneRect zone14{}; // central area just outside box
    ZoneRect bylineLeft{};
    ZoneRect bylineRight{};
};

SpecialZones BuildSpecialZones(const PitchLayout& layout);
}  // namespace tf

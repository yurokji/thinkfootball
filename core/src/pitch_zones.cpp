#include "thinkfootball/pitch_zones.h"

namespace tf
{
ZoneRect GetZoneRect(const PitchLayout& layout, Lane lane, Band band)
{
    float laneWidth = layout.pitchWidth / static_cast<float>(Lane::Count);
    float bandHeight = layout.pitchHeight / static_cast<float>(Band::Count);

    ZoneRect rect{};
    rect.x = laneWidth * static_cast<float>(static_cast<int>(lane)) - layout.pitchWidth * 0.5f;
    rect.z = bandHeight * static_cast<float>(static_cast<int>(band)) - layout.pitchHeight * 0.5f;
    rect.width = laneWidth;
    rect.height = bandHeight;
    return rect;
}

int GetZoneAtPosition(const PitchLayout& layout, const Vec3& pos)
{
    float laneWidth = layout.pitchWidth / static_cast<float>(Lane::Count);
    float bandHeight = layout.pitchHeight / static_cast<float>(Band::Count);

    // Detect whether coordinates are centered or origin at 0.
    bool originZero = (pos.x >= 0.0f && pos.x <= layout.pitchWidth &&
                       pos.z >= 0.0f && pos.z <= layout.pitchHeight);

    float px = originZero ? pos.x : (pos.x + layout.pitchWidth * 0.5f);
    float pz = originZero ? pos.z : (pos.z + layout.pitchHeight * 0.5f);

    int laneIdx = static_cast<int>(px / laneWidth);
    int bandIdx = static_cast<int>(pz / bandHeight);

    if (laneIdx < 0 || laneIdx >= static_cast<int>(Lane::Count) ||
        bandIdx < 0 || bandIdx >= static_cast<int>(Band::Count))
    {
        return -1; // out of pitch
    }
    return bandIdx * static_cast<int>(Lane::Count) + laneIdx;
}

SpecialZones BuildSpecialZones(const PitchLayout& layout)
{
    SpecialZones s{};
    float boxWidth = 40.32f;
    float boxDepth = 16.5f;
    float goalAreaWidth = 18.32f;

    // Home defends negative Z; Away defends positive Z.
    s.penaltyBoxHome = {-boxWidth * 0.5f, -layout.pitchHeight * 0.5f, boxWidth, boxDepth};
    s.penaltyBoxAway = {-boxWidth * 0.5f, layout.pitchHeight * 0.5f - boxDepth, boxWidth, boxDepth};

    // Zone14 (central strip just outside box)
    float zone14Depth = 10.0f;
    s.zone14 = {-goalAreaWidth * 0.5f, -boxDepth - zone14Depth, goalAreaWidth, zone14Depth * 2.0f};

    // Byline cross zones near corners
    float bylineHeight = 5.0f;
    float bylineWidth = layout.pitchWidth * 0.5f;
    s.bylineLeft = {-layout.pitchWidth * 0.5f, -layout.pitchHeight * 0.5f, bylineWidth, bylineHeight};
    s.bylineRight = {-layout.pitchWidth * 0.5f, layout.pitchHeight * 0.5f - bylineHeight, bylineWidth, bylineHeight};

    return s;
}
}  // namespace tf

#include "thinkfootball/pitch_geom.h"

#include <algorithm>

namespace tf
{
PitchGeometry BuildStandardPitch(float length, float width)
{
    PitchGeometry g{};
    g.length = length;
    g.width = width;

    g.pitchRect = {0.0f, 0.0f, length, width};

    // Half-line across width at x = length/2
    g.halfLine = {{length * 0.5f, 0.0f, 0.0f}, {length * 0.5f, 0.0f, width}};

    g.centerSpot = {length * 0.5f, 0.0f, width * 0.5f};
    g.centerCircle = {g.centerSpot, 9.15f};

    // Standard box dimensions.
    const float penaltyDepth = 16.5f;
    const float penaltyWidth = 40.32f;
    const float goalAreaDepth = 5.5f;
    const float goalAreaWidth = 18.32f;
    const float penaltySpotDist = 11.0f;

    float penOffsetZ = (width - penaltyWidth) * 0.5f;
    float gaOffsetZ = (width - goalAreaWidth) * 0.5f;

    // Home side at x=0
    g.penaltyArea[0] = {0.0f, penOffsetZ, penaltyDepth, penaltyWidth};
    g.goalArea[0] = {0.0f, gaOffsetZ, goalAreaDepth, goalAreaWidth};
    g.penaltySpot[0] = {penaltySpotDist, 0.0f, width * 0.5f};
    g.penaltyArc[0] = {{penaltySpotDist, 0.0f, width * 0.5f}, 9.15f};
    g.goalCenter[0] = {0.0f, 0.0f, width * 0.5f};

    // Away side at x=length (areas extend backward in -x from that line)
    g.penaltyArea[1] = {length - penaltyDepth, penOffsetZ, penaltyDepth, penaltyWidth};
    g.goalArea[1] = {length - goalAreaDepth, gaOffsetZ, goalAreaDepth, goalAreaWidth};
    g.penaltySpot[1] = {length - penaltySpotDist, 0.0f, width * 0.5f};
    g.penaltyArc[1] = {{length - penaltySpotDist, 0.0f, width * 0.5f}, 9.15f};
    g.goalCenter[1] = {length, 0.0f, width * 0.5f};

    // Corner arcs (top-left clockwise)
    g.cornerArc[0] = {{0.0f, 0.0f, 0.0f}, 1.0f};
    g.cornerArc[1] = {{length, 0.0f, 0.0f}, 1.0f};
    g.cornerArc[2] = {{length, 0.0f, width}, 1.0f};
    g.cornerArc[3] = {{0.0f, 0.0f, width}, 1.0f};

    return g;
}
}  // namespace tf

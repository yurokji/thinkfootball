// Pitch geometry primitives (meters, x=length, z=width).
#pragma once

#include "thinkfootball/types.h"
#include <array>

namespace tf
{
struct Segment
{
    Vec3 a{};
    Vec3 b{};
};

struct RectXZ
{
    float x{};
    float z{};
    float width{};
    float height{};
};

struct CircleXZ
{
    Vec3 center{};
    float radius{};
};

struct PitchGeometry
{
    float length{105.0f};  // meters along +x
    float width{68.0f};    // meters along +z

    Segment halfLine{};
    RectXZ pitchRect{};

    CircleXZ centerCircle{};
    Vec3 centerSpot{};

    std::array<RectXZ, 2> penaltyArea{};   // [0]=home goal side at x=0, [1]=away at x=length
    std::array<RectXZ, 2> goalArea{};
    std::array<Vec3, 2> penaltySpot{};     // 11m from goal line
    std::array<CircleXZ, 2> penaltyArc{};  // center at penalty spot, radius 9.15
    std::array<CircleXZ, 4> cornerArc{};   // clockwise from top-left

    std::array<Vec3, 2> goalCenter{};      // center of goal on goal line
    float goalWidth{7.32f};
    float goalDepth{2.0f};                 // purely visual for now
    float goalPostRadius{0.4f};
};

// Build a standard FIFA pitch geometry for given length/width (meters).
PitchGeometry BuildStandardPitch(float length = 105.0f, float width = 68.0f);
}  // namespace tf

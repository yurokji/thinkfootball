// Global game constants (screen/pitch layout).
#pragma once

#include <raylib.h>

namespace tfc
{
// Screen layout
inline constexpr int kGameWidth = 1280;
inline constexpr int kGameHeight = 720;
inline constexpr int kSidebarWidth = 360;
inline constexpr int kWindowWidth = kGameWidth + kSidebarWidth;
inline constexpr int kWindowHeight = 960;  // extra space for bottom panels
inline constexpr float kPitchOffsetX = 16.0f;
inline constexpr float kPitchOffsetY = 16.0f;
inline constexpr float kPitchScreenMargin = 48.0f;

// Simulation
inline constexpr float kTargetDt = 1.0f / 60.0f;
// World dimensions (meters): landscape pitch x=length, z=width.
inline constexpr float kPitchLengthM = 105.0f;
inline constexpr float kPitchWidthM = 68.0f;

// Rendering sizes
inline constexpr int kFontSizeUI = 24;
inline constexpr int kHudTitleSize = 36;
inline constexpr int kPlayerLabelSize = 24;
inline constexpr float kPlayerRadius = 12.0f;
inline constexpr float kPlayerOutlineRadius = 14.0f;
inline constexpr float kHeadingRadius = 10.0f;
inline constexpr float kBallRadius = 6.0f;
inline constexpr float kVisionRangeBase = 12.0f;      // meters
inline constexpr float kVisionHalfAngleDeg = 40.0f * 0.5f;  // half-angle ~20deg default

// Colors
inline constexpr Color kPitchOuterColor{0, 80, 0, 255};
inline constexpr Color kPitchInnerColor{0, 100, 0, 255};
inline constexpr Color kLineColor{255, 255, 255, 255};  // RAYWHITE
inline constexpr Color kHeadingColor{255, 255, 0, 230}; // bright yellow
inline constexpr Color kPlayerLabelColor{80, 80, 80, 255}; // DARKGRAY-ish
inline constexpr Color kHudTextColor{80, 80, 80, 255};
inline constexpr Color kBallColor{255, 161, 0, 255}; // ORANGE
inline constexpr Color kHomeColor{102, 191, 255, 255}; // SKYBLUE
inline constexpr Color kAwayColor{230, 41, 55, 255};   // RED
inline constexpr Color kVisionColor{0, 255, 255, 160};      // brighter translucent cyan
inline constexpr Color kVisionOutlineColor{0, 180, 255, 200};
}  // namespace tfc

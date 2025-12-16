// Ball state and event APIs (deterministic, replay-friendly).
#pragma once

#include "thinkfootball/types.h"
#include <cstdint>

namespace tf
{
enum class BallMode : uint8_t
{
    Controlled,
    FreeGround,
    FreeAir
};

struct BallContact
{
    int playerId{-1};
    int teamId{-1};
    int tick{0};
};

struct BallFlightProfile
{
    bool active{false};
    int startTick{0};
    int endTick{0};
    Vec3 startPos{};
    Vec3 endPos{};
    float apexHeight{0.0f};
    float spin{0.0f};
};

struct BallState
{
    BallMode mode{BallMode::FreeGround};

    Vec3 pos{};
    Vec3 vel{};

    // Render parameters stored for determinism/replay.
    float height{0.0f};
    float heightVel{0.0f};

    int ownerPlayerId{-1};  // valid when controlled
    int claimPlayerId{-1};  // optional hint for contests

    BallContact lastTouch{};
    BallContact prevTouch{};
    std::uint32_t touchSeq{0};

    BallFlightProfile flight{};
};

struct BallParams
{
    float groundDamping{0.98f};   // per second multiplier
    float airDamping{0.99f};
};

void BallInit(BallState& ball, const Vec3& startPos);
void BallRegisterTouch(BallState& ball, int playerId, int teamId, int tick);

void BallKickGround(BallState& ball,
                    int passerPlayerId,
                    int passerTeamId,
                    int tick,
                    const Vec3& startPos,
                    const Vec3& initialVel);

void BallKickLob(BallState& ball,
                 int passerPlayerId,
                 int passerTeamId,
                 int tick,
                 const Vec3& startPos,
                 const Vec3& landingPos,
                 int hangTimeTicks,
                 float apexHeight,
                 float spin);

void BallClaimControl(BallState& ball,
                      int playerId,
                      int teamId,
                      int tick,
                      const Vec3& attachPos);

void BallTick(BallState& ball, int currentTick, float dtSeconds, const BallParams& params = {});
}  // namespace tf

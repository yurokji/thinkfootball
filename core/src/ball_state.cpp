#include "thinkfootball/ball_state.h"

#include <algorithm>
#include <cmath>

namespace tf
{
static float Lerp(float a, float b, float t) { return a + (b - a) * t; }

void BallInit(BallState& ball, const Vec3& startPos)
{
    ball = BallState{};
    ball.pos = startPos;
    ball.mode = BallMode::FreeGround;
}

void BallRegisterTouch(BallState& ball, int playerId, int teamId, int tick)
{
    ball.prevTouch = ball.lastTouch;
    ball.lastTouch = {playerId, teamId, tick};
    ball.touchSeq++;
}

void BallKickGround(BallState& ball,
                    int passerPlayerId,
                    int passerTeamId,
                    int tick,
                    const Vec3& startPos,
                    const Vec3& initialVel)
{
    BallRegisterTouch(ball, passerPlayerId, passerTeamId, tick);
    ball.mode = BallMode::FreeGround;
    ball.pos = startPos;
    ball.vel = initialVel;
    ball.ownerPlayerId = -1;
    ball.claimPlayerId = -1;
    ball.flight.active = false;
    ball.height = 0.0f;
    ball.heightVel = 0.0f;
}

void BallKickLob(BallState& ball,
                 int passerPlayerId,
                 int passerTeamId,
                 int tick,
                 const Vec3& startPos,
                 const Vec3& landingPos,
                 int hangTimeTicks,
                 float apexHeight,
                 float spin)
{
    BallRegisterTouch(ball, passerPlayerId, passerTeamId, tick);
    ball.mode = BallMode::FreeAir;
    ball.pos = startPos;
    ball.vel = {0, 0, 0};
    ball.ownerPlayerId = -1;
    ball.claimPlayerId = -1;
    ball.flight.active = true;
    ball.flight.startTick = tick;
    ball.flight.endTick = tick + hangTimeTicks;
    ball.flight.startPos = startPos;
    ball.flight.endPos = landingPos;
    ball.flight.apexHeight = apexHeight;
    ball.flight.spin = spin;
}

void BallClaimControl(BallState& ball,
                      int playerId,
                      int teamId,
                      int tick,
                      const Vec3& attachPos)
{
    BallRegisterTouch(ball, playerId, teamId, tick);
    ball.mode = BallMode::Controlled;
    ball.ownerPlayerId = playerId;
    ball.claimPlayerId = -1;
    ball.pos = attachPos;
    ball.vel = {0, 0, 0};
    ball.height = 0.0f;
    ball.heightVel = 0.0f;
    ball.flight.active = false;
}

void BallTick(BallState& ball, int currentTick, float dtSeconds, const BallParams& params)
{
    switch (ball.mode)
    {
    case BallMode::Controlled:
        ball.vel = {0, 0, 0};
        ball.height = 0.0f;
        ball.heightVel = 0.0f;
        break;
    case BallMode::FreeGround:
        ball.pos.x += ball.vel.x * dtSeconds;
        ball.pos.z += ball.vel.z * dtSeconds;
        ball.vel.x *= std::pow(params.groundDamping, dtSeconds);
        ball.vel.z *= std::pow(params.groundDamping, dtSeconds);
        ball.height = 0.0f;
        break;
    case BallMode::FreeAir:
        if (!ball.flight.active || currentTick >= ball.flight.endTick)
        {
            ball.mode = BallMode::FreeGround;
            ball.flight.active = false;
            ball.height = 0.0f;
            ball.heightVel = 0.0f;
            break;
        }
        else
        {
            float t = 0.0f;
            if (ball.flight.endTick != ball.flight.startTick)
            {
                t = std::clamp(
                    static_cast<float>(currentTick - ball.flight.startTick) /
                        static_cast<float>(ball.flight.endTick - ball.flight.startTick),
                    0.0f, 1.0f);
            }
            ball.pos.x = Lerp(ball.flight.startPos.x, ball.flight.endPos.x, t);
            ball.pos.z = Lerp(ball.flight.startPos.z, ball.flight.endPos.z, t);
            ball.height = 4.0f * ball.flight.apexHeight * t * (1.0f - t);
        }
        break;
    }
}
}  // namespace tf

#include "thinkfootball/movement.h"

#include <algorithm>
#include <cmath>

namespace tf
{
namespace
{
float LengthXZ(const Vec3& v)
{
    return std::sqrt(v.x * v.x + v.z * v.z);
}

float WrapAngle(float a)
{
    const float pi = 3.1415926535f;
    const float twoPi = pi * 2.0f;
    while (a > pi) a -= twoPi;
    while (a < -pi) a += twoPi;
    return a;
}

Vec3 NormalizeXZ(const Vec3& v)
{
    float len = LengthXZ(v);
    if (len <= 1e-5f) return {0, 0, 0};
    return {v.x / len, 0.0f, v.z / len};
}

void ApplySeparation(Player& self, const WorldState& world, float dt, float radius, float strength)
{
    Vec3 push{0, 0, 0};
    // Only apply mild separation to avoid "blocking" when trying to tackle.
    float effectiveStrength = strength * 0.25f;  // further reduced
    for (const Player& other : world.players)
    {
        if (&other == &self) continue;
        Vec3 delta{self.state.position.x - other.state.position.x, 0.0f, self.state.position.z - other.state.position.z};
        float dist = LengthXZ(delta);
        if (dist > 1e-4f && dist < radius)
        {
            float scale = (radius - dist) / radius;
            push.x += (delta.x / dist) * scale;
            push.z += (delta.z / dist) * scale;
        }
    }
    self.state.velocity.x += push.x * effectiveStrength * dt;
    self.state.velocity.z += push.z * effectiveStrength * dt;
}
}  // namespace

void MovementArcade::Tick(Player& player, const WorldState& world, float dtSeconds)
{
    // Desired velocity toward target
    Vec3 toTarget{player.intent.targetPos.x - player.state.position.x,
                  0.0f,
                  player.intent.targetPos.z - player.state.position.z};
    Vec3 dir = NormalizeXZ(toTarget);
    float dist = LengthXZ(toTarget);

    // Human-like movement in meters/sec and meters/sec^2.
    const float baseMaxSpeedMps = 7.5f;   // ~elite sprint
    const float baseAccelMps2 = 6.5f;     // faster accel to turn quicker
    bool ownsBall = (world.ball.mode == BallMode::Controlled && world.ball.ownerPlayerId == player.id);
    float speedMult = ownsBall ? 0.5f : 1.30f;  // make on-ball slower, off-ball faster
    float maxSpeed = player.stats.speed * baseMaxSpeedMps * speedMult;
    float accel = player.stats.accel * baseAccelMps2;
    float desiredSpeed = player.intent.desiredSpeed01 * maxSpeed;

    // Ease into target to avoid instant stops.
    const float slowRadius = 3.0f;  // meters
    if (dist < slowRadius && slowRadius > 1e-3f)
    {
        desiredSpeed *= (dist / slowRadius);
    }

    // Turn body toward desired direction with limited turn rate.
    float desiredHeading = player.state.facingRadians;
    if (dist > 1e-3f)
    {
        desiredHeading = std::atan2(dir.x, dir.z);
    }
    float angleDiff = WrapAngle(desiredHeading - player.state.facingRadians);
    float maxTurn = turnRateRadPerSec * dtSeconds;
    float appliedTurn = std::clamp(angleDiff, -maxTurn, maxTurn);
    player.state.facingRadians = WrapAngle(player.state.facingRadians + appliedTurn);

    // Do not allow movement backwards; scale speed by facing alignment.
    float forwardFactor = 1.0f;
    float angleToMove = WrapAngle(desiredHeading - player.state.facingRadians);
    forwardFactor = std::cos(angleToMove);  // 1 at 0 deg, 0 at 90 deg, negative if behind
    // Allow some movement even when behind, but heavily damped.
    desiredSpeed *= std::max(0.2f, forwardFactor);

    // Accelerate toward desired velocity
    Vec3 desiredVel{dir.x * desiredSpeed, 0.0f, dir.z * desiredSpeed};
    Vec3 delta{desiredVel.x - player.state.velocity.x, 0.0f, desiredVel.z - player.state.velocity.z};
    float deltaLen = LengthXZ(delta);
    float maxDelta = accel * dtSeconds;
    if (deltaLen > maxDelta && deltaLen > 1e-5f)
    {
        delta.x *= maxDelta / deltaLen;
        delta.z *= maxDelta / deltaLen;
    }
    player.state.velocity.x += delta.x;
    player.state.velocity.z += delta.z;

    // Separation
    ApplySeparation(player, world, dtSeconds, separationRadius, separationStrength);

    // Integrate position
    player.state.position.x += player.state.velocity.x * dtSeconds;
    player.state.position.z += player.state.velocity.z * dtSeconds;
}
}  // namespace tf

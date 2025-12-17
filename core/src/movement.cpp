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
    // Stronger separation to avoid clustering.
    float effectiveStrength = strength * 0.8f;
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
    // Clamp push to avoid jitter explosions.
    const float maxPush = 5.0f;
    push.x = std::clamp(push.x, -maxPush, maxPush);
    push.z = std::clamp(push.z, -maxPush, maxPush);
    self.state.velocity.x += push.x * effectiveStrength * dt;
    self.state.velocity.z += push.z * effectiveStrength * dt;
}
}  // namespace

void MovementArcade::Tick(Player& player, const WorldState& world, float dtSeconds)
{
    float breath = std::clamp(player.condition.breath, 0.0f, 1.0f);
    float endurance = std::clamp(player.stats.endurance, 0.1f, 1.0f);

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
    float breathSpeedFactor = 0.55f + 0.45f * breath;   // winded players slow down
    float breathAccelFactor = 0.65f + 0.35f * breath;   // and turn slower
    float maxSpeed = player.stats.speed * baseMaxSpeedMps * speedMult * breathSpeedFactor;
    float accel = player.stats.accel * baseAccelMps2 * breathAccelFactor;
    float desiredSpeed = player.intent.desiredSpeed01 * maxSpeed;

    // Ease into target to avoid instant stops.
    const float slowRadius = 3.0f;  // meters
    if (dist < slowRadius && slowRadius > 1e-3f)
    {
        desiredSpeed *= (dist / slowRadius);
    }

    // Turn body toward desired direction with limited turn rate (slower when fast).
    float desiredHeading = player.state.facingRadians;
    if (dist > 1e-3f)
    {
        desiredHeading = std::atan2(dir.x, dir.z);
    }
    float angleDiff = WrapAngle(desiredHeading - player.state.facingRadians);
    float currentSpeed = LengthXZ(player.state.velocity);
    float speedRatio = std::clamp(currentSpeed / std::max(maxSpeed, 1e-3f), 0.0f, 1.0f);
    float turnScale = 0.5f + (1.0f - speedRatio) * 0.5f;  // fast일수록 회전 한계 축소
    float maxTurn = turnRateRadPerSec * dtSeconds * turnScale;
    float appliedTurn = std::clamp(angleDiff, -maxTurn, maxTurn);
    player.state.facingRadians = WrapAngle(player.state.facingRadians + appliedTurn);

    // Do not allow backwards movement; if target는 후방이면 정지+회전만 수행.
    float angleToMove = WrapAngle(desiredHeading - player.state.facingRadians);
    float angleAbs = std::fabs(angleToMove);
    float turnSkill = 0.6f + player.stats.control * 0.4f; // 컨트롤이 좋을수록 회전·감속 페널티 완화
    if (angleAbs > (3.1415926535f * 0.5f))
    {
        desiredSpeed = 0.0f;
    }
    else
    {
        float forwardFactor = std::cos(angleToMove);  // 1 at 0 deg, 0 at 90 deg
        desiredSpeed *= std::clamp(forwardFactor, 0.0f, 1.0f);
        // 추가 감속: 각도가 클수록 속도 더 줄임.
        float angleDamp = 1.0f - (angleAbs / (3.1415926535f * 0.5f)) * 0.7f; // up to -70%
        desiredSpeed *= std::clamp(angleDamp, 0.3f, 1.0f);
        // 컨트롤 좋은 선수는 감속 페널티 완화.
        desiredSpeed *= turnSkill;
    }

    // Accelerate toward desired velocity
    Vec3 desiredVel{dir.x * desiredSpeed, 0.0f, dir.z * desiredSpeed};
    Vec3 delta{desiredVel.x - player.state.velocity.x, 0.0f, desiredVel.z - player.state.velocity.z};
    float deltaLen = LengthXZ(delta);
    float maxDelta = accel * dtSeconds;
    // 회전 중 가속 제한: 정면 정렬이 낮고 컨트롤이 낮을수록 덜 급하게 방향 전환
    float align = std::max(0.0f, std::cos(angleAbs));
    float accelScale = std::clamp(0.3f + align * turnSkill, 0.3f, 1.0f);
    maxDelta *= accelScale;
    if (deltaLen > maxDelta && deltaLen > 1e-5f)
    {
        delta.x *= maxDelta / deltaLen;
        delta.z *= maxDelta / deltaLen;
    }
    player.state.velocity.x += delta.x;
    player.state.velocity.z += delta.z;

    // Breath model: sprinting/bursting drains breath; coasting recovers it, scaled by endurance.
    float appliedDelta = LengthXZ(delta);
    float accelUse = std::min(1.0f, (maxDelta > 1e-5f) ? appliedDelta / maxDelta : 0.0f);
    float sprintUse = std::clamp(desiredSpeed / std::max(maxSpeed, 1e-3f), 0.0f, 1.0f);
    float exert = std::max(0.0f, sprintUse - 0.5f) * 1.4f + accelUse * 0.3f;  // bias drain to high sprint
    if (ownsBall) exert *= 1.1f;  // carrying the ball is tiring
    float drain = exert * (1.0f + (1.0f - endurance)) * dtSeconds * 0.9f;
    float recover = (1.0f - sprintUse) * (0.6f + endurance * 0.8f) * dtSeconds * 0.6f;
    breath = std::clamp(breath - drain + recover, 0.0f, 1.0f);
    player.condition.breath = breath;

    // Separation
    ApplySeparation(player, world, dtSeconds, separationRadius, separationStrength);

    // Integrate position
    player.state.position.x += player.state.velocity.x * dtSeconds;
    player.state.position.z += player.state.velocity.z * dtSeconds;
}
}  // namespace tf

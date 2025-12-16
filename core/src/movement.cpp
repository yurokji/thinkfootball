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

Vec3 NormalizeXZ(const Vec3& v)
{
    float len = LengthXZ(v);
    if (len <= 1e-5f) return {0, 0, 0};
    return {v.x / len, 0.0f, v.z / len};
}

void ApplySeparation(Player& self, const WorldState& world, float dt, float radius, float strength)
{
    Vec3 push{0, 0, 0};
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
    self.state.velocity.x += push.x * strength * dt;
    self.state.velocity.z += push.z * strength * dt;
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
    const float baseAccelMps2 = 5.0f;     // modest accel to avoid warping
    float maxSpeed = player.stats.speed * baseMaxSpeedMps;
    float accel = player.stats.accel * baseAccelMps2;
    float desiredSpeed = player.intent.desiredSpeed01 * maxSpeed;

    // Ease into target to avoid instant stops.
    const float slowRadius = 5.0f;  // meters
    if (dist < slowRadius && slowRadius > 1e-3f)
    {
        desiredSpeed *= (dist / slowRadius);
    }

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

    // Facing updates toward velocity if moving
    if (LengthXZ(player.state.velocity) > 1e-3f)
    {
        player.state.facingRadians = std::atan2(player.state.velocity.x, player.state.velocity.z);
    }
}
}  // namespace tf

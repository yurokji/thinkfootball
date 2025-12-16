#include "thinkfootball/brain.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace tf
{
namespace
{
constexpr float kPi = 3.1415926535f;

struct VisionInfo
{
    float nearestOppDist{std::numeric_limits<float>::max()};
    Vec3 nearestOppVec{};
};

inline float Length2D(float x, float z)
{
    return std::sqrt(x * x + z * z);
}

inline Vec3 RotateY(const Vec3& v, float ang)
{
    float s = std::sin(ang);
    float c = std::cos(ang);
    return {v.x * c - v.z * s, 0.0f, v.x * s + v.z * c};
}

VisionInfo CollectVision(const Player& viewer, const WorldState& world, float rangeBase, float halfAngleRad)
{
    VisionInfo info{};
    float range = rangeBase * (0.6f + viewer.stats.awareness * 0.8f);
    float dirX = std::sin(viewer.state.facingRadians);
    float dirZ = std::cos(viewer.state.facingRadians);

    for (const auto& p : world.players)
    {
        if (p.id == viewer.id) continue;
        float dx = p.state.position.x - viewer.state.position.x;
        float dz = p.state.position.z - viewer.state.position.z;
        float dist2 = dx * dx + dz * dz;
        if (dist2 > range * range) continue;
        float dist = Length2D(dx, dz);
        if (dist < 1e-3f) continue;
        float dot = (dirX * dx + dirZ * dz) / dist;
        float ang = std::acos(std::clamp(dot, -1.0f, 1.0f));
        if (ang <= halfAngleRad && p.teamIndex != viewer.teamIndex)
        {
            if (dist < info.nearestOppDist)
            {
                info.nearestOppDist = dist;
                info.nearestOppVec = {dx / dist, 0.0f, dz / dist};
            }
        }
    }
    return info;
}
}  // namespace

void TeamBrain::ThinkTeam(WorldState& /*world*/, float /*dtSeconds*/)
{
    // Placeholder: team-level tactics updates can be added here.
}

void TeamBrain::ApplyTactics(const WorldState& world, GroupContext& ctx)
{
    const float minBand = ctx.pitchHeight * 0.05f;
    for (size_t i = 0; i < world.teams.size() && i < ctx.team.size(); ++i)
    {
        const auto& tactics = world.teams[i].tactics;
        // Normalize tempo/press into usable scales.
        ctx.team[i].speedScale = std::clamp(0.4f + tactics.tempo * 0.6f, 0.2f, 1.5f);
        ctx.team[i].pressScale = std::clamp(0.5f + tactics.pressIntensity * 0.5f, 0.2f, 1.5f);
        ctx.team[i].halfWidth = (ctx.pitchWidth * 0.5f) * (0.3f + tactics.width * 0.7f);

        // Defensive line expressed as a clamp relative to own goal.
        float lineRatio = std::clamp(tactics.defensiveLineHeight, 0.0f, 1.0f);
        if (i == 0)
        {
            ctx.team[i].lineZ = std::clamp(ctx.pitchHeight * (0.10f + lineRatio * 0.75f), 0.0f, ctx.pitchHeight - minBand);
        }
        else
        {
            ctx.team[i].lineZ = std::clamp(ctx.pitchHeight * (0.90f - lineRatio * 0.75f), minBand, ctx.pitchHeight);
        }
    }
}

void BrainChaseBall::Think(Player& player, const WorldState& world, const GroupContext& ctx, float /*dtSeconds*/)
{
    const int teamIndex = std::clamp(player.teamIndex, 0, 1);
    const auto& tactics = world.teams[teamIndex].tactics;
    const auto& tctx = ctx.team[teamIndex];

    Vec3 target = ctx.ballPos;
    // If another player already controls the ball, stop just outside a small buffer to avoid stacking.
    if (world.ball.mode == BallMode::Controlled && world.ball.ownerPlayerId != player.id)
    {
        const float buffer = 2.5f;  // meters
        Vec3 toBall{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
        float dist = std::sqrt(toBall.x * toBall.x + toBall.z * toBall.z);
        if (dist > 1e-3f && dist > buffer)
        {
            float scale = (dist - buffer) / dist;
            target.x = player.state.position.x + toBall.x * scale;
            target.z = player.state.position.z + toBall.z * scale;
        }
        else
        {
            target = player.state.position;  // stay put if already within buffer
        }
    }

    const float pressBand = ctx.pitchHeight * (0.05f + tactics.pressIntensity * 0.1f);
    if (teamIndex == 0)
    {
        target.z = std::min(target.z, tctx.lineZ + pressBand);
    }
    else
    {
        target.z = std::max(target.z, tctx.lineZ - pressBand);
    }

    const float centerX = ctx.pitchWidth * 0.5f;
    const float minX = centerX - tctx.halfWidth;
    const float maxX = centerX + tctx.halfWidth;
    target.x = std::clamp(target.x, minX, maxX);

    player.intent.targetPos = target;
    float speed01 = std::clamp(tctx.speedScale * tctx.pressScale, 0.0f, 1.0f);
    player.intent.desiredSpeed01 = speed01;
    player.intent.action = RequestedAction::None;
    player.intent.faceDir = {0, 0, 0};
}

void BrainSimplePossession::Think(Player& player, const WorldState& world, const GroupContext& ctx, float /*dtSeconds*/)
{
    const int teamIndex = std::clamp(player.teamIndex, 0, 1);
    const auto& tactics = world.teams[teamIndex].tactics;
    const auto& tctx = ctx.team[teamIndex];

    const bool ownsBall = (world.ball.mode == BallMode::Controlled && world.ball.ownerPlayerId == player.id);

    Vec3 target = ctx.ballPos;
    Vec3 goalPos{(teamIndex == 0) ? ctx.pitchWidth : 0.0f, 0.0f, ctx.pitchHeight * 0.5f};
    RequestedAction action = RequestedAction::None;
    float speed01 = std::clamp(tctx.speedScale * tctx.pressScale, 0.0f, 1.0f);
    VisionInfo vision = CollectVision(player, world, 12.0f, 40.0f * 0.5f * (kPi / 180.0f));
    if (ownsBall)
    {
        // Default dribble direction toward goal, then pick a safer variant.
        Vec3 toGoal{goalPos.x - player.state.position.x, 0.0f, goalPos.z - player.state.position.z};
        float glen = Length2D(toGoal.x, toGoal.z);
        Vec3 fwdDir = (glen > 1e-3f) ? Vec3{toGoal.x / glen, 0.0f, toGoal.z / glen} : Vec3{(teamIndex == 0) ? 1.0f : -1.0f, 0.0f, 0.0f};

        // Clamp within pitch bounds.
        target.x = std::clamp(target.x, 0.0f, ctx.pitchWidth);
        target.z = std::clamp(target.z, 0.0f, ctx.pitchHeight);

        speed01 = 0.7f;  // dribble slower than sprint

        // Slow when threat is close in vision.
        if (vision.nearestOppDist < 3.5f)
        {
            speed01 *= 0.5f;
        }

        // Choose safer dribble direction among a few candidates with minimal turn.
        float baseAng = 0.3f;  // ~17deg
        float maxAng = 0.6f;   // ~34deg
        std::vector<Vec3> dirs = {
            fwdDir,
            RotateY(fwdDir, baseAng),
            RotateY(fwdDir, -baseAng),
            RotateY(fwdDir, maxAng),
            RotateY(fwdDir, -maxAng)};

        float bestScore = -1e9f;
        Vec3 bestDir = fwdDir;
        for (const auto& d : dirs)
        {
            float normLen = Length2D(d.x, d.z);
            if (normLen < 1e-4f) continue;
            Vec3 nd{d.x / normLen, 0.0f, d.z / normLen};
            float angle = std::acos(std::clamp(nd.x * fwdDir.x + nd.z * fwdDir.z, -1.0f, 1.0f));
            float anglePenalty = angle * (1.0f + (1.0f - player.stats.control));  // better control → smaller penalty

            float threatPenalty = 0.0f;
            if (vision.nearestOppDist < 8.0f)
            {
                threatPenalty = (8.0f - vision.nearestOppDist);
            }

            float score = (nd.x * fwdDir.x + nd.z * fwdDir.z) * 2.0f - anglePenalty * 1.0f - threatPenalty * 0.5f;
            if (score > bestScore)
            {
                bestScore = score;
                bestDir = nd;
            }
        }
        target = {player.state.position.x + bestDir.x * 8.0f, 0.0f, player.state.position.z + bestDir.z * 8.0f};

        // Shoot if close enough to goal.
        float toGoalX = goalPos.x - player.state.position.x;
        float toGoalZ = goalPos.z - player.state.position.z;
        float goalDist2 = toGoalX * toGoalX + toGoalZ * toGoalZ;
        if (goalDist2 < 20.0f * 20.0f)
        {
            action = RequestedAction::Shoot;
            target = goalPos;
            speed01 = 0.2f;  // preparing shot
        }

        // Look for a simple pass to a teammate reasonably close; prefer forward, but allow fallback lateral/back.
        int bestForwardId = -1;
        float bestForwardScore = -1.0f;
        Vec3 bestForwardPos{};
        int bestAnyId = -1;
        float bestAnyScore = -1.0f;
        Vec3 bestAnyPos{};
        for (const auto& mate : world.players)
        {
            if (mate.teamIndex != teamIndex || mate.id == player.id) continue;
            float dx = mate.state.position.x - player.state.position.x;
            float dz = mate.state.position.z - player.state.position.z;
            float dist2 = dx * dx + dz * dz;
            if (dist2 < 8.0f * 8.0f) continue;            // avoid very short passes
            if (dist2 > 45.0f * 45.0f) continue;          // keep within moderate range
            float dist = std::sqrt(dist2);

            float forward = (teamIndex == 0) ? dx : -dx;

            // Require mate to be within vision cone.
            float dirX = std::sin(player.state.facingRadians);
            float dirZ = std::cos(player.state.facingRadians);
            float dot = (dirX * dx + dirZ * dz) / std::max(dist, 1e-3f);
            float ang = std::acos(std::clamp(dot, -1.0f, 1.0f));
            float halfAng = 40.0f * 0.5f * (kPi / 180.0f);
            float visRange = 12.0f * (0.6f + player.stats.awareness * 0.8f);
            if (ang > halfAng || dist > visRange) continue;

            float laneCenter = ctx.pitchHeight * 0.5f;
            float widthPenalty = std::abs(mate.state.position.z - laneCenter) / (ctx.pitchHeight * 0.5f);
            float score = (45.0f - dist) * 0.8f + forward * 0.4f - widthPenalty * 0.1f;
            if (forward <= 0.0f) score *= 0.75f;  // prefer forward, but allow back with penalty

            if (forward > 0.5f && score > bestForwardScore)
            {
                bestForwardScore = score;
                bestForwardId = mate.id;
                bestForwardPos = mate.state.position;
            }
            if (score > bestAnyScore)
            {
                bestAnyScore = score;
                bestAnyId = mate.id;
                bestAnyPos = mate.state.position;
            }
        }

        // Prefer a forward option if available; otherwise fallback to best overall in vision.
        if (bestForwardId >= 0 && action != RequestedAction::Shoot)
        {
            action = RequestedAction::Pass;
            target = bestForwardPos;
            speed01 = 0.3f;  // slow down a bit while preparing pass
        }
        else if (bestAnyId >= 0 && action != RequestedAction::Shoot)
        {
            action = RequestedAction::Pass;
            target = bestAnyPos;
            speed01 = 0.3f;
        }
    }
    else
    {
        // Chase-with-buffer as in BrainChaseBall.
        const float pressBand = ctx.pitchHeight * (0.05f + tactics.pressIntensity * 0.1f);
        if (teamIndex == 0)
        {
            target.x = std::min(target.x, tctx.lineZ + pressBand);
        }
        else
        {
            target.x = std::max(target.x, tctx.lineZ - pressBand);
        }

        const float centerZ = ctx.pitchHeight * 0.5f;
        const float minZ = centerZ - tctx.halfWidth;
        const float maxZ = centerZ + tctx.halfWidth;
        target.z = std::clamp(target.z, minZ, maxZ);

        if (world.ball.mode == BallMode::Controlled)
        {
            const float buffer = 2.5f;
            Vec3 toBall{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
            float dist = std::sqrt(toBall.x * toBall.x + toBall.z * toBall.z);
            if (dist > buffer && dist > 1e-3f)
            {
                float scale = (dist - buffer) / dist;
                target.x = player.state.position.x + toBall.x * scale;
                target.z = player.state.position.z + toBall.z * scale;
            }
            else
            {
                target = player.state.position;
            }
        }
    }

    player.intent.targetPos = target;
    player.intent.desiredSpeed01 = speed01;
    player.intent.action = action;
    player.intent.faceDir = {0, 0, 0};
}

void TickPlayerWithBrain(Player& player,
                         const WorldState& world,
                         const GroupContext& ctx,
                         MovementBase& movement,
                         PlayerBrain& brain,
                         float dtSeconds)
{
    brain.Think(player, world, ctx, dtSeconds);
    movement.Tick(player, world, dtSeconds);
}
}  // namespace tf

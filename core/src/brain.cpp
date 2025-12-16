#include "thinkfootball/brain.h"

#include <algorithm>

namespace tf
{
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
    RequestedAction action = RequestedAction::None;
    float speed01 = std::clamp(tctx.speedScale * tctx.pressScale, 0.0f, 1.0f);

    if (ownsBall)
    {
        // Default dribble forward along attack direction.
        const float attackDir = (teamIndex == 0) ? 1.0f : -1.0f;
        target = player.state.position;
        target.z += 8.0f * attackDir;  // advance 8m ahead

        // Clamp within pitch bounds.
        target.x = std::clamp(target.x, 0.0f, ctx.pitchWidth);
        target.z = std::clamp(target.z, 0.0f, ctx.pitchHeight);

        speed01 = 0.7f;  // dribble slower than sprint

        // Look for a simple pass to a teammate ahead and reasonably close.
        int bestId = -1;
        float bestScore = -1.0f;
        Vec3 bestPos{};
        for (const auto& mate : world.players)
        {
            if (mate.teamIndex != teamIndex || mate.id == player.id) continue;
            float dx = mate.state.position.x - player.state.position.x;
            float dz = mate.state.position.z - player.state.position.z;
            float dist2 = dx * dx + dz * dz;
            if (dist2 < 4.0f) continue;       // too close
            if (dist2 > 30.0f * 30.0f) continue;  // too far for this simple model

            // Prefer forward (toward opponent goal) and centrality per tactics width.
            float forward = (teamIndex == 0) ? dz : -dz;
            if (forward <= 0.0f) continue;

            float laneCenter = ctx.pitchWidth * 0.5f;
            float widthPenalty = std::abs(mate.state.position.x - laneCenter) / (ctx.pitchWidth * 0.5f);
            float score = forward - widthPenalty * 3.0f;
            if (score > bestScore)
            {
                bestScore = score;
                bestId = mate.id;
                bestPos = mate.state.position;
            }
        }

        if (bestId >= 0)
        {
            action = RequestedAction::Pass;
            target = bestPos;
            speed01 = 0.3f;  // slow down a bit while preparing pass
        }
    }
    else
    {
        // Chase-with-buffer as in BrainChaseBall.
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

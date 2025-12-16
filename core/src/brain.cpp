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

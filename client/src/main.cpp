#include <raylib.h>
#include "raygui.h"

#include <filesystem>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cmath>
#include <random>

#include "thinkfootball/brain.h"
#include "thinkfootball/constants.h"
#include "thinkfootball/pitch_geom.h"
#include "thinkfootball/world_state.h"

namespace
{
std::string ResolveFontPath()
{
    namespace fs = std::filesystem;
    fs::path exeDir = fs::path(GetApplicationDirectory());
    const fs::path candidates[] = {
        fs::path("assets/fonts/Pretendard-Regular.ttf"),
        fs::path("../assets/fonts/Pretendard-Regular.ttf"),
        exeDir / "assets/fonts/Pretendard-Regular.ttf",
        exeDir.parent_path() / "assets/fonts/Pretendard-Regular.ttf"
    };
    for (const auto& path : candidates)
    {
        if (!path.empty() && FileExists(path.string().c_str()))
            return path.string();
    }
    return {};
}

std::vector<int> BuildKoreanCodepoints()
{
    std::vector<int> cps;
    for (int cp = 32; cp <= 126; ++cp) cps.push_back(cp);
    for (int cp = 0x3131; cp <= 0x318E; ++cp) cps.push_back(cp);
    for (int cp = 0xAC00; cp <= 0xD7A3; ++cp) cps.push_back(cp);
    cps.push_back(0);
    return cps;
}

Vector2 ToScreen(const tf::Vec3& p, const Vector2& origin, float scale)
{
    return {origin.x + p.x * scale, origin.y + p.z * scale};
}

tf::Vec3 ClampToPitch(const tf::Vec3& p)
{
    tf::Vec3 r = p;
    r.x = std::clamp(r.x, 0.0f, tfc::kPitchLengthM);
    r.z = std::clamp(r.z, 0.0f, tfc::kPitchWidthM);
    return r;
}

void DrawHeading(const tf::Vec3& pos, float facingRadians, float radius, const Vector2& origin, float scale, Color color)
{
    Vector2 center = ToScreen(pos, origin, scale);

    // Equilateral triangle anchored ahead of the circle, not centered on it.
    float side = radius * 1.4f;
    float height = std::sqrt(3.0f) * 0.5f * side;
    float offset = radius + height * 0.25f;  // keep it tucked near the edge

    // Define triangle in local space pointing "forward" (+z -> screen down).
    Vector2 tipLocal{0.0f, offset + height};
    Vector2 leftLocal{-side * 0.5f, offset};
    Vector2 rightLocal{side * 0.5f, offset};

    float s = std::sin(facingRadians);
    float c = std::cos(facingRadians);
    // Screen y grows downward; invert y for rotation to avoid left/right mirroring.
    auto Rotate = [&](const Vector2& v) {
        float ry = -v.y;
        float rx = v.x;
        float rx2 = rx * c - ry * s;
        float ry2 = rx * s + ry * c;
        return Vector2{rx2, -ry2};
    };

    Vector2 tip = Rotate(tipLocal);
    Vector2 left = Rotate(leftLocal);
    Vector2 right = Rotate(rightLocal);

    tip.x += center.x;
    tip.y += center.y;
    left.x += center.x;
    left.y += center.y;
    right.x += center.x;
    right.y += center.y;

    DrawTriangle(tip, right, left, color);
}

void DrawVisionCone(const tf::Player& player, const Vector2& origin, float scale)
{
    // Range scales with awareness and shrinks when breath is low.
    float breath = std::clamp(player.condition.breath, 0.0f, 1.0f);
    float range = tfc::kVisionRangeBase * (0.6f + player.stats.awareness * 0.8f) * (0.55f + 0.45f * breath);
    float halfAngle = tfc::kVisionHalfAngleDeg * (PI / 180.0f) * (0.65f + 0.55f * breath);

    float dirX = std::sin(player.state.facingRadians);
    float dirZ = std::cos(player.state.facingRadians);

    float s = std::sin(halfAngle);
    float c = std::cos(halfAngle);

    // Rotate direction by +-halfAngle for boundaries.
    float leftX = dirX * c - dirZ * s;
    float leftZ = dirX * s + dirZ * c;
    float rightX = dirX * c + dirZ * s;
    float rightZ = -dirX * s + dirZ * c;

    tf::Vec3 p = player.state.position;
    Vector2 center = ToScreen(p, origin, scale);
    Vector2 left = ToScreen({p.x + leftX * range, 0.0f, p.z + leftZ * range}, origin, scale);
    Vector2 right = ToScreen({p.x + rightX * range, 0.0f, p.z + rightZ * range}, origin, scale);

    DrawTriangle(center, right, left, tfc::kVisionColor);
    DrawTriangleLines(center, right, left, tfc::kVisionOutlineColor);
}

struct VisionHit
{
    bool hasHit{false};
    int playerId{-1};
};

VisionHit CheckVision(const tf::Player& viewer, const std::vector<tf::Player>& players, float rangeBase, float halfAngleRad)
{
    VisionHit hit{};
    float breath = std::clamp(viewer.condition.breath, 0.0f, 1.0f);
    float range = rangeBase * (0.6f + viewer.stats.awareness * 0.8f) * (0.55f + 0.45f * breath);
    float halfAng = halfAngleRad * (0.65f + 0.55f * breath);
    float dirX = std::sin(viewer.state.facingRadians);
    float dirZ = std::cos(viewer.state.facingRadians);

    for (const auto& p : players)
    {
        if (p.id == viewer.id) continue;
        float dx = p.state.position.x - viewer.state.position.x;
        float dz = p.state.position.z - viewer.state.position.z;
        float dist2 = dx * dx + dz * dz;
        if (dist2 > range * range) continue;
        float dist = std::sqrt(dist2);
        if (dist < 1e-3f) continue;
        float normX = dx / dist;
        float normZ = dz / dist;
        float dot = dirX * normX + dirZ * normZ;  // cos(theta)
        float ang = std::acos(std::clamp(dot, -1.0f, 1.0f));
        if (ang <= halfAng)
        {
            hit.hasHit = true;
            hit.playerId = p.id;
            break;
        }
    }
    return hit;
}
}  // namespace

int main()
{
    InitWindow(tfc::kWindowWidth, tfc::kWindowHeight, "Think Football");
    SetTargetFPS(60);

    const std::string fontPath = ResolveFontPath();
    Font hudFont = GetFontDefault();
    bool hudFontLoaded = false;
    if (!fontPath.empty())
    {
        std::vector<int> codepoints = BuildKoreanCodepoints();
        Font loaded = LoadFontEx(fontPath.c_str(), tfc::kFontSizeUI, codepoints.data(), static_cast<int>(codepoints.size()));
        if (loaded.texture.id != 0)
        {
            hudFont = loaded;
            hudFontLoaded = true;
            GuiSetFont(hudFont);
            std::cout << "Loaded raygui font: " << fontPath << std::endl;
        }
        else
        {
            std::cout << "Failed to load raygui font: " << fontPath << " (using default)" << std::endl;
        }
    }

    tf::WorldState world{};
    world.ball.pos = {tfc::kPitchLengthM * 0.5f, 0.0f, tfc::kPitchWidthM * 0.5f};
    world.pitch = tf::BuildStandardPitch(tfc::kPitchLengthM, tfc::kPitchWidthM);
    SeedRng(world, 42);
    world.teams[0].name = "Home";
    world.teams[1].name = "Away";
    world.teams[0].tactics = {0.55f, 0.55f, 0.75f, 0.5f, 0.6f};
    world.teams[1].tactics = {0.45f, 0.50f, 0.55f, 0.55f, 0.55f};

    // Create random players (3 per team) within their halves, spread across width.
    std::uniform_real_distribution<float> homeX(tfc::kPitchLengthM * 0.10f, tfc::kPitchLengthM * 0.45f);
    std::uniform_real_distribution<float> awayX(tfc::kPitchLengthM * 0.55f, tfc::kPitchLengthM * 0.90f);
    std::uniform_real_distribution<float> jitter(-2.0f, 2.0f);
    std::array<float, 3> zSlots = {tfc::kPitchWidthM * 0.2f, tfc::kPitchWidthM * 0.5f, tfc::kPitchWidthM * 0.8f};
    std::uniform_real_distribution<float> statMid(0.6f, 0.9f);
    std::uniform_real_distribution<float> statWide(0.55f, 0.95f);

    auto makePlayer = [&](int id, int teamIndex, const char* name, float zBase) {
        tf::Player p;
        p.id = id;
        p.name = name;
        p.teamIndex = teamIndex;
        float z = std::clamp(zBase + jitter(world.rng), 4.0f, tfc::kPitchWidthM - 4.0f);
        p.state.position = {teamIndex == 0 ? homeX(world.rng) : awayX(world.rng), 0.0f, z};
        p.intent.targetPos = p.state.position;
        p.stats.speed = statWide(world.rng);
        p.stats.accel = statWide(world.rng);
        p.stats.control = statMid(world.rng);
        p.stats.passGround = statMid(world.rng);
        p.stats.passLong = statMid(world.rng);
        p.stats.shoot = statWide(world.rng);
        p.stats.defend = statWide(world.rng);
        p.stats.awareness = statMid(world.rng);
        p.stats.composure = statMid(world.rng);
        p.stats.endurance = statWide(world.rng);
        return p;
    };

    for (int i = 0; i < 3; ++i) world.players.push_back(makePlayer(i, 0, TextFormat("Home_%d", i + 1), zSlots[i]));
    for (int i = 0; i < 3; ++i) world.players.push_back(makePlayer(3 + i, 1, TextFormat("Away_%d", i + 1), zSlots[i]));

    // Save initial positions for reset.
    std::vector<tf::Vec3> initialPositions;
    initialPositions.reserve(world.players.size());
    for (const auto& p : world.players) initialPositions.push_back(p.state.position);

    // Give initial control to the rearmost home player.
    auto homeIt = std::min_element(world.players.begin(), world.players.end(), [](const tf::Player& a, const tf::Player& b) {
        if (a.teamIndex != b.teamIndex) return a.teamIndex < b.teamIndex;
        return a.state.position.x < b.state.position.x;
    });
    if (homeIt != world.players.end() && homeIt->teamIndex == 0)
    {
        tf::BallClaimControl(world.ball, homeIt->id, homeIt->teamIndex, 0, homeIt->state.position);
    }

    tf::MovementArcade moveController;
    moveController.separationRadius = 4.0f;    // meters
    moveController.separationStrength = 8.0f;  // push harder when too close
    tf::BrainSimplePossession brainSimple;
    tf::TeamBrain teamBrain;
    int tickCount = 0;
    int passBlockId = -1;
    int passBlockUntil = 0;
    int scoreHome = 0;
    int scoreAway = 0;
    bool showVision = true;
    std::uniform_real_distribution<float> stealChance(0.0f, 1.0f);
    std::uniform_real_distribution<float> knockAngle(0.0f, 2.0f * PI);
    enum class RestartType
    {
        None,
        GoalKick,
        Corner,
        ThrowIn
    };
    RestartType restartMode = RestartType::None;
    int restartTeam = -1;
    tf::Vec3 restartSpot{};
    int restartResumeTick = 0;
    bool restartKickPending = false;
    tf::Vec3 restartKickTarget{};
    int restartKickerId = -1;

    while (!WindowShouldClose())
    {
        tf::AdvanceClock(world, tfc::kTargetDt);
        ++tickCount;
        if (IsKeyPressed(KEY_V)) showVision = !showVision;

        tf::GroupContext ctx;
        ctx.ballPos = world.ball.pos;
        ctx.pitchWidth = tfc::kPitchLengthM;
        ctx.pitchHeight = tfc::kPitchWidthM;
        teamBrain.ApplyTactics(world, ctx);
        for (auto& player : world.players)
        {
            TickPlayerWithBrain(player, world, ctx, moveController, brainSimple, tfc::kTargetDt);
            player.state.position = ClampToPitch(player.state.position);
        }

        // Reset hasBall flags.
        for (auto& player : world.players) player.state.hasBall = false;

        // Handle restart delays: keep ball parked until resume tick.
        if (restartMode != RestartType::None)
        {
            world.ball.pos = restartSpot;
            world.ball.vel = {0, 0, 0};
            world.ball.ownerPlayerId = -1;
            world.ball.mode = tf::BallMode::FreeGround;
            if (tickCount >= restartResumeTick)
            {
                // Pick kicker nearest to restartSpot on restartTeam.
                tf::Player* kicker = nullptr;
                float bestDist2 = 1e9f;
                for (auto& p : world.players)
                {
                    if (p.teamIndex != restartTeam) continue;
                    float dx = p.state.position.x - restartSpot.x;
                    float dz = p.state.position.z - restartSpot.z;
                    float d2 = dx * dx + dz * dz;
                    if (d2 < bestDist2)
                    {
                        bestDist2 = d2;
                        kicker = &p;
                    }
                }
                if (kicker)
                {
                    kicker->state.position = restartSpot;
                    kicker->intent.targetPos = restartSpot;
                    tf::BallClaimControl(world.ball, kicker->id, kicker->teamIndex, tickCount, kicker->state.position);

                    // Simple restart pass target: farthest forward teammate, else clear into space toward opponent goal and center line.
                    float bestFwd = (restartTeam == 0) ? -1e9f : 1e9f;
                    tf::Vec3 bestPos = restartSpot;
                    for (auto& mate : world.players)
                    {
                        if (mate.teamIndex != restartTeam || mate.id == kicker->id) continue;
                        if (restartTeam == 0)
                        {
                            if (mate.state.position.x > bestFwd)
                            {
                                bestFwd = mate.state.position.x;
                                bestPos = mate.state.position;
                            }
                        }
                        else
                        {
                            if (mate.state.position.x < bestFwd)
                            {
                                bestFwd = mate.state.position.x;
                                bestPos = mate.state.position;
                            }
                        }
                    }
                    if ((bestFwd == -1e9f && restartTeam == 0) || (bestFwd == 1e9f && restartTeam == 1))
                    {
                        float dir = (restartTeam == 0) ? 1.0f : -1.0f;
                        bestPos = {restartSpot.x + dir * 15.0f, 0.0f, world.pitch.width * 0.5f};
                    }
                    kicker->intent.targetPos = bestPos;
                    kicker->intent.action = tf::RequestedAction::Pass;
                    restartKickPending = true;
                    restartKickTarget = bestPos;
                    restartKickerId = kicker->id;
                }
                restartMode = RestartType::None;
            }
        }

        // Handle possession/pass actions.
        const float controlRadius = 0.7f; // meters
        if (world.ball.mode == tf::BallMode::Controlled)
        {
            tf::Player* ownerPtr = nullptr;
            float ownerBreath = 1.0f;
            float ownerSpeed = 0.0f;
            for (auto& player : world.players)
            {
                if (player.id == world.ball.ownerPlayerId)
                {
                    player.state.hasBall = true;
                    ownerPtr = &player;
                    ownerBreath = std::clamp(player.condition.breath, 0.0f, 1.0f);
                    ownerSpeed = std::sqrt(player.state.velocity.x * player.state.velocity.x +
                                           player.state.velocity.z * player.state.velocity.z);
                    // Auto-kick on restart if pending.
                    if (restartKickPending && player.id == restartKickerId)
                    {
                        tf::Vec3 target = restartKickTarget;
                        tf::Vec3 dir{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
                        float len = std::sqrt(dir.x * dir.x + dir.z * dir.z);
                        if (len > 0.5f)
                        {
                            dir.x /= len;
                            dir.z /= len;
                            const float passSpeed = 18.0f;
                            tf::Vec3 vel{dir.x * passSpeed, 0.0f, dir.z * passSpeed};
                            tf::Vec3 startPos{player.state.position.x + dir.x * 0.5f, 0.0f, player.state.position.z + dir.z * 0.5f};
                            tf::BallKickGround(world.ball, player.id, player.teamIndex, tickCount, startPos, vel);
                            passBlockId = player.id;
                            passBlockUntil = tickCount + 30;
                            player.condition.breath = std::min(1.0f, player.condition.breath + 0.15f); // catch breath after pass
                        }
                        restartKickPending = false;
                        restartKickerId = -1;
                    }
                    else if (player.intent.action == tf::RequestedAction::Pass)
                    {
                        tf::Vec3 target = ClampToPitch(player.intent.targetPos);
                        tf::Vec3 dir{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
                        float len = std::sqrt(dir.x * dir.x + dir.z * dir.z);
                        if (len > 1e-3f)
                        {
                            dir.x /= len;
                            dir.z /= len;
                            const float passSpeed = 18.0f; // m/s simple flat pass
                            tf::Vec3 vel{dir.x * passSpeed, 0.0f, dir.z * passSpeed};
                            tf::Vec3 startPos{player.state.position.x + dir.x * 0.5f, 0.0f, player.state.position.z + dir.z * 0.5f};
                            tf::BallKickGround(world.ball, player.id, player.teamIndex, tickCount, startPos, vel);
                            passBlockId = player.id;
                            passBlockUntil = tickCount + 30; // block kicker reclaim for 30 ticks (~0.5s)
                            player.condition.breath = std::min(1.0f, player.condition.breath + 0.12f);
                        }
                    }
                    else if (player.intent.action == tf::RequestedAction::Shoot)
                    {
                        tf::Vec3 target = (player.teamIndex == 0)
                                              ? tf::Vec3{world.pitch.length, 0.0f, world.pitch.width * 0.5f}
                                              : tf::Vec3{0.0f, 0.0f, world.pitch.width * 0.5f};
                        tf::Vec3 dir{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
                        float len = std::sqrt(dir.x * dir.x + dir.z * dir.z);
                        if (len > 1e-3f)
                        {
                            dir.x /= len;
                            dir.z /= len;
                            const float shotSpeed = 28.0f; // faster shot
                            tf::Vec3 vel{dir.x * shotSpeed, 0.0f, dir.z * shotSpeed};
                            tf::Vec3 startPos{player.state.position.x + dir.x * 0.5f, 0.0f, player.state.position.z + dir.z * 0.5f};
                            tf::BallKickGround(world.ball, player.id, player.teamIndex, tickCount, startPos, vel);
                            passBlockId = player.id;
                            passBlockUntil = tickCount + 45; // block reclaim slightly longer on shot
                        }
                    }
                    else
                    {
                        world.ball.pos = player.state.position;
                    }

                    // Winded high-speed carriers can fumble forward.
                    if (world.ball.mode == tf::BallMode::Controlled && world.ball.ownerPlayerId == player.id)
                    {
                        if (ownerSpeed > 6.0f && ownerBreath < 0.45f)
                        {
                            float dropProb = std::clamp((ownerSpeed - 6.0f) * 0.08f + (0.5f - ownerBreath) * 0.6f, 0.0f, 0.65f);
                            if (stealChance(world.rng) < dropProb)
                            {
                                float ang = knockAngle(world.rng);
                                tf::Vec3 vel{std::cos(ang) * 9.0f, 0.0f, std::sin(ang) * 9.0f};
                                tf::Vec3 startPos{world.ball.pos.x + vel.x * 0.1f, 0.0f, world.ball.pos.z + vel.z * 0.1f};
                                tf::BallKickGround(world.ball, player.id, player.teamIndex, tickCount, startPos, vel);
                                world.ball.ownerPlayerId = -1;
                                passBlockId = -1;
                            }
                        }
                    }
                }
            }

            // Possession contests: opponents near the owner may steal or knock loose.
            for (auto& player : world.players)
            {
                if (player.id == world.ball.ownerPlayerId) continue;
                float dx = player.state.position.x - world.ball.pos.x;
                float dz = player.state.position.z - world.ball.pos.z;
                float dist2 = dx * dx + dz * dz;
                if (dist2 <= 1.2f * 1.2f)
                {
                    // Simple probabilistic steal/loose ball.
                    float dist = std::sqrt(dist2);
                    float stealProb = 0.7f + (1.2f - dist) * 0.3f; // up to 1.0
                    if (ownerPtr)
                    {
                        stealProb *= (1.0f + (1.0f - std::clamp(ownerPtr->condition.breath, 0.0f, 1.0f)) * 0.6f);
                        float ownerSpd = std::sqrt(ownerPtr->state.velocity.x * ownerPtr->state.velocity.x +
                                                   ownerPtr->state.velocity.z * ownerPtr->state.velocity.z);
                        if (ownerSpd > 6.0f) stealProb += 0.1f;
                        stealProb = std::min(1.0f, stealProb);
                    }

                    // Facing/touchline bias: if owner near touchline and defender facing outward, raise steal/throw-out chance.
                    float outwardX = 0.0f, outwardZ = 0.0f;
                    const float touchThresh = 2.0f;
                    if (world.ball.pos.z < touchThresh)
                    {
                        outwardZ = -1.0f;
                    }
                    else if (world.ball.pos.z > world.pitch.width - touchThresh)
                    {
                        outwardZ = 1.0f;
                    }
                    float fx = std::sin(player.state.facingRadians);
                    float fz = std::cos(player.state.facingRadians);
                    if (outwardZ != 0.0f)
                    {
                        float dot = fx * outwardX + fz * outwardZ;
                        if (dot > 0.3f) stealProb = std::min(1.0f, stealProb + 0.2f);
                    }

                    float r = stealChance(world.rng);
                    if (r < stealProb)
                    {
                        // Steal
                        tf::BallClaimControl(world.ball, player.id, player.teamIndex, tickCount, player.state.position);
                        player.state.hasBall = true;
                        // Kick attacker away directionally to avoid instant steal-back
                        float ang = knockAngle(world.rng);
                        // If near touchline, bias away from line
                        if (outwardZ != 0.0f) ang = (outwardZ < 0) ? -PI * 0.5f : PI * 0.5f;
                        player.intent.targetPos = {player.state.position.x + std::cos(ang) * 8.0f, 0.0f, player.state.position.z + std::sin(ang) * 8.0f};
                        player.intent.action = tf::RequestedAction::None;
                        passBlockId = player.id;
                        passBlockUntil = tickCount + 30;
                    }
                    else
                    {
                        // Loose ball knock out
                        float ang = knockAngle(world.rng);
                        if (outwardZ != 0.0f) ang = (outwardZ < 0) ? -PI * 0.5f : PI * 0.5f;
                        tf::Vec3 vel{std::cos(ang) * 10.0f, 0.0f, std::sin(ang) * 10.0f};
                        tf::Vec3 startPos{world.ball.pos.x + vel.x * 0.1f, 0.0f, world.ball.pos.z + vel.z * 0.1f};
                        tf::BallKickGround(world.ball, world.ball.ownerPlayerId, world.ball.lastTouch.teamId, tickCount, startPos, vel);
                        world.ball.ownerPlayerId = -1;
                        passBlockId = -1;
                    }
                    break;
                }
            }
        }

        // Claim control if free and close.
        if (world.ball.mode != tf::BallMode::Controlled)
        {
            for (auto& player : world.players)
            {
                if (passBlockId == player.id && tickCount < passBlockUntil) continue;
                float dx = player.state.position.x - world.ball.pos.x;
                float dz = player.state.position.z - world.ball.pos.z;
                float dist2 = dx * dx + dz * dz;
                if (dist2 <= controlRadius * controlRadius)
                {
                    tf::BallClaimControl(world.ball, player.id, player.teamIndex, tickCount, player.state.position);
                    player.state.hasBall = true;
                    break;
                }
            }
        }

        tf::BallTick(world.ball, tickCount, tfc::kTargetDt);
        // Out-of-play handling: goal/goal-kick/corner/throw-in.
        bool oobEndline = (world.ball.pos.x < 0.0f) || (world.ball.pos.x > world.pitch.length);
        bool oobSideline = (world.ball.pos.z < 0.0f) || (world.ball.pos.z > world.pitch.width);
        if ((oobEndline || oobSideline) && restartMode == RestartType::None)
        {
            int lastTeam = world.ball.lastTouch.teamId;
            if (oobEndline)
            {
                int defendingTeam = (world.ball.pos.x < 0.0f) ? 0 : 1;
                int attackingTeam = 1 - defendingTeam;
                bool corner = (lastTeam == defendingTeam);  // deflected by defender
                if (corner)
                {
                    restartMode = RestartType::Corner;
                    restartTeam = attackingTeam;
                    float cornerX = (defendingTeam == 0) ? 0.0f : world.pitch.length;
                    float cornerZ = (world.ball.pos.z < world.pitch.width * 0.5f) ? 0.0f : world.pitch.width;
                    restartSpot = {cornerX, 0.0f, cornerZ};
                }
                else
                {
                    restartMode = RestartType::GoalKick;
                    restartTeam = defendingTeam;
                    const auto& ga = world.pitch.goalArea[defendingTeam];
                    float spotX = (defendingTeam == 0) ? ga.x + ga.width + 0.5f : ga.x - 0.5f;
                    float spotZ = world.pitch.width * 0.5f;
                    restartSpot = {spotX, 0.0f, spotZ};
                }
            }
            else if (oobSideline)
            {
                restartMode = RestartType::ThrowIn;
                restartTeam = (lastTeam == 0) ? 1 : 0;  // opponent throws
                float spotX = std::clamp(world.ball.pos.x, 0.0f, world.pitch.length);
                float spotZ = (world.ball.pos.z < 0.0f) ? 0.0f : world.pitch.width;
                restartSpot = {spotX, 0.0f, spotZ};
            }
            restartResumeTick = tickCount + 60;  // ~1 second delay
            world.ball.ownerPlayerId = -1;
            world.ball.mode = tf::BallMode::FreeGround;
            world.ball.vel = {0, 0, 0};
        }
        // Goal detection
        const float halfGoal = world.pitch.goalWidth * 0.5f;
        bool scored = false;
        if (world.ball.pos.x <= 0.0f &&
            std::abs(world.ball.pos.z - world.pitch.goalCenter[0].z) <= halfGoal)
        {
            // Away team scores
            scoreAway += 1;
            scored = true;
        }
        else if (world.ball.pos.x >= world.pitch.length &&
                 std::abs(world.ball.pos.z - world.pitch.goalCenter[1].z) <= halfGoal)
        {
            // Home team scores
            scoreHome += 1;
            scored = true;
        }
        if (scored)
        {
            // Reset players to initial positions.
            for (size_t i = 0; i < world.players.size() && i < initialPositions.size(); ++i)
            {
                world.players[i].state.position = initialPositions[i];
                world.players[i].state.velocity = {0, 0, 0};
                world.players[i].intent.targetPos = initialPositions[i];
            }
            // Determine conceding team: if home scored, away kicks off; vice versa.
            int concedingTeam = (world.ball.pos.x <= 0.0f) ? 0 : 1;
            // Ball to center.
            world.ball.pos = {world.pitch.length * 0.5f, 0.0f, world.pitch.width * 0.5f};
            world.ball.vel = {0, 0, 0};
            world.ball.ownerPlayerId = -1;
            world.ball.mode = tf::BallMode::FreeGround;
            passBlockId = -1;
            passBlockUntil = tickCount + 60;

            // Find rearmost player of conceding team and give kickoff at center.
            tf::Player* kicker = nullptr;
            for (auto& p : world.players)
            {
                if (p.teamIndex != concedingTeam) continue;
                if (!kicker || p.state.position.x < kicker->state.position.x) kicker = &p;
            }
            if (kicker)
            {
                kicker->state.position = world.ball.pos;
                kicker->intent.targetPos = kicker->state.position;
                tf::BallClaimControl(world.ball, kicker->id, kicker->teamIndex, tickCount, kicker->state.position);
                // Set intent to pass to nearest teammate ahead.
                float bestFwd = -1e9f;
                tf::Vec3 bestPos = world.ball.pos;
                for (auto& mate : world.players)
                {
                    if (mate.teamIndex != concedingTeam || mate.id == kicker->id) continue;
                    float dx = mate.state.position.x - kicker->state.position.x;
                    if ((concedingTeam == 0 && dx <= 0) || (concedingTeam == 1 && dx >= 0)) continue;
                    if (dx > bestFwd)
                    {
                        bestFwd = dx;
                        bestPos = mate.state.position;
                    }
                }
                kicker->intent.targetPos = bestPos;
                kicker->intent.action = tf::RequestedAction::Pass;
            }
        }
        // Keep ball within touch/end lines.
        if (world.ball.pos.x < 0.0f)
        {
            world.ball.pos.x = 0.0f;
            world.ball.vel.x = 0.0f;
        }
        else if (world.ball.pos.x > tfc::kPitchLengthM)
        {
            world.ball.pos.x = tfc::kPitchLengthM;
            world.ball.vel.x = 0.0f;
        }
        if (world.ball.pos.z < 0.0f)
        {
            world.ball.pos.z = 0.0f;
            world.ball.vel.z = 0.0f;
        }
        else if (world.ball.pos.z > tfc::kPitchWidthM)
        {
            world.ball.pos.z = tfc::kPitchWidthM;
            world.ball.vel.z = 0.0f;
        }

        BeginDrawing();
        ClearBackground(DARKGREEN);

        // Layout bounds
        Rectangle gameArea = {tfc::kPitchOffsetX, tfc::kPitchOffsetY, (float)tfc::kGameWidth, (float)tfc::kGameHeight};
        Rectangle sidebarTop = {gameArea.x + gameArea.width, tfc::kPitchOffsetY, (float)tfc::kSidebarWidth, 480};
        Rectangle sidebarBottom = {sidebarTop.x, sidebarTop.y + sidebarTop.height, (float)tfc::kSidebarWidth, (float)tfc::kWindowHeight - (sidebarTop.y + sidebarTop.height)};
        Rectangle bottomBar = {tfc::kPitchOffsetX, gameArea.y + gameArea.height, (float)tfc::kGameWidth, (float)tfc::kWindowHeight - (gameArea.y + gameArea.height)};

        // Compute pitch draw rect with preserved aspect ratio and generous margins.
        float availW = tfc::kGameWidth - 2.0f * tfc::kPitchScreenMargin;
        float availH = tfc::kGameHeight - 2.0f * tfc::kPitchScreenMargin;
        float scale = std::min(availW / tfc::kPitchLengthM, availH / tfc::kPitchWidthM);
        float pitchDrawW = tfc::kPitchLengthM * scale;
        float pitchDrawH = tfc::kPitchWidthM * scale;
        Vector2 pitchOrigin{gameArea.x + (tfc::kGameWidth - pitchDrawW) * 0.5f, gameArea.y + (tfc::kGameHeight - pitchDrawH) * 0.5f};
        Rectangle pitchRect = {pitchOrigin.x, pitchOrigin.y, pitchDrawW, pitchDrawH};

        // Game area and pitch
        DrawRectangleRec(gameArea, tfc::kPitchOuterColor);
        DrawRectangleRec(pitchRect, tfc::kPitchInnerColor);
        DrawRectangleLinesEx(pitchRect, 3, tfc::kLineColor);
        // Draw pitch markings using geometry (in meters, converted to screen).
        const auto& pg = world.pitch;
        auto toScreenRect = [&](const tf::RectXZ& r) {
            Vector2 tl = ToScreen({r.x, 0.0f, r.z}, pitchOrigin, scale);
            return Rectangle{tl.x, tl.y, r.width * scale, r.height * scale};
        };
        auto drawRect = [&](const tf::RectXZ& r, float thickness = 2.0f) {
            DrawRectangleLinesEx(toScreenRect(r), thickness, tfc::kLineColor);
        };
        auto drawSegment = [&](const tf::Segment& s) {
            Vector2 a = ToScreen(s.a, pitchOrigin, scale);
            Vector2 b = ToScreen(s.b, pitchOrigin, scale);
            DrawLineEx(a, b, 2.0f, tfc::kLineColor);
        };
        drawSegment(pg.halfLine);
        DrawCircleLines((int)(ToScreen(pg.centerSpot, pitchOrigin, scale).x),
                        (int)(ToScreen(pg.centerSpot, pitchOrigin, scale).y),
                        pg.centerCircle.radius * scale, tfc::kLineColor);
        drawRect(pg.penaltyArea[0]);
        drawRect(pg.penaltyArea[1]);
        drawRect(pg.goalArea[0]);
        drawRect(pg.goalArea[1]);
        for (const auto& spot : pg.penaltySpot)
        {
            Vector2 p = ToScreen(spot, pitchOrigin, scale);
            DrawCircle((int)p.x, (int)p.y, 3.0f, tfc::kLineColor);
        }
        // Corner arcs as small circles for now.
        for (const auto& c : pg.cornerArc)
        {
            Vector2 p = ToScreen(c.center, pitchOrigin, scale);
            DrawCircleLines((int)p.x, (int)p.y, c.radius * scale, tfc::kLineColor);
        }
        // Goal posts (simple representation)
        const float goalHalfWidth = pg.goalWidth * 0.5f;
        float postRadius = pg.goalPostRadius * scale;
        Vector2 leftPostHome = ToScreen({0.0f, 0.0f, pg.goalCenter[0].z - halfGoal}, pitchOrigin, scale);
        Vector2 rightPostHome = ToScreen({0.0f, 0.0f, pg.goalCenter[0].z + goalHalfWidth}, pitchOrigin, scale);
        Vector2 leftPostAway = ToScreen({pg.goalCenter[1].x, 0.0f, pg.goalCenter[1].z - goalHalfWidth}, pitchOrigin, scale);
        Vector2 rightPostAway = ToScreen({pg.goalCenter[1].x, 0.0f, pg.goalCenter[1].z + goalHalfWidth}, pitchOrigin, scale);
        DrawCircle((int)leftPostHome.x, (int)leftPostHome.y, postRadius, tfc::kLineColor);
        DrawCircle((int)rightPostHome.x, (int)rightPostHome.y, postRadius, tfc::kLineColor);
        DrawCircle((int)leftPostAway.x, (int)leftPostAway.y, postRadius, tfc::kLineColor);
        DrawCircle((int)rightPostAway.x, (int)rightPostAway.y, postRadius, tfc::kLineColor);
        // Players and ball
        for (const auto& player : world.players)
        {
            Vector2 sp = ToScreen(player.state.position, pitchOrigin, scale);
            Color c = (player.teamIndex == 0) ? tfc::kHomeColor : tfc::kAwayColor;
            // Vision highlight: if this player is seen by the owner of the ball.
            if (world.ball.mode == tf::BallMode::Controlled)
            {
                auto ownerIt = std::find_if(world.players.begin(), world.players.end(),
                                            [&](const tf::Player& p) { return p.id == world.ball.ownerPlayerId; });
                if (ownerIt != world.players.end() && ownerIt->id != player.id)
                {
                    VisionHit vh = CheckVision(*ownerIt, world.players, tfc::kVisionRangeBase, tfc::kVisionHalfAngleDeg * (PI / 180.0f));
                    if (vh.hasHit && vh.playerId == player.id)
                    {
                        c = ColorAlpha(c, 0.8f);
                        DrawCircleLines((int)sp.x, (int)sp.y, tfc::kPlayerOutlineRadius + 2.0f, tfc::kVisionOutlineColor);
                    }
                }
            }
            // Draw heading first (under the circle).
            if (showVision) DrawVisionCone(player, pitchOrigin, scale);
            DrawHeading(player.state.position, player.state.facingRadians, tfc::kHeadingRadius, pitchOrigin, scale, tfc::kHeadingColor);
            DrawCircle((int)sp.x, (int)sp.y, tfc::kPlayerRadius, c);
            DrawCircleLines((int)sp.x, (int)sp.y, tfc::kPlayerOutlineRadius, tfc::kPlayerLabelColor);
            Vector2 labelPos{sp.x - 16.0f, sp.y - 28.0f};
            DrawTextEx(hudFont, player.name.c_str(), labelPos, (float)tfc::kPlayerLabelSize, 0.0f, tfc::kPlayerLabelColor);
        }
        {
            Vector2 bp = ToScreen(world.ball.pos, pitchOrigin, scale);
            DrawCircle((int)bp.x, (int)bp.y, tfc::kBallRadius, tfc::kBallColor);
        }

        // Scoreboard at top center of pitch area
        std::string scoreText = TextFormat("HOME %d : %d AWAY", scoreHome, scoreAway);
        Vector2 scoreSize = MeasureTextEx(hudFont, scoreText.c_str(), (float)tfc::kHudTitleSize, 0.0f);
        Vector2 scorePos{pitchRect.x + pitchRect.width * 0.5f - scoreSize.x * 0.5f, pitchRect.y - scoreSize.y - 6.0f};
        DrawTextEx(hudFont, scoreText.c_str(), scorePos, (float)tfc::kHudTitleSize, 0.0f, tfc::kHudTextColor);

        // HUD text inside game area
        // const char* hud = reinterpret_cast<const char*>(u8"Think Football – 전략형 축구 시뮬레이션");
        // DrawTextEx(hudFont, hud, {24, 20}, (float)tfc::kHudTitleSize, 0.0f, tfc::kHudTextColor);

        // Sidebar top: info_aux
        GuiPanel(sidebarTop, "Info");
        GuiLabel({sidebarTop.x + 10, sidebarTop.y + 20, sidebarTop.width - 20, 20}, "Think Football HUD");
        GuiLabel({sidebarTop.x + 10, sidebarTop.y + 45, sidebarTop.width - 20, 20}, TextFormat("Clock: %.2f s", world.clock.timeSeconds));
        GuiLabel({sidebarTop.x + 10, sidebarTop.y + 70, sidebarTop.width - 20, 40}, "ASCII: ABC abc 123 !@#$%");
        GuiLabel({sidebarTop.x + 10, sidebarTop.y + 110, sidebarTop.width - 20, 60}, reinterpret_cast<const char*>(u8"한글: 성공적으로 이 텍스트가 보여야 합니다."));

        // Sidebar bottom: commands/instructions
        GuiPanel(sidebarBottom, "Commands");
        GuiLabel({sidebarBottom.x + 10, sidebarBottom.y + 20, sidebarBottom.width - 20, 20}, "지시/전술 입력 영역");
        GuiLabel({sidebarBottom.x + 10, sidebarBottom.y + 45, sidebarBottom.width - 20, 60}, reinterpret_cast<const char*>(u8"여기에 전술/지시 UI를 배치할 예정입니다."));

        // Bottom bar (under game area)
        GuiPanel(bottomBar, "");
        GuiLabel({bottomBar.x + 10, bottomBar.y + 10, bottomBar.width - 20, 20}, "Bottom Info");
        GuiLabel({bottomBar.x + 10, bottomBar.y + 35, bottomBar.width - 20, 40}, reinterpret_cast<const char*>(u8"여기는 추가 정보/로그를 넣을 수 있는 하단 영역입니다."));

        EndDrawing();
    }

    if (hudFontLoaded) UnloadFont(hudFont);
    CloseWindow();
    return 0;
}

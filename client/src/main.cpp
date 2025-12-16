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
    // Range scales modestly with awareness stat.
    float range = tfc::kVisionRangeBase * (0.6f + player.stats.awareness * 0.8f);
    float halfAngle = tfc::kVisionHalfAngleDeg * (PI / 180.0f);

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

    auto makePlayer = [&](int id, int teamIndex, const char* name, float zBase) {
        tf::Player p;
        p.id = id;
        p.name = name;
        p.teamIndex = teamIndex;
        float z = std::clamp(zBase + jitter(world.rng), 4.0f, tfc::kPitchWidthM - 4.0f);
        p.state.position = {teamIndex == 0 ? homeX(world.rng) : awayX(world.rng), 0.0f, z};
        p.intent.targetPos = p.state.position;
        p.stats.speed = 0.8f;
        p.stats.accel = 0.8f;
        return p;
    };

    for (int i = 0; i < 3; ++i) world.players.push_back(makePlayer(i, 0, TextFormat("Home_%d", i + 1), zSlots[i]));
    for (int i = 0; i < 3; ++i) world.players.push_back(makePlayer(3 + i, 1, TextFormat("Away_%d", i + 1), zSlots[i]));

    // Give initial control to first home player.
    tf::BallClaimControl(world.ball, world.players.front().id, world.players.front().teamIndex, 0, world.players.front().state.position);

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

        // Handle possession/pass actions.
        const float controlRadius = 0.7f; // meters
        if (world.ball.mode == tf::BallMode::Controlled)
        {
            for (auto& player : world.players)
            {
                if (player.id == world.ball.ownerPlayerId)
                {
                    player.state.hasBall = true;
                    if (player.intent.action == tf::RequestedAction::Pass)
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
            // Reset ball to center, free state
            world.ball.pos = {world.pitch.length * 0.5f, 0.0f, world.pitch.width * 0.5f};
            world.ball.vel = {0, 0, 0};
            world.ball.ownerPlayerId = -1;
            world.ball.mode = tf::BallMode::FreeGround;
            passBlockId = -1;
            passBlockUntil = tickCount + 60;
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

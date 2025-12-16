#include <raylib.h>
#include "raygui.h"

#include <filesystem>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cmath>

#include "thinkfootball/brain.h"
#include "thinkfootball/world_state.h"

namespace
{
constexpr int kGameWidth = 1280;
constexpr int kGameHeight = 720;
constexpr int kSidebarWidth = 360;
constexpr int kWindowWidth = kGameWidth + kSidebarWidth;
constexpr int kWindowHeight = 960;  // extra space for bottom panels
constexpr float kPitchOffsetX = 16.0f;
constexpr float kPitchOffsetY = 16.0f;
constexpr float kPitchScreenMargin = 48.0f;  // keep pitch well inside the viewport
constexpr float kTargetDt = 1.0f / 60.0f;
// Use a landscape pitch: x axis ~length 105m, z axis ~width 68m.
constexpr float kPitchWidthM = 105.0f;  // meters (x-axis, length)
constexpr float kPitchHeightM = 68.0f;  // meters (z-axis, width)

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
    r.x = std::clamp(r.x, 0.0f, kPitchWidthM);
    r.z = std::clamp(r.z, 0.0f, kPitchHeightM);
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
}  // namespace

int main()
{
    InitWindow(kWindowWidth, kWindowHeight, "Think Football");
    SetTargetFPS(60);

    const std::string fontPath = ResolveFontPath();
    Font hudFont = GetFontDefault();
    bool hudFontLoaded = false;
    if (!fontPath.empty())
    {
        std::vector<int> codepoints = BuildKoreanCodepoints();
        Font loaded = LoadFontEx(fontPath.c_str(), 24, codepoints.data(), static_cast<int>(codepoints.size()));
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
    world.ball.pos = {kPitchWidthM * 0.5f, 0.0f, kPitchHeightM * 0.5f};
    SeedRng(world, 42);
    world.teams[0].name = "Home";
    world.teams[1].name = "Away";
    world.teams[0].tactics = {0.55f, 0.55f, 0.65f, 0.5f, 0.6f};
    world.teams[1].tactics = {0.45f, 0.50f, 0.55f, 0.55f, 0.55f};

    // Simple two players with chase-ball brains.
    tf::Player p1;
    p1.id = 0;
    p1.name = "Home_1";
    p1.teamIndex = 0;
    p1.state.position = {kPitchWidthM * 0.4f, 0.0f, kPitchHeightM * 0.6f};
    p1.intent.targetPos = p1.state.position;
    p1.stats.speed = 0.8f;
    p1.stats.accel = 0.8f;

    tf::Player p2;
    p2.id = 1;
    p2.name = "Away_1";
    p2.teamIndex = 1;
    p2.state.position = {kPitchWidthM * 0.8f, 0.0f, kPitchHeightM * 0.4f};
    p2.intent.targetPos = p2.state.position;
    p2.stats.speed = 0.8f;
    p2.stats.accel = 0.8f;

    world.players.push_back(p1);
    world.players.push_back(p2);

    tf::MovementArcade moveController;
    tf::BrainSimplePossession brainSimple;
    tf::TeamBrain teamBrain;
    int tickCount = 0;

    while (!WindowShouldClose())
    {
        tf::AdvanceClock(world, kTargetDt);
        ++tickCount;

        tf::GroupContext ctx;
        ctx.ballPos = world.ball.pos;
        ctx.pitchWidth = kPitchWidthM;
        ctx.pitchHeight = kPitchHeightM;
        teamBrain.ApplyTactics(world, ctx);
        for (auto& player : world.players)
        {
            TickPlayerWithBrain(player, world, ctx, moveController, brainSimple, kTargetDt);
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
                            tf::BallKickGround(world.ball, player.id, player.teamIndex, tickCount, player.state.position, vel);
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

        tf::BallTick(world.ball, tickCount, kTargetDt);
        // Keep ball within touch/end lines.
        if (world.ball.pos.x < 0.0f)
        {
            world.ball.pos.x = 0.0f;
            world.ball.vel.x = 0.0f;
        }
        else if (world.ball.pos.x > kPitchWidthM)
        {
            world.ball.pos.x = kPitchWidthM;
            world.ball.vel.x = 0.0f;
        }
        if (world.ball.pos.z < 0.0f)
        {
            world.ball.pos.z = 0.0f;
            world.ball.vel.z = 0.0f;
        }
        else if (world.ball.pos.z > kPitchHeightM)
        {
            world.ball.pos.z = kPitchHeightM;
            world.ball.vel.z = 0.0f;
        }

        BeginDrawing();
        ClearBackground(DARKGREEN);

        // Layout bounds
        Rectangle gameArea = {kPitchOffsetX, kPitchOffsetY, (float)kGameWidth, (float)kGameHeight};
        Rectangle sidebarTop = {gameArea.x + gameArea.width, kPitchOffsetY, (float)kSidebarWidth, 480};
        Rectangle sidebarBottom = {sidebarTop.x, sidebarTop.y + sidebarTop.height, (float)kSidebarWidth, (float)kWindowHeight - (sidebarTop.y + sidebarTop.height)};
        Rectangle bottomBar = {kPitchOffsetX, gameArea.y + gameArea.height, (float)kGameWidth, (float)kWindowHeight - (gameArea.y + gameArea.height)};

        // Compute pitch draw rect with preserved aspect ratio and generous margins.
        float availW = kGameWidth - 2.0f * kPitchScreenMargin;
        float availH = kGameHeight - 2.0f * kPitchScreenMargin;
        float scale = std::min(availW / kPitchWidthM, availH / kPitchHeightM);
        float pitchDrawW = kPitchWidthM * scale;
        float pitchDrawH = kPitchHeightM * scale;
        Vector2 pitchOrigin{gameArea.x + (kGameWidth - pitchDrawW) * 0.5f, gameArea.y + (kGameHeight - pitchDrawH) * 0.5f};
        Rectangle pitchRect = {pitchOrigin.x, pitchOrigin.y, pitchDrawW, pitchDrawH};

        // Game area and pitch
        DrawRectangleRec(gameArea, Color{0, 80, 0, 255});
        DrawRectangleRec(pitchRect, Color{0, 100, 0, 255});
        DrawRectangleLinesEx(pitchRect, 3, RAYWHITE);
        // Players and ball
        for (const auto& player : world.players)
        {
            Vector2 sp = ToScreen(player.state.position, pitchOrigin, scale);
            Color c = (player.teamIndex == 0) ? SKYBLUE : RED;
            // Draw heading first (under the circle).
            DrawHeading(player.state.position, player.state.facingRadians, 10.0f, pitchOrigin, scale, Fade(YELLOW, 0.9f));
            DrawCircle((int)sp.x, (int)sp.y, 12.0f, c);
            DrawCircleLines((int)sp.x, (int)sp.y, 14.0f, DARKGRAY);
            Vector2 labelPos{sp.x - 16.0f, sp.y - 28.0f};
            DrawTextEx(hudFont, player.name.c_str(), labelPos, 24.0f, 0.0f, DARKGRAY);
        }
        {
            Vector2 bp = ToScreen(world.ball.pos, pitchOrigin, scale);
            DrawCircle((int)bp.x, (int)bp.y, 6.0f, ORANGE);
        }

        // HUD text inside game area
        const char* hud = reinterpret_cast<const char*>(u8"Think Football – 전략형 축구 시뮬레이션");
        DrawTextEx(hudFont, hud, {24, 20}, 36.0f, 0.0f, DARKGRAY);

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

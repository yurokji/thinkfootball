#include <raylib.h>
#include "raygui.h"

#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

#include "thinkfootball/world_state.h"

namespace
{
constexpr int kGameWidth = 1280;
constexpr int kGameHeight = 720;
constexpr int kSidebarWidth = 360;
constexpr int kWindowWidth = kGameWidth + kSidebarWidth;
constexpr int kWindowHeight = 960;  // extra space for bottom panels
constexpr float kTargetDt = 1.0f / 60.0f;

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
    world.ball.position = {kGameWidth * 0.5f, 0.0f, kGameHeight * 0.5f};

    while (!WindowShouldClose())
    {
        tf::AdvanceClock(world, kTargetDt);

        BeginDrawing();
        ClearBackground(DARKGREEN);

        // Layout bounds
        Rectangle gameArea = {0, 0, (float)kGameWidth, (float)kGameHeight};
        Rectangle sidebarTop = {kGameWidth, 0, (float)kSidebarWidth, 480};
        Rectangle sidebarBottom = {kGameWidth, sidebarTop.y + sidebarTop.height, (float)kSidebarWidth, (float)kWindowHeight - (sidebarTop.y + sidebarTop.height)};
        Rectangle bottomBar = {0, (float)kGameHeight, (float)kGameWidth, (float)kWindowHeight - kGameHeight};

        // Game area frame
        DrawRectangleLines((int)gameArea.x + 20, (int)gameArea.y + 40, (int)gameArea.width - 40, (int)gameArea.height - 80, RAYWHITE);
        DrawCircle((int)world.ball.position.x, (int)world.ball.position.z, 6.0f, ORANGE);

        // HUD text inside game area
        const char* hud = reinterpret_cast<const char*>(u8"Think Football – 전략형 축구 시뮬레이션");
        DrawTextEx(hudFont, hud, {24, 20}, 24.0f, 0.0f, RAYWHITE);

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

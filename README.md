# Think Football

Prototype scaffolding for a strategic, non-player-controlled football game.

## Build & Run

```bash
cmake -S . -B build
cmake --build build
./build/thinkfootball_client
```

Requirements: CMake 3.20+, a C++20 compiler, and desktop OpenGL (raylib is fetched automatically).

## Layout

- `core/`: simulation types/library
- `client/`: raylib + ImGui viewer
- `third_party/raygui`: raygui single-header UI

add_library(thinkfootball_core STATIC
    src/world_state.cpp
    src/pitch_zones.cpp
    src/movement.cpp
    src/ball_state.cpp
    src/brain.cpp
)

target_include_directories(thinkfootball_core
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(thinkfootball_core PUBLIC cxx_std_20)

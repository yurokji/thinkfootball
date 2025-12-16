add_executable(thinkfootball_client
    src/main.cpp
    src/raygui_impl.c
)

target_link_libraries(thinkfootball_client
    PRIVATE
        thinkfootball_core
        raylib
)

target_include_directories(thinkfootball_client
    PRIVATE
        ${CMAKE_SOURCE_DIR}/core/include
        ${CMAKE_SOURCE_DIR}/client/include
        ${CMAKE_SOURCE_DIR}/third_party/raygui
)

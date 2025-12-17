#include "thinkfootball/zone_behavior.h"

#include <algorithm>
#include <numeric>

namespace tf
{
std::array<float, 9> ZoneBehavior::Normalized() const
{
    std::array<float, 9> v{};
    for (size_t i = 0; i < 8; ++i) v[i] = dirWeight[i];
    v[8] = holdWeight;
    float sum = std::accumulate(v.begin(), v.end(), 0.0f);
    if (sum < 1e-6f) return v;
    for (auto& x : v) x /= sum;
    return v;
}

ZoneBehaviorTable BuildDefaultZoneBehaviors(bool attackPositiveX)
{
    ZoneBehaviorTable table{};
    for (int b = 0; b < static_cast<int>(Band::Count); ++b)
    {
        for (int l = 0; l < static_cast<int>(Lane::Count); ++l)
        {
            int idx = b * static_cast<int>(Lane::Count) + l;
            ZoneBehavior zb{};
            // Bias forward and slight central drift.
            float forward = 1.0f;
            float side = 0.4f;
            float hold = 0.2f;
            zb.dirWeight[attackPositiveX ? static_cast<int>(Direction8::E) : static_cast<int>(Direction8::W)] = forward;
            zb.dirWeight[static_cast<int>(Direction8::NE)] = side * (attackPositiveX ? 1.0f : 0.6f);
            zb.dirWeight[static_cast<int>(Direction8::SE)] = side * (attackPositiveX ? 1.0f : 0.6f);
            zb.dirWeight[static_cast<int>(Direction8::NW)] = side * (attackPositiveX ? 0.6f : 1.0f);
            zb.dirWeight[static_cast<int>(Direction8::SW)] = side * (attackPositiveX ? 0.6f : 1.0f);
            zb.holdWeight = hold;
            table.zones[idx] = zb;
        }
    }
    return table;
}

const ZoneBehavior* GetZoneBehaviorAtPos(const ZoneBehaviorTable& table, const PitchLayout& layout, const Vec3& pos)
{
    int idx = GetZoneAtPosition(layout, pos);
    if (idx < 0) return nullptr;
    return &table.zones[idx];
}

ZoneBehavior RoleDirectionBias(const std::string& role, bool attackPositiveX)
{
    ZoneBehavior zb{};
    auto setForward = [&](float fwd, float diag, float side, float back, float hold) {
        zb.dirWeight[(attackPositiveX ? static_cast<int>(Direction8::E) : static_cast<int>(Direction8::W))] = fwd;
        zb.dirWeight[static_cast<int>(Direction8::NE)] = diag;
        zb.dirWeight[static_cast<int>(Direction8::SE)] = diag;
        zb.dirWeight[static_cast<int>(Direction8::NW)] = diag * 0.6f;
        zb.dirWeight[static_cast<int>(Direction8::SW)] = diag * 0.6f;
        zb.dirWeight[static_cast<int>(Direction8::N)] = side;
        zb.dirWeight[static_cast<int>(Direction8::S)] = side;
        zb.dirWeight[(attackPositiveX ? static_cast<int>(Direction8::W) : static_cast<int>(Direction8::E))] = back;
        zb.holdWeight = hold;
    };
    if (role == "GK")
        setForward(0.1f, 0.05f, 0.1f, 0.15f, 0.5f);
    else if (role == "CDF")
        setForward(0.15f, 0.1f, 0.1f, 0.2f, 0.35f);
    else if (role == "LB" || role == "RB")
        setForward(0.25f, 0.2f, 0.2f, 0.1f, 0.25f);
    else if (role == "CDM")
        setForward(0.2f, 0.15f, 0.2f, 0.15f, 0.3f);
    else if (role == "CAM")
        setForward(0.3f, 0.25f, 0.15f, 0.05f, 0.25f);
    else if (role == "LM" || role == "RM")
        setForward(0.25f, 0.25f, 0.2f, 0.1f, 0.2f);
    else if (role == "LF" || role == "RF")
        setForward(0.35f, 0.25f, 0.15f, 0.05f, 0.2f);
    else
        setForward(0.2f, 0.15f, 0.2f, 0.1f, 0.25f);
    return zb;
}
}  // namespace tf

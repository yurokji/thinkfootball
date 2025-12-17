#include "thinkfootball/brain.h"
#include "thinkfootball/zone_behavior.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <random>
#include <unordered_map>
#include <vector>

namespace tf
{
namespace
{
constexpr float kPi = 3.1415926535f;

// fwd decl
inline float Length2D(float x, float z);
inline Vec3 RotateY(const Vec3& v, float ang);

struct VisionInfo
{
    float nearestOppDist{std::numeric_limits<float>::max()};
    Vec3 nearestOppVec{};
};

struct FacingDecision
{
    Vec3 dir{};
    float lockTime{0.0f};
};

// 스캔 방향/빈도 설정: 움직일 땐 몸 방향, 정지/저속일 땐 곁눈질 허용
static void UpdateScan(Player& p, float now)
{
    float speed = Length2D(p.state.velocity.x, p.state.velocity.z);
    Vec3 face{std::sin(p.state.facingRadians), 0.0f, std::cos(p.state.facingRadians)};
    bool moving = speed > 0.5f;
    // 기본 콘 각: 30~45도, 어웨어니스 높을수록 넓음
    float baseHalf = 30.0f * (kPi / 180.0f);
    float half = baseHalf * (0.8f + p.stats.awareness * 0.6f);
    if (!moving && speed < 0.1f)
    {
        // 정지 시 뒤쪽까지 약간 허용 (곁눈질)
        half = std::min(half + 0.4f, 1.6f);  // 최대 약 90도
    }
    if (moving)
    {
        p.state.scanDir = face;
        p.state.scanHalfAngle = half;
        p.state.nextScanTime = now + 0.6f;
        return;
    }
    if (now >= p.state.nextScanTime || Length2D(p.state.scanDir.x, p.state.scanDir.z) < 1e-4f)
    {
        std::uniform_real_distribution<float> uni(-half, half);
        float jitter = uni(p.rng);
        Vec3 s = RotateY(face, jitter);
        p.state.scanDir = s;
        p.state.scanHalfAngle = half;
        float period = std::clamp(0.8f - p.stats.awareness * 0.5f, 0.3f, 0.9f);
        p.state.nextScanTime = now + period;
    }
}

inline float Length2D(float x, float z)
{
    return std::sqrt(x * x + z * z);
}

inline float Hash01(uint32_t a, uint32_t b, uint32_t c)
{
    uint32_t x = a * 0x9E3779B1u ^ b * 0x7F4A7C15u ^ c * 0x94D049BBu;
    x ^= x >> 16;
    x *= 0x7FEB352Du;
    x ^= x >> 15;
    x *= 0x846CA68Bu;
    x ^= x >> 16;
    return (x & 0xFFFFFFu) / float(0x1000000u);  // [0,1)
}

inline Vec3 RotateY(const Vec3& v, float ang)
{
    float s = std::sin(ang);
    float c = std::cos(ang);
    return {v.x * c - v.z * s, 0.0f, v.x * s + v.z * c};
}

VisionInfo CollectVision(const Player& viewer, const WorldState& world, float rangeBase, float halfAngleRad)
{
    VisionInfo info{};
    float range = rangeBase * (0.6f + viewer.stats.awareness * 0.8f);
    float halfAng = halfAngleRad;  // keep stable to reduce visual jitter
    // 스캔 방향이 유효하면 그것을 사용, 없으면 facing 사용
    Vec3 scan = viewer.state.scanDir;
    if (Length2D(scan.x, scan.z) < 1e-4f)
    {
        scan = {std::sin(viewer.state.facingRadians), 0.0f, std::cos(viewer.state.facingRadians)};
    }
    float dirX = scan.x;
    float dirZ = scan.z;

    for (const auto& p : world.players)
    {
        if (p.id == viewer.id) continue;
        float dx = p.state.position.x - viewer.state.position.x;
        float dz = p.state.position.z - viewer.state.position.z;
        float dist2 = dx * dx + dz * dz;
        if (dist2 > range * range) continue;
        float dist = Length2D(dx, dz);
        if (dist < 1e-3f) continue;
        float dot = (dirX * dx + dirZ * dz) / dist;
        float ang = std::acos(std::clamp(dot, -1.0f, 1.0f));
        if (ang <= halfAng && p.teamIndex != viewer.teamIndex)
        {
            if (dist < info.nearestOppDist)
            {
                info.nearestOppDist = dist;
                info.nearestOppVec = {dx / dist, 0.0f, dz / dist};
            }
        }
    }
    return info;
}

struct DribbleHold
{
    float untilTime{-1.0f};
    Vec3 dir{};
};

static std::unordered_map<int, DribbleHold> g_dribbleHold;

struct DecisionCache
{
    float nextTime{-1.0f};
    Vec3 target{};
    RequestedAction action{RequestedAction::None};
};

inline Vec3 DirFromIndex(int idx)
{
    // idx: Direction8 enum order N, NE, E, SE, S, SW, W, NW
    switch (idx)
    {
    case 0: return {0.0f, 0.0f, 1.0f};
    case 1: return {0.7071f, 0.0f, 0.7071f};
    case 2: return {1.0f, 0.0f, 0.0f};
    case 3: return {0.7071f, 0.0f, -0.7071f};
    case 4: return {0.0f, 0.0f, -1.0f};
    case 5: return {-0.7071f, 0.0f, -0.7071f};
    case 6: return {-1.0f, 0.0f, 0.0f};
    case 7: return {-0.7071f, 0.0f, 0.7071f};
    default: return {0.0f, 0.0f, 0.0f};
    }
}

Vec3 BiasVectorFromBehavior(const ZoneBehavior& zb, bool attackPositiveX)
{
    // Sum weighted direction vectors (flip X if attacking negative).
    Vec3 acc{};
    for (int i = 0; i < 8; ++i)
    {
        Vec3 d = DirFromIndex(i);
        if (!attackPositiveX) d.x = -d.x;
        acc.x += d.x * zb.dirWeight[i];
        acc.z += d.z * zb.dirWeight[i];
    }
    float len = Length2D(acc.x, acc.z);
    if (len > 1e-4f)
    {
        acc.x /= len;
        acc.z /= len;
    }
    return acc;
}

Vec3 AnchorForRole(const Player& p, float pitchLen, float pitchWid)
{
    float midZ = pitchWid * 0.5f;
    auto mirrorX = [&](float x) { return pitchLen - x; };
    auto anchor = [&](float x, float z) {
        return (p.teamIndex == 0) ? Vec3{x, 0.0f, z} : Vec3{mirrorX(x), 0.0f, z};
    };
    if (p.role == "GK") return anchor(2.0f, midZ);
    if (p.role == "LB") return anchor(16.0f, pitchWid * 0.2f);
    if (p.role == "RB") return anchor(16.0f, pitchWid * 0.8f);
    if (p.role == "CDF")
    {
        bool leftSide = (p.id % 2 == 0);
        return anchor(12.0f, pitchWid * (leftSide ? 0.35f : 0.65f));
    }
    if (p.role == "CDM") return anchor(28.0f, pitchWid * 0.5f);
    if (p.role == "LM") return anchor(32.0f, pitchWid * 0.2f);
    if (p.role == "RM") return anchor(32.0f, pitchWid * 0.8f);
    if (p.role == "CAM") return anchor(44.0f, pitchWid * 0.5f);
    if (p.role == "LF") return anchor(60.0f, pitchWid * 0.42f);
    if (p.role == "RF") return anchor(60.0f, pitchWid * 0.58f);
    // 기본: 중앙 미드 위치
    return anchor(40.0f, midZ);
}

// 패스 가능성: 거리 4~35m, 라인 안전, 패스 레인 여유(최소 간격).
bool IsPassFeasible(const Player& passer, const Vec3& target, const WorldState& world, float pitchWidth, float pitchLength)
{
    float dx = target.x - passer.state.position.x;
    float dz = target.z - passer.state.position.z;
    float dist2 = dx * dx + dz * dz;
    if (dist2 < 4.0f * 4.0f || dist2 > 35.0f * 35.0f) return false;

    // 라인 안쪽 최소 마진
    const float margin = 1.0f;
    if (target.x < -margin || target.x > pitchLength + margin) return false;
    if (target.z < -margin || target.z > pitchWidth + margin) return false;

    // 레인 간섭: 패스 선분에서 상대까지의 최소 거리
    float minGap = 99.f;
    for (const auto& opp : world.players)
    {
        if (opp.teamIndex == passer.teamIndex) continue;
        float ox = opp.state.position.x - passer.state.position.x;
        float oz = opp.state.position.z - passer.state.position.z;
        float proj = (ox * dx + oz * dz) / std::max(dist2, 1e-3f);
        proj = std::clamp(proj, 0.0f, 1.0f);
        float cx = passer.state.position.x + dx * proj;
        float cz = passer.state.position.z + dz * proj;
        float gx = opp.state.position.x - cx;
        float gz = opp.state.position.z - cz;
        float gap = std::sqrt(gx * gx + gz * gz);
        minGap = std::min(minGap, gap);
    }
    if (minGap < 2.5f) return false;
    return true;
}

// 드리블 위험도: 통로 폭 협소, 터치라인 인접, 압박 근접.
bool IsDribbleRisky(const Player& player, const WorldState& world, float pitchWidth)
{
    const float lookAhead = 8.0f;
    const float narrow = 3.0f;
    int closeCount = 0;
    for (const auto& opp : world.players)
    {
        if (opp.teamIndex == player.teamIndex) continue;
        float dx = opp.state.position.x - player.state.position.x;
        float dz = opp.state.position.z - player.state.position.z;
        // 투영: 현재 페이싱 방향 기준
        float fx = std::sin(player.state.facingRadians);
        float fz = std::cos(player.state.facingRadians);
        float proj = dx * fx + dz * fz;
        if (proj <= 0.0f || proj > lookAhead) continue;
        float lateral = std::abs(dx * fz - dz * fx);
        if (lateral < narrow)
        {
            closeCount++;
        }
    }
    bool corridorRisk = (closeCount >= 2);

    // 터치라인 근접
    bool lineRisk = (player.state.position.z < 2.0f) || (player.state.position.z > pitchWidth - 2.0f);
    return corridorRisk || lineRisk;
}
}  // namespace

void TeamBrain::ThinkTeam(WorldState& /*world*/, float /*dtSeconds*/)
{
    // Placeholder: team-level tactics updates can be added here.
}

// 가장 가까운 상대를 찾되 시야와 무관하게 위치 기반으로 계산.
static void NearestOpponent(const Player& self, const WorldState& world, Vec3& outDir, float& outDist)
{
    outDist = std::numeric_limits<float>::max();
    outDir = {0, 0, 0};
    for (const auto& opp : world.players)
    {
        if (opp.teamIndex == self.teamIndex) continue;
        float dx = opp.state.position.x - self.state.position.x;
        float dz = opp.state.position.z - self.state.position.z;
        float d2 = dx * dx + dz * dz;
        if (d2 < outDist * outDist)
        {
            float d = std::sqrt(std::max(d2, 1e-6f));
            outDist = d;
            outDir = {dx / d, 0.0f, dz / d};
        }
    }
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
    // If teammate controls the ball, hold a support distance instead of crowding.
    if (world.ball.mode == BallMode::Controlled && world.ball.ownerPlayerId != player.id)
    {
        const Player* owner = nullptr;
        for (const auto& p : world.players)
        {
            if (p.id == world.ball.ownerPlayerId)
            {
                owner = &p;
                break;
            }
        }
        if (owner && owner->teamIndex == player.teamIndex)
        {
                Vec3 toGoal{(teamIndex == 0 ? ctx.pitchWidth : 0.0f) - owner->state.position.x, 0.0f, ctx.pitchHeight * 0.5f - owner->state.position.z};
                float len = Length2D(toGoal.x, toGoal.z);
                Vec3 fwd = (len > 1e-3f) ? Vec3{toGoal.x / len, 0.0f, toGoal.z / len} : Vec3{(teamIndex == 0) ? 1.0f : -1.0f, 0.0f, 0.0f};
                Vec3 perp{-fwd.z, 0.0f, fwd.x};
                float sideSign = (Hash01(static_cast<uint32_t>(player.id), static_cast<uint32_t>(world.ball.touchSeq), 77) < 0.5f) ? 1.0f : -1.0f;
                float lateral = 6.0f * sideSign; // spread sideways
                target.x = owner->state.position.x - fwd.x * 4.0f + perp.x * lateral;
                target.z = owner->state.position.z - fwd.z * 4.0f + perp.z * lateral;
                player.intent.desiredSpeed01 = 0.35f;
        }
        else
        {
            const float buffer = 4.0f;  // meters
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
                player.intent.desiredSpeed01 = 0.05f;
            }
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
    const bool isGK = (player.role == "GK");
    const auto& tactics = world.teams[teamIndex].tactics;
    const auto& tctx = ctx.team[teamIndex];
    float breath = std::clamp(player.condition.breath, 0.0f, 1.0f);
    const float now = world.clock.timeSeconds;

    const bool ownsBall = (world.ball.mode == BallMode::Controlled && world.ball.ownerPlayerId == player.id);

    Vec3 target = ctx.ballPos;
    // Attack direction: team 0 -> +x (opponent goal at length), team 1 -> -x (goal at 0).
    Vec3 goalPos{(teamIndex == 0) ? ctx.pitchWidth : 0.0f, 0.0f, ctx.pitchHeight * 0.5f};
    RequestedAction action = RequestedAction::None;
    float speed01 = std::clamp(tctx.speedScale * tctx.pressScale, 0.0f, 1.0f);
    UpdateScan(player, now);
    VisionInfo vision = CollectVision(player, world, 20.0f, player.state.scanHalfAngle);
    float nearestAllyDist = std::numeric_limits<float>::max();
    Vec3 nearestAllyVec{};
    Vec3 nearestAllyPos{};
    for (const auto& other : world.players)
    {
        if (other.id == player.id || other.teamIndex != teamIndex) continue;
        float dx = other.state.position.x - player.state.position.x;
        float dz = other.state.position.z - player.state.position.z;
        float d2 = dx * dx + dz * dz;
        if (d2 < nearestAllyDist * nearestAllyDist)
        {
            nearestAllyDist = std::sqrt(d2);
            nearestAllyVec = {dx, 0.0f, dz};
            nearestAllyPos = other.state.position;
        }
    }
    if (ownsBall)
    {
        // Use cached decision to reduce jitter.
        if (now < player.state.nextDecisionTime && player.state.cachedAction != RequestedAction::None)
        {
            target = player.state.cachedTarget;
            action = player.state.cachedAction;
            speed01 = 0.4f;
        }

        // Default dribble direction toward goal, then pick a safer variant.
        Vec3 toGoal{goalPos.x - player.state.position.x, 0.0f, goalPos.z - player.state.position.z};
        float glen = Length2D(toGoal.x, toGoal.z);
        Vec3 fwdDir = (glen > 1e-3f) ? Vec3{toGoal.x / glen, 0.0f, toGoal.z / glen} : Vec3{(teamIndex == 0) ? 1.0f : -1.0f, 0.0f, 0.0f};

        // Clamp within pitch bounds.
        target.x = std::clamp(target.x, 0.0f, ctx.pitchWidth);
        target.z = std::clamp(target.z, 0.0f, ctx.pitchHeight);

        speed01 = 0.9f * (0.7f + 0.3f * breath);  // winded -> slower default dribble

        // Slow when threat is close in vision.
        if (vision.nearestOppDist < 7.0f)
        {
            speed01 *= 0.45f;  // slow down more near threat
        }

        // If we recently chose a dribble direction, reuse it for a short hold to prevent oscillation.
        float lineMargin = 5.0f;
        auto itHold = g_dribbleHold.find(player.id);
        if (itHold != g_dribbleHold.end() && now < itHold->second.untilTime)
        {
            Vec3 nd = itHold->second.dir;
            target = {player.state.position.x + nd.x * 8.0f, 0.0f, player.state.position.z + nd.z * 8.0f};
            target.z = std::clamp(target.z, lineMargin, ctx.pitchHeight - lineMargin);
            // Spread away from nearest ally to keep lanes open.
            if (nearestAllyDist < 8.0f && nearestAllyDist > 1e-3f)
            {
                Vec3 perp{-nd.z, 0.0f, nd.x};
                float side = nearestAllyVec.x * perp.x + nearestAllyVec.z * perp.z;
                float sign = (side > 0.0f) ? -1.0f : 1.0f;
                float push = (8.0f - nearestAllyDist) / 8.0f * 3.0f;
                target.x += perp.x * sign * push;
                target.z += perp.z * sign * push;
            }
        }
        else
        {
            // Choose safer dribble direction among a few candidates with minimal turn.
            float baseAng = 0.6f;  // ~34deg
            float maxAng = 1.0f;   // ~57deg
            std::vector<Vec3> dirs = {
                fwdDir,
                RotateY(fwdDir, baseAng),
                RotateY(fwdDir, -baseAng),
                RotateY(fwdDir, maxAng),
                RotateY(fwdDir, -maxAng)};

            float bestScore = -1e9f;
            Vec3 bestDir = fwdDir;
            // Role directional bias
            ZoneBehavior roleBias = RoleDirectionBias(player.role, teamIndex == 0);
            Vec3 biasDir = BiasVectorFromBehavior(roleBias, teamIndex == 0);

            for (const auto& d : dirs)
            {
                float normLen = Length2D(d.x, d.z);
                if (normLen < 1e-4f) continue;
                Vec3 nd{d.x / normLen, 0.0f, d.z / normLen};
                float angle = std::acos(std::clamp(nd.x * fwdDir.x + nd.z * fwdDir.z, -1.0f, 1.0f));
                float anglePenalty = angle * (0.5f + (1.0f - player.stats.control) * 0.3f);  // even more willing to turn

                float threatPenalty = 0.0f;
                if (vision.nearestOppDist < 14.0f)
                {
                    threatPenalty += (14.0f - vision.nearestOppDist) * 4.0f;
                    // Penalize moving toward threat direction.
                    float toward = nd.x * vision.nearestOppVec.x + nd.z * vision.nearestOppVec.z;
                    if (toward > 0.0f)
                    {
                        threatPenalty += toward * 12.0f;
                    }
                }

                // Corridor (narrow gap) penalty: if two or more opponents are close to the path within 8m ahead
                // and lateral clearance < 1m, heavily penalize to force turning away.
                float corridorPenalty = 0.0f;
                int closeCount = 0;
                for (const auto& opp : world.players)
                {
                    if (opp.teamIndex == teamIndex) continue;
                    float dx = opp.state.position.x - player.state.position.x;
                    float dz = opp.state.position.z - player.state.position.z;
                    float proj = dx * nd.x + dz * nd.z;
                    if (proj <= 0.0f || proj > 8.0f) continue;  // only look ahead up to 8m
                    float lateral = std::abs(dx * nd.z - dz * nd.x);
                    if (lateral < 3.0f)
                    {
                        closeCount++;
                        corridorPenalty += (3.0f - lateral) * 10.0f;
                    }
                }
                if (closeCount >= 2)
                {
                    corridorPenalty *= 2.f;  // tighten if multiple obstacles form a narrow channel
                }

                // Touchline safety: penalize directions that drive ball outside margin.
                float futureZ = player.state.position.z + nd.z * 8.0f;
                float linePenalty = 0.0f;
                if (futureZ < lineMargin)
                    linePenalty += (lineMargin - futureZ) * 3.0f;
                else if (futureZ > ctx.pitchHeight - lineMargin)
                    linePenalty += (futureZ - (ctx.pitchHeight - lineMargin)) * 3.0f;

                float roleBiasScore = nd.x * biasDir.x + nd.z * biasDir.z;
                float score = (nd.x * fwdDir.x + nd.z * fwdDir.z) * 1.5f + roleBiasScore * 1.2f - anglePenalty - threatPenalty - corridorPenalty - linePenalty;
                score -= (1.0f - breath) * 6.0f;  // low breath hurts dribble confidence
                if (score > bestScore)
                {
                    bestScore = score;
                    bestDir = nd;
                }
            }
            target = {player.state.position.x + bestDir.x * 8.0f, 0.0f, player.state.position.z + bestDir.z * 8.0f};
            // Clamp target inside touchlines margin.
            target.z = std::clamp(target.z, lineMargin, ctx.pitchHeight - lineMargin);
            // Spread away from nearest ally to keep lanes open.
            if (nearestAllyDist < 8.0f && nearestAllyDist > 1e-3f)
            {
                Vec3 perp{-bestDir.z, 0.0f, bestDir.x};
                float side = nearestAllyVec.x * perp.x + nearestAllyVec.z * perp.z;
                float sign = (side > 0.0f) ? -1.0f : 1.0f;
                float push = (8.0f - nearestAllyDist) / 8.0f * 3.0f;
                target.x += perp.x * sign * push;
                target.z += perp.z * sign * push;
            }
            g_dribbleHold[player.id] = DribbleHold{now + 0.25f, bestDir};
        }

        // Shoot if close enough to goal (GK는 제외).
        float toGoalX = goalPos.x - player.state.position.x;
        float toGoalZ = goalPos.z - player.state.position.z;
        float goalDist2 = toGoalX * toGoalX + toGoalZ * toGoalZ;
        bool facingOpponentGoal = (teamIndex == 0) ? (toGoalX > 0.0f) : (toGoalX < 0.0f);
        if (!isGK && facingOpponentGoal && goalDist2 < 20.0f * 20.0f)
        {
            action = RequestedAction::Shoot;
            target = goalPos;
            speed01 = 0.2f;  // preparing shot
        }

        // Look for a simple pass to a teammate reasonably close; prefer forward, but allow fallback lateral/back.
        int bestForwardId = -1;
        float bestForwardScore = -1.0f;
        Vec3 bestForwardPos{};
        int bestAnyId = -1;
        float bestAnyScore = -1.0f;
        Vec3 bestAnyPos{};
        int lastPasser = world.ball.prevTouch.playerId;
        for (const auto& mate : world.players)
        {
            if (mate.teamIndex != teamIndex || mate.id == player.id) continue;
            float dx = mate.state.position.x - player.state.position.x;
            float dz = mate.state.position.z - player.state.position.z;
            float dist2 = dx * dx + dz * dz;
            if (dist2 < 3.0f * 3.0f) continue;            // avoid ultra short passes
            if (dist2 > 35.0f * 35.0f) continue;          // keep passes reasonable
            float dist = std::sqrt(dist2);

            float forward = (teamIndex == 0) ? dx : -dx;

            // Require mate to be within vision cone (looser) and slightly longer range.
            float dirX = std::sin(player.state.facingRadians);
            float dirZ = std::cos(player.state.facingRadians);
            float dot = (dirX * dx + dirZ * dz) / std::max(dist, 1e-3f);
            float ang = std::acos(std::clamp(dot, -1.0f, 1.0f));
            float halfAng = 80.0f * (kPi / 180.0f);  // wide, stable cone for passing
            float visRange = 30.0f * (0.6f + player.stats.awareness * 0.8f);
            if (ang > halfAng || dist > visRange) continue;

            float laneCenter = ctx.pitchHeight * 0.5f;
            float widthPenalty = std::abs(mate.state.position.z - laneCenter) / (ctx.pitchHeight * 0.5f);
            // Penalize short passes and lanes crowded by opponents.
            float score = (50.0f - dist) * 0.8f + forward * 0.6f - widthPenalty * 0.05f;
            if (forward <= 0.0f) score *= 0.9f;  // mild penalty for back passes, still allowed
            if (mate.id == lastPasser) score -= 3.0f;    // small discouragement only
            if (dist < 8.0f) score -= (8.0f - dist) * 0.2f; // allow short outlet more
            // Opponent clearance along pass lane
            float minGap = 99.f;
            for (const auto& opp : world.players)
            {
                if (opp.teamIndex == teamIndex) continue;
                float ox = opp.state.position.x - player.state.position.x;
                float oz = opp.state.position.z - player.state.position.z;
                float proj = (ox * dx + oz * dz) / std::max(dist2, 1e-3f);
                proj = std::clamp(proj, 0.0f, 1.0f);
                float cx = player.state.position.x + dx * proj;
                float cz = player.state.position.z + dz * proj;
                float gx = opp.state.position.x - cx;
                float gz = opp.state.position.z - cz;
                float gap = std::sqrt(gx * gx + gz * gz);
                minGap = std::min(minGap, gap);
            }
            if (minGap < 4.0f) score -= (4.0f - minGap) * 1.2f; // less strict so passes still chosen

            // Winded players want to offload.
            score += (1.0f - breath) * 18.0f;

            // Role-specific tendencies (natural style)
            bool isCB = (player.role == "CDF");
            bool isFB = (player.role == "LB" || player.role == "RB");
            bool isWM = (player.role == "LM" || player.role == "RM");
            bool isFW = (player.role == "LF" || player.role == "RF");
            bool isAM = (player.role == "CAM");
            if (isCB && dist > 15.0f)
            {
                score += 5.0f;  // CB 롱패스 선호
                if (dist > 22.0f) score += 3.0f;
            }
            if ((isFB || isWM) && forward > 0.0f && dist > 10.0f)
            {
                score += 4.0f;  // 측면 전진 패스/크로스 성향
            }
            bool fwRelax = (vision.nearestOppDist > 9.0f);
            if (isFW && fwRelax)
            {
                score *= 0.7f;  // 포워드는 드리블/슛 우선, 패스 점수 하향
            }
            if (isAM)
            {
                score += 3.0f;  // AM은 패스 성향 강화
            }

            if (forward > 0.3f && score > bestForwardScore)
            {
                bestForwardScore = score;
                bestForwardId = mate.id;
                bestForwardPos = mate.state.position;
            }
            if (score > bestAnyScore)
            {
                bestAnyScore = score;
                bestAnyId = mate.id;
                bestAnyPos = mate.state.position;
            }
        }

        // Prefer a forward option if available; otherwise fallback to best overall in vision.
        // 압박/위험 정도를 세분화해 패스 성향을 높인다.
        int oppClose = 0;
        for (const auto& opp : world.players)
        {
            if (opp.teamIndex == teamIndex) continue;
            float dx = opp.state.position.x - player.state.position.x;
            float dz = opp.state.position.z - player.state.position.z;
            if (dx * dx + dz * dz < 10.0f * 10.0f) oppClose++;
        }

        bool underPressure = (vision.nearestOppDist < 9.0f || oppClose >= 2);
        float randPass = Hash01(static_cast<uint32_t>(player.id), static_cast<uint32_t>(world.ball.touchSeq), 333);

        // Require minimally viable scores before passing to avoid punting into nowhere.
        float minScore = underPressure ? -1.0f : -0.5f;
        bool canForward = (bestForwardId >= 0 && bestForwardScore > minScore);
        bool canAny = (bestAnyId >= 0 && bestAnyScore > minScore);

        float chanceForward = underPressure ? 0.97f : 0.75f;
        float chanceAny = underPressure ? 0.95f : 0.7f;

        // 강제 패스 모드: 드리블 리스크 높거나 호흡 낮거나 압박 많으면 우선 패스.
        bool forcePass = underPressure || breath < 0.55f || IsDribbleRisky(player, world, ctx.pitchHeight);

        bool passChosen = false;
        if (canForward && action != RequestedAction::Shoot && (forcePass || randPass < chanceForward))
        {
            action = RequestedAction::Pass;
            target = bestForwardPos;
            speed01 = 0.35f;  // prep pass
            passChosen = true;
        }
        else if (canAny && action != RequestedAction::Shoot && (forcePass || randPass < chanceAny))
        {
            action = RequestedAction::Pass;
            target = bestAnyPos;
            speed01 = 0.35f;
            passChosen = true;
        }

        // Feasibility/risk override
        bool passOk = passChosen && IsPassFeasible(player, target, world, ctx.pitchHeight, ctx.pitchWidth);
        bool dribbleRisk = IsDribbleRisky(player, world, ctx.pitchHeight);
        if (passOk && dribbleRisk)
        {
            action = RequestedAction::Pass;
            speed01 = 0.35f;
        }
        else if (!passOk && dribbleRisk)
        {
            // 위험한 드리블: 잠시 홀드/턴
            action = RequestedAction::None;
            target = player.state.position;
            speed01 = 0.1f;
        }
        // 패스가 선택되지 않았지만 압박이 심하면 가장 가까운 안전 아군에게라도 짧게 준다.
        if (!passChosen && underPressure && bestAnyId >= 0)
        {
            action = RequestedAction::Pass;
            target = bestAnyPos;
            speed01 = 0.35f;
            passChosen = true;
        }

        // Cache decision to reduce jitter for a short window.
        player.state.cachedAction = action;
        player.state.cachedTarget = target;
        player.state.nextDecisionTime = now + 0.3f;
    }
    else
    {
        // Not owning ball: clear cached action.
        player.state.cachedAction = RequestedAction::None;
        player.state.nextDecisionTime = now;
        // Off-ball: defend or support spacing.
        if (world.ball.mode == BallMode::Controlled)
        {
            const Player* owner = nullptr;
            for (const auto& p : world.players)
            {
                if (p.id == world.ball.ownerPlayerId)
                {
                    owner = &p;
                    break;
                }
            }
            if (owner && owner->teamIndex == teamIndex && owner->id != player.id)
            {
                // Support spacing: stay 10–18m away, lateral offset to open lanes.
            Vec3 toGoal{(teamIndex == 0 ? ctx.pitchWidth : 0.0f) - owner->state.position.x, 0.0f, ctx.pitchHeight * 0.5f - owner->state.position.z};
            float len = Length2D(toGoal.x, toGoal.z);
            Vec3 fwd = (len > 1e-3f) ? Vec3{toGoal.x / len, 0.0f, toGoal.z / len} : Vec3{(teamIndex == 0) ? 1.0f : -1.0f, 0.0f, 0.0f};
            Vec3 perp{-fwd.z, 0.0f, fwd.x};
            float sideSign = (player.id % 2 == 0) ? 1.0f : -1.0f;
            float distBack = 6.0f;
            float supportDist = 12.0f + (player.id % 3) * 2.0f;  // 12–16m
            target.x = owner->state.position.x - fwd.x * distBack + perp.x * (sideSign * supportDist * 0.5f);
            target.z = owner->state.position.z - fwd.z * distBack + perp.z * (sideSign * supportDist * 0.5f);
            speed01 = 0.35f;
            }
            else
            {
                // Defending: keep a buffer when someone else owns the ball.
                const float buffer = 4.0f;
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
                    speed01 = 0.05f;  // back off instead of stacking
                }
            }
        }

        const float pressBand = ctx.pitchHeight * (0.05f + tactics.pressIntensity * 0.1f);
        if (teamIndex == 0)
        {
            target.x = std::min(target.x, tctx.lineZ + pressBand);
        }
        else
        {
            target.x = std::max(target.x, tctx.lineZ - pressBand);
        }

        const float centerZ = ctx.pitchHeight * 0.5f;
        const float minZ = centerZ - tctx.halfWidth;
        const float maxZ = centerZ + tctx.halfWidth;
        target.z = std::clamp(target.z, minZ, maxZ);

        // 앵커/로밍 범위 블렌드로 뭉침 방지.
        Vec3 anchor = AnchorForRole(player, ctx.pitchWidth, ctx.pitchHeight);
        const float roamRadius = 10.0f;
        target.x = 0.5f * target.x + 0.5f * anchor.x;
        target.z = 0.5f * target.z + 0.5f * anchor.z;
        Vec3 diff{target.x - anchor.x, 0.0f, target.z - anchor.z};
        float dlen = Length2D(diff.x, diff.z);
        if (dlen > roamRadius && dlen > 1e-3f)
        {
            diff.x *= (roamRadius / dlen);
            diff.z *= (roamRadius / dlen);
            target.x = anchor.x + diff.x;
            target.z = anchor.z + diff.z;
        }
    }

    // ---- Facing selection: 정보 획득 + 실행 방향을 분리, 짧은 lock으로 떨림 완화 ----
    FacingDecision fd{};
    // 우선 기존 lock 유지
    // now already computed above
    Vec3 locked = player.state.cachedFaceDir;
    if (now < player.state.faceLockUntil && (locked.x * locked.x + locked.z * locked.z) > 1e-4f)
    {
        fd.dir = locked;
    }
    else
    {
        Vec3 toBall{world.ball.pos.x - player.state.position.x, 0.0f, world.ball.pos.z - player.state.position.z};
        float ballLen = Length2D(toBall.x, toBall.z);
        Vec3 ballDir = (ballLen > 1e-4f) ? Vec3{toBall.x / ballLen, 0.0f, toBall.z / ballLen} : Vec3{0, 0, 0};

        Vec3 oppDir;
        float oppDist;
        NearestOpponent(player, world, oppDir, oppDist);

        Vec3 desiredFace{0, 0, 0};
        // 온볼: 선택 행동 타깃을 우선 본다.
        if (action == RequestedAction::Pass || action == RequestedAction::Shoot)
        {
            Vec3 faceVec{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
            float len = Length2D(faceVec.x, faceVec.z);
            if (len > 1e-4f) desiredFace = {faceVec.x / len, 0.0f, faceVec.z / len};
        }
        if ((desiredFace.x * desiredFace.x + desiredFace.z * desiredFace.z) < 1e-5f && ballLen > 1e-4f)
        {
            desiredFace = ballDir;
        }
        // 오프볼이거나 위에서 못 정했다면, 최근 위협/볼을 본다.
        if ((desiredFace.x * desiredFace.x + desiredFace.z * desiredFace.z) < 1e-5f && oppDist < 15.0f)
        {
            desiredFace = oppDir;
        }
        // 그래도 없으면 진행/앵커 방향을 천천히 본다.
        if ((desiredFace.x * desiredFace.x + desiredFace.z * desiredFace.z) < 1e-5f)
        {
            Vec3 toTarget{target.x - player.state.position.x, 0.0f, target.z - player.state.position.z};
            float len = Length2D(toTarget.x, toTarget.z);
            if (len > 1e-4f) desiredFace = {toTarget.x / len, 0.0f, toTarget.z / len};
        }
        float lock = std::clamp(0.6f - player.stats.awareness * 0.3f, 0.25f, 0.7f);  // 시야 좋을수록 더 자주 스캔
        // 압박 많으면 더 짧게 스캔
        if (oppDist < 8.0f) lock *= 0.7f;
        fd.dir = desiredFace;
        fd.lockTime = now + lock;
        player.state.cachedFaceDir = fd.dir;
        player.state.faceLockUntil = fd.lockTime;
    }

    player.intent.targetPos = target;
    player.intent.desiredSpeed01 = speed01;
    player.intent.action = action;
    player.intent.faceDir = fd.dir;
}

void TickPlayerWithBrain(Player& player,
                         const WorldState& world,
                         const GroupContext& ctx,
                         MovementBase& movement,
                         PlayerBrain& brain,
                         float dtSeconds)
{
    // Rate-limit decisions with per-player offset and urgency by ball proximity.
    float now = world.clock.timeSeconds;
    float ballDx = world.ball.pos.x - player.state.position.x;
    float ballDz = world.ball.pos.z - player.state.position.z;
    float ballDist = std::sqrt(ballDx * ballDx + ballDz * ballDz);
    float urgency = (ballDist < 8.0f) ? 0.12f : (ballDist < 15.0f ? 0.18f : 0.25f);
    float offset = (player.id % 5) * 0.02f;  // spread decision ticks
    if (now >= player.state.nextDecisionTime)
    {
        brain.Think(player, world, ctx, dtSeconds);
        player.state.nextDecisionTime = now + urgency + offset;
    }
    // Movement consumes the last intent (updated or reused).
    movement.Tick(player, world, dtSeconds);
}
}  // namespace tf

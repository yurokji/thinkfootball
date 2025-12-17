#include "thinkfootball/serialize.h"

#include <nlohmann/json.hpp>

namespace tf
{
using nlohmann::json;

static void to_json(json& j, const Vec3& v)
{
    j = json{{"x", v.x}, {"y", v.y}, {"z", v.z}};
}

static void from_json(const json& j, Vec3& v)
{
    v.x = j.value("x", 0.0f);
    v.y = j.value("y", 0.0f);
    v.z = j.value("z", 0.0f);
}

static void to_json(json& j, const BallContact& c)
{
    j = json{{"playerId", c.playerId}, {"teamId", c.teamId}, {"tick", c.tick}};
}

static void from_json(const json& j, BallContact& c)
{
    c.playerId = j.value("playerId", -1);
    c.teamId = j.value("teamId", -1);
    c.tick = j.value("tick", 0);
}

std::string ToJson(const WorldState& world)
{
    json j;
    j["clock"] = {{"timeSeconds", world.clock.timeSeconds}, {"deltaSeconds", world.clock.deltaSeconds}};
    j["ball"] = {{"pos", world.ball.pos},
                 {"vel", world.ball.vel},
                 {"mode", static_cast<int>(world.ball.mode)},
                 {"height", world.ball.height},
                 {"heightVel", world.ball.heightVel},
                 {"ownerPlayerId", world.ball.ownerPlayerId},
                 {"claimPlayerId", world.ball.claimPlayerId},
                 {"lastTouch", world.ball.lastTouch},
                 {"prevTouch", world.ball.prevTouch},
                 {"touchSeq", world.ball.touchSeq},
                 {"flight",
                  {{"active", world.ball.flight.active},
                   {"startTick", world.ball.flight.startTick},
                   {"endTick", world.ball.flight.endTick},
                   {"startPos", world.ball.flight.startPos},
                   {"endPos", world.ball.flight.endPos},
                   {"apexHeight", world.ball.flight.apexHeight},
                   {"spin", world.ball.flight.spin}}}};

    json teams = json::array();
    for (const auto& t : world.teams)
    {
        teams.push_back({{"name", t.name},
                         {"tactics",
                          {{"defensiveLineHeight", t.tactics.defensiveLineHeight},
                           {"pressIntensity", t.tactics.pressIntensity},
                           {"width", t.tactics.width},
                           {"directness", t.tactics.directness},
                           {"tempo", t.tactics.tempo}}},
                         {"formation", t.formation},
                         {"style", t.style}});
    }
    j["teams"] = teams;

    json players = json::array();
    for (const auto& p : world.players)
    {
        players.push_back({{"id", p.id},
                           {"name", p.name},
                           {"role", p.role},
                           {"teamIndex", p.teamIndex},
                           {"stats",
                           {{"speed", p.stats.speed},
                            {"accel", p.stats.accel},
                            {"control", p.stats.control},
                            {"passGround", p.stats.passGround},
                            {"passLong", p.stats.passLong},
                            {"shoot", p.stats.shoot},
                            {"defend", p.stats.defend},
                            {"awareness", p.stats.awareness},
                            {"composure", p.stats.composure},
                             {"endurance", p.stats.endurance},
                             {"aggression", p.stats.aggression},
                             {"passPref", p.stats.passPref},
                             {"shootPref", p.stats.shootPref},
                             {"dribblePref", p.stats.dribblePref},
                             {"holdPref", p.stats.holdPref}}},
                          {"condition",
                           {{"fatigue", p.condition.fatigue},
                            {"pressure01", p.condition.pressure01},
                            {"breath", p.condition.breath}}},
                           {"intent",
                            {{"targetPos", p.intent.targetPos},
                             {"desiredSpeed01", p.intent.desiredSpeed01},
                             {"faceDir", p.intent.faceDir},
                             {"action", static_cast<int>(p.intent.action)}}},
                           {"state",
                           {{"position", p.state.position},
                            {"velocity", p.state.velocity},
                            {"facingRadians", p.state.facingRadians},
                            {"hasBall", p.state.hasBall},
                            {"nextDecisionTime", p.state.nextDecisionTime},
                            {"cachedTarget", p.state.cachedTarget},
                            {"cachedAction", static_cast<int>(p.state.cachedAction)},
                            {"cachedFaceDir", p.state.cachedFaceDir},
                            {"faceLockUntil", p.state.faceLockUntil},
                            {"scanDir", p.state.scanDir},
                            {"scanHalfAngle", p.state.scanHalfAngle},
                            {"nextScanTime", p.state.nextScanTime}}}});
    }
    j["players"] = players;
    j["rngSeed"] = world.rngSeed;
    return j.dump();
}

WorldState FromJson(const std::string& jsonStr)
{
    WorldState world;
    auto j = json::parse(jsonStr);
    world.clock.timeSeconds = j["clock"].value("timeSeconds", 0.0f);
    world.clock.deltaSeconds = j["clock"].value("deltaSeconds", 0.0f);

    const auto& jb = j["ball"];
    world.ball.pos = jb["pos"].get<Vec3>();
    world.ball.vel = jb["vel"].get<Vec3>();
    world.ball.mode = static_cast<BallMode>(jb.value("mode", 0));
    world.ball.height = jb.value("height", 0.0f);
    world.ball.heightVel = jb.value("heightVel", 0.0f);
    world.ball.ownerPlayerId = jb.value("ownerPlayerId", -1);
    world.ball.claimPlayerId = jb.value("claimPlayerId", -1);
    world.ball.lastTouch = jb.value("lastTouch", BallContact{});
    world.ball.prevTouch = jb.value("prevTouch", BallContact{});
    world.ball.touchSeq = jb.value("touchSeq", 0U);

    if (jb.contains("flight"))
    {
        const auto& jf = jb["flight"];
        world.ball.flight.active = jf.value("active", false);
        world.ball.flight.startTick = jf.value("startTick", 0);
        world.ball.flight.endTick = jf.value("endTick", 0);
        world.ball.flight.startPos = jf.value("startPos", Vec3{});
        world.ball.flight.endPos = jf.value("endPos", Vec3{});
        world.ball.flight.apexHeight = jf.value("apexHeight", 0.0f);
        world.ball.flight.spin = jf.value("spin", 0.0f);
    }

    auto teams = j["teams"];
    for (size_t i = 0; i < world.teams.size() && i < teams.size(); ++i)
    {
        world.teams[i].name = teams[i].value("name", "");
        auto t = teams[i]["tactics"];
        world.teams[i].tactics.defensiveLineHeight = t.value("defensiveLineHeight", 0.5f);
        world.teams[i].tactics.pressIntensity = t.value("pressIntensity", 0.5f);
        world.teams[i].tactics.width = t.value("width", 0.5f);
        world.teams[i].tactics.directness = t.value("directness", 0.5f);
        world.teams[i].tactics.tempo = t.value("tempo", 0.5f);
        world.teams[i].formation = teams[i].value("formation", std::string("4-4-2"));
        world.teams[i].style = teams[i].value("style", std::string("neutral"));
    }

    world.players.clear();
    for (const auto& jp : j["players"])
    {
        Player p;
        p.id = jp.value("id", 0);
        p.name = jp.value("name", "");
        p.role = jp.value("role", "");
        p.teamIndex = jp.value("teamIndex", 0);
        auto s = jp["stats"];
        p.stats.speed = s.value("speed", 0.5f);
        p.stats.accel = s.value("accel", 0.5f);
        p.stats.control = s.value("control", 0.5f);
        p.stats.passGround = s.value("passGround", 0.5f);
        p.stats.passLong = s.value("passLong", 0.5f);
        p.stats.shoot = s.value("shoot", 0.5f);
        p.stats.defend = s.value("defend", 0.5f);
        p.stats.awareness = s.value("awareness", 0.5f);
        p.stats.composure = s.value("composure", 0.5f);
        p.stats.endurance = s.value("endurance", 0.5f);
        p.stats.aggression = s.value("aggression", 0.5f);
        p.stats.passPref = s.value("passPref", 0.5f);
        p.stats.shootPref = s.value("shootPref", 0.5f);
        p.stats.dribblePref = s.value("dribblePref", 0.5f);
        p.stats.holdPref = s.value("holdPref", 0.5f);

        auto c = jp["condition"];
        p.condition.fatigue = c.value("fatigue", 0.0f);
        p.condition.pressure01 = c.value("pressure01", 0.0f);
        p.condition.breath = c.value("breath", 1.0f);

        auto it = jp["intent"];
        p.intent.targetPos = it["targetPos"].get<Vec3>();
        p.intent.desiredSpeed01 = it.value("desiredSpeed01", 0.0f);
        p.intent.faceDir = it["faceDir"].get<Vec3>();
        p.intent.action = static_cast<RequestedAction>(it.value("action", 0));

        auto st = jp["state"];
        p.state.position = st["position"].get<Vec3>();
        p.state.velocity = st["velocity"].get<Vec3>();
        p.state.facingRadians = st.value("facingRadians", 0.0f);
        p.state.hasBall = st.value("hasBall", false);
        p.state.nextDecisionTime = st.value("nextDecisionTime", 0.0f);
        p.state.cachedTarget = st.value("cachedTarget", Vec3{});
        p.state.cachedAction = static_cast<RequestedAction>(st.value("cachedAction", 0));
        p.state.cachedFaceDir = st.value("cachedFaceDir", Vec3{});
        p.state.faceLockUntil = st.value("faceLockUntil", 0.0f);
        p.state.scanDir = st.value("scanDir", Vec3{});
        p.state.scanHalfAngle = st.value("scanHalfAngle", 0.6f);
        p.state.nextScanTime = st.value("nextScanTime", 0.0f);

        world.players.push_back(p);
    }

    world.rngSeed = j.value("rngSeed", 0ULL);
    SeedRng(world, world.rngSeed);
    return world;
}
}  // namespace tf

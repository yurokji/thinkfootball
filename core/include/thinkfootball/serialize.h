#pragma once

#include "thinkfootball/world_state.h"
#include <string>

namespace tf
{
// Serialize world state (including rng seed) to JSON string.
std::string ToJson(const WorldState& world);

// Deserialize world state from JSON string; initializes rng with stored seed.
WorldState FromJson(const std::string& json);
}

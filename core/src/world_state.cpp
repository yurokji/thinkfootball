#include "thinkfootball/world_state.h"

namespace tf
{
void AdvanceClock(WorldState& world, float dtSeconds)
{
    world.clock.deltaSeconds = dtSeconds;
    world.clock.timeSeconds += dtSeconds;
}

void SeedRng(WorldState& world, std::uint64_t seed)
{
    world.rngSeed = seed;
    world.rng.seed(seed);
}
}  // namespace tf

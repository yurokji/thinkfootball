#include "thinkfootball/world_state.h"

namespace tf
{
void AdvanceClock(WorldState& world, float dtSeconds)
{
    world.clock.deltaSeconds = dtSeconds;
    world.clock.timeSeconds += dtSeconds;
}
}  // namespace tf

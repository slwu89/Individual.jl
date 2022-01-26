# [API reference](@id ref_api)
## Basic schema

Functions to create basic Markov individual-based models (IBM).

```@docs
individual.schema_base.TheoryIBM
individual.schema_base.AbstractIBM
individual.schema_base.IBM
individual.schema_base.npeople
individual.schema_base.nstate
individual.schema_base.statelabel
individual.schema_base.get_index_state
individual.schema_base.queue_state_update
individual.schema_base.apply_state_updates
individual.schema_base.render_states
individual.schema_base.initialize_states
individual.schema_base.reset_states
individual.schema_base.simulation_loop
```

## Event scheduling schema

Create IBMs with event scheduling capabilities.

```@docs
individual.schema_events.TheorySchedulingIBM
individual.schema_events.AbstractSchedulingIBM
individual.schema_events.SchedulingIBM
individual.schema_events.add_event
individual.schema_events.schedule_event
individual.schema_events.get_scheduled
individual.schema_events.clear_schedule
individual.schema_events.event_tick
individual.schema_events.event_process
individual.schema_events.simulation_loop
```

## Sampling

Methods for sampling random variates commonly used in IBMs.

```@docs
individual.sampling.delay_geom_sample
individual.sampling.bernoulli_sample
individual.sampling.choose
```
# [API reference](@id ref_api)
## Basic schema

Functions to create basic Markov individual-based models (IBM).

```@docs
Individual.SchemaBase.TheoryIBM
Individual.SchemaBase.AbstractIBM
Individual.SchemaBase.IBM
Individual.SchemaBase.npeople
Individual.SchemaBase.nstate
Individual.SchemaBase.statelabel
Individual.SchemaBase.get_index_state
Individual.SchemaBase.queue_state_update
Individual.SchemaBase.render_states
Individual.SchemaBase.initialize_states
Individual.SchemaBase.reset_states
Individual.SchemaBase.create_state_update
Individual.SchemaBase.create_attr_update
Individual.SchemaBase.simulation_loop
```

## Event scheduling schema

Create IBMs with event scheduling capabilities.

```@docs
Individual.SchemaEvents.TheorySchedulingIBM
Individual.SchemaEvents.AbstractSchedulingIBM
Individual.SchemaEvents.SchedulingIBM
Individual.SchemaEvents.add_event
Individual.SchemaEvents.schedule_event
Individual.SchemaEvents.get_scheduled
Individual.SchemaEvents.clear_schedule
Individual.SchemaEvents.event_tick
Individual.SchemaEvents.event_process
```

## Sampling

Methods for Sampling random variates commonly used in IBMs.

```@docs
Individual.Sampling.delay_geom_sample
Individual.Sampling.bernoulli_sample
Individual.Sampling.choose
```
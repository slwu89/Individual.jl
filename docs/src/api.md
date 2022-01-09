# API reference

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
individual.schema_base.output_states
```

## Event scheduling schema

Create IBMs with event scheduling capabilities.

```@docs
individual.schema_events.TheorySchedulingIBM
individual.schema_events.AbstractSchedulingIBM
individual.schema_events.SchedulingIBM
individual.schema_events.schedule_event
individual.schema_events.get_scheduled
individual.schema_events.clear_schedule
individual.schema_events.event_tick
individual.schema_events.event_process
```

## Sampling

Methods for sampling random variates commonly used in IBMs.

```@docs
individual.sampling.delay_sample
individual.sampling.bernoulli_sample
individual.sampling.choose
```
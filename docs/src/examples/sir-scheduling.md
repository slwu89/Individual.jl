```@meta
EditURL = "https://github.com/AlgebraicJulia/AlgebraicPetri.jl/blob/master/docs/examples/sir-scheduling.jl"
```

# [SIR example with event scheduling](@id sir_scheduling)
Sean L. Wu (@slwu89), 2021-1-9

````@example sir-scheduling
using Individual.Sampling
using Individual.SchemaBase
using Individual.SchemaEvents

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs
using Plots
````

## Introduction
This tutorial shows how to simulate the SIR model using the event scheduling schema available in Individual.jl. The stochastic
process being simulated is exactly the same as the basic [Markov SIR model tutorial](@ref sir_basic), and all parameters
are identical, so please see that tutorial for reference if needed.

The schema looks like this:

````@example sir-scheduling
to_graphviz(TheorySchedulingIBM)
````

The schema expands on the basic `TheoryIBM` for Markov models; the relationship between states and people is the same.
There is a new object, `Event`, which in epidemiological models might contain recovery, hospitalization, death, etc.
There are morphisms into the objects `EventLabel` and `EventListener`. `EventLabel` is simply a string for writing
self-documenting models. The `EventListener` stores functions called "event listeners" which are called with the
set of persons scheduled for that event on that timestep, and may queue state updates, and schedule or cancel other events.

The set of scheduled (queued) events is also an object `Scheduled`, with morphisms into the objects of events and persons, and a delay attribute.
For each queued event these tell us which event will occur, who it will happen to, and after how many timesteps it (the event listener) should fire.
This event scheduling mechanism allows events which occur after a non-Geometric (i.e. non-Markovian) delay, such as fixed delays
or any other distribution.

If we had additional combinatorial data describing each person (e.g. discrete age bin for each person), we could make another attribute and a morphism from people to that attribute.
Additional atomic data for each person (e.g. neutralizing antibody titre) would be an attribute of people. In this way we can simulate
a general class of individual based models relevant to epidemiology, ecology, and the social sciences.

## Parameters

````@example sir-scheduling
N = 1000
I0 = 8
S0 = N - I0
Δt = 0.1
tmax = 100
steps = Int(tmax/Δt)
γ = 1/10 # recovery rate
R0 = 2.5
β = R0 * γ # R0 for corresponding ODEs

initial_states = fill("S", N)
initial_states[rand(1:N, I0)] .= "I"
state_labels = ["S", "I", "R"];
nothing #hide
````

## Model object

The "SchedulingIBM" (Individual Based Model with Scheduling) schema needs several type parameters.
The first is the same as the "IBM" schema, associating a unique name to each categorical state.
The second is the delay, the number of time steps after which a scheduled event will fire.
The third is the name for each event. The last is for the listeners associated with each event.

````@example sir-scheduling
const SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
initialize_states(SIR, initial_states, state_labels);
nothing #hide
````

## Processes

The infection process is the same as the basic SIR model.

````@example sir-scheduling
function infection_process(t::Int)
    I = npeople(SIR, "I")
    N = npeople(SIR)
    λ = β * I/N
    S = get_index_state(SIR, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR, S, "I")
end
````

The recovery process is queues future recovery events. We first find who is infected,
and then take the set difference of those persons with those who are already scheduled for
recovery, which is just the set of persons who need a recovery scheduled.

````@example sir-scheduling
function recovery_process(t::Int)

    I = get_index_state(SIR, "I")
    already_scheduled = get_scheduled(SIR, "Recovery")
    to_schedule = setdiff(I, already_scheduled)

    if length(to_schedule) > 0
        rec_times = delay_geom_sample(length(to_schedule), γ, Δt)
        schedule_event(SIR, to_schedule, rec_times, "Recovery")
    end
end
````

## Events

The event listener associated with recovery is quite simple, just updating the state to R.
We create an event with the label "Recovery" and a single listener, and add it to the model.

````@example sir-scheduling
function recovery_listener(target, t::Int)
    queue_state_update(SIR, target, "R")
end

add_event(SIR, "Recovery", recovery_listener);
nothing #hide
````

## Simulation

We use `render_process` to create a rendering (output) process and
a matrix giving state counts by time step. Then we draw a trajectory and plot the results.
We need to use the `simulation_loop` from the module for models with event scheduling.

````@example sir-scheduling
state_out, render_process = render_states(SIR, steps)

SchemaEvents.simulation_loop(SIR, [infection_process, recovery_process, render_process], steps)

plot(
    (1:steps) * Δt,
    state_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)
````


# # [SIR example with event scheduling](@id sir_scheduling)
# Sean L. Wu (@slwu89), 2021-1-9

using individual.sampling
using individual.schema_base
using individual.schema_events

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs
using Plots, GraphViz

# ## Introduction
# This tutorial shows how to simulate the SIR model using the event scheduling schema available in individual.jl. The stochastic
# process being simulated is exactly the same as the basic [Markov SIR model tutorial](@ref sir_basic), and all parameters
# are identical, so please see that tutorial for reference if needed.

# The schema looks like this:

to_graphviz(TheorySchedulingIBM)

# The schema expands on the basic `TheoryIBM` for Markov models; the relationship between states and people is the same.
# There is a set of `Event`s, which in epidemiological models might correspond to recovery, hospitalization, death, etc.
# Each event has a label for writing self-documenting models, and an `EventListener`, which can be used to store
# functions called "event listeners" which are called with the set of persons scheduled for that event on that timestep, and 
# may queue state updates, and schedule or cancel other events.

# The set of scheduled (queued) events is also a set `Scheduled`, with morphisms into the set of events and persons, and a delay `Attr`.
# For each queued event these tell us which event will occur, who it will happen to, and after how many timesteps it (the event listener) should fire.

# If we had additional combinatorial data describing each person (e.g. discrete age bin for each person), we could make another set and a morphism from people to that set. 
# Additional atomic data for each person (e.g. neutralizing antibody titre) would be an `Attr` of people. In this way we can simulate
# a general class of individual based models relevant to epidemiology, ecology, and the social sciences.

# ## Parameters

N = 1000
I0 = 5
S0 = N - I0
Δt = 0.1
tmax = 100
steps = Int(tmax/Δt)
γ = 1/10 # recovery rate
R0 = 2.5
β = R0 * γ # R0 for corresponding ODEs

initial_states = fill(1, N)
initial_states[rand(1:N, I0)] .= 2
state_labels = ["S", "I", "R"];

# ## Model object

const SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
add_parts!(SIR, :State, length(state_labels), statelabel = state_labels)
people = add_parts!(SIR, :Person, N)
set_subpart!(SIR, people, :state, initial_states);

# ## Processes

# The infection process is the same as the basic SIR model. 

function infection_process(t::Int)
    I = npeople(SIR, "I")
    N = npeople(SIR)
    λ = β * I/N
    S = get_index_state(SIR, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR, S, "I")
end

# The recovery process is queues future recovery events. We first find who is infected,
# and then take the set difference of those persons with those who are already scheduled for
# recovery, which is just the set of persons who need a recovery scheduled.

function recovery_process(t::Int)

    I = get_index_state(SIR, "I")
    already_scheduled = get_scheduled(SIR, "Recovery")
    to_schedule = setdiff(I, already_scheduled)

    if length(to_schedule) > 0
        rec_times = delay_sample(length(to_schedule), γ, Δt)
        schedule_event(SIR, to_schedule, rec_times, "Recovery")
    end
end

# ## Events

# The event listener associated with recovery is quite simple, just updating the state to R.
# We create an event with the label "Recovery" and a single listener, and add it to hhe model.

function recovery_listener(target, t::Int)
    queue_state_update(SIR, target, "R")
end

recovery_listeners = Function[]
push!(recovery_listeners, recovery_listener)
add_parts!(SIR, :Event, 1, eventlabel = "Recovery", eventlistener = [recovery_listeners]);

# ## Simulation

# We draw a trajectory and plot the results.

out = Array{Int64}(undef, steps, 3)

for t = 1:steps
    infection_process(t)
    recovery_process(t)
    event_process(SIR, t)
    event_tick(SIR)
    out[t, :] = output_states(t, SIR)
    apply_state_updates(SIR)
end

plot(
    (1:steps) * Δt,
    out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)
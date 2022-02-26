using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories
using Individual.Sampling

# @present TheoryIBM(FreeSchema) begin 
#   Person::Ob 
#   PersonInstance::Ob 
#   next::Hom(PersonInstance, PersonInstance)
#   current::Hom(Person, PersonInstance)
#   person_identity::Hom(PersonInstance, Person)

#   State::Ob
#   StaticState::Ob
#   state::Hom(PersonInstance, State)
#   static_state::Hom(Person, StaticState)
  
#   StateLabel::AttrType
#   StaticStateLabel::AttrType
#   statelabel::Attr(State, StateLabel)
#   staticstatelabel::Attr(StaticState, StaticStateLabel)

#   Time::AttrType
#   time::Attr(PersonInstance, Time)

#   Event::Ob
#   event::Hom(PersonInstance, Event)
  
#   EventLabel::AttrType
#   eventslabel::Attr(Event, EventLabel)

#   EventListener::AttrType
#   eventlistener::Attr(Event, EventListener)

# end

# @abstract_acset_type AbstractIBM

# @acset_type IBM(TheoryIBM, index = [:current, :next, :person_identity, :state, :static_state, :event], 
#       unique_index = [:statelabel, :staticstatelabel]) <: AbstractIBM


@present TheoryMarkovIBM(FreeSchema) begin
  Person::Ob
  CurrentInstance::Ob
  NextInstance::Ob

  State::Ob # allow the user to have many states

  current::Hom(Person, CurrentInstance)
  next::Hom(Person, NextInstance)
  #current_identity::Hom(CurrentInstance, Person)
  #next_identity::Hom(NextInstance, Person)
  
  current_state::Hom(CurrentInstance, State)
  next_state::Hom(NextInstance, State)

  StateLabel::AttrType
  statelabel::Attr(State, StateLabel)
end

@abstract_acset_type AbstractIBM

# @acset_type MarkovIBM(TheoryMarkovIBM, index = [:current_state, :next_state], unique_index = [:statelabel, :current, :next]) <: AbstractIBM

@acset_type MarkovIBM(TheoryMarkovIBM, index = [:current_state, :next_state, :current, :next], unique_index = [:statelabel]) <: AbstractIBM

# process


""" 
    npeople(model::AbstractIBM, states)

Return the number of people in some set of `states` (an element of the State Ob).
If called without the argument `states`, simply return the total population size.
"""
npeople(model::AbstractIBM) = nparts(model, :Person)
npeople(model::AbstractIBM, states) = length(incident(model, states, [:current_state, :statelabel]))

""" 
    nstate(model::AbstractIBM)

Return the size of the finite state space.
"""
nstate(model::AbstractIBM) = nparts(model, :State)

""" 
    statelabel(model::AbstractIBM)

Return the labels (names) of the states in the finite state space.
"""
statelabel(model::AbstractIBM) = subpart(model, :statelabel)

""" 
    get_index_state(model::AbstractIBM, states)

Return an integer vector giving the persons who are in the states specified in `states`.
If called without the argument `states`, simply return everyone's index.
"""
get_index_state(model::AbstractIBM, states) = incident(model, states, [:current_state, :statelabel])
get_index_state(model::AbstractIBM) = parts(model, :Person)


""" 
    queue_state_update(model::AbstractIBM, persons, state)

For persons specified in `persons`, queue a state update to `state`, which will be applied at the
end of the time step.
"""
function queue_state_update(model::AbstractIBM, persons, state)
    if length(persons) > 0
        state_index = only(incident(model, state, :statelabel))
        state_index > 0 || throw(ArgumentError("state $(state) is not is the set of state labels"))
        nexts = add_parts!(model, :NextInstance, length(persons), 
            next_state=state_index)
        set_subpart!(model, persons, :next, nexts)
    end
end

""" 
    simulation_loop(model::AbstractIBM, processes::Union{Function, AbstractVector{Function}}, steps::Integer)

A simple predefined simulation loop for basic (no events) individual based models. Processes are called first,
followed by state updates.
"""
function simulation_loop(model::AbstractIBM, processes::Union{Function, AbstractVector{Function}}, steps::Integer)
    if processes isa Function
        processes = [processes]
    end

    for t = 1:steps
        for p = processes
            p(t)
        end

        nexts = parts(model, :NextInstance)
        # set_subpart!(model, model[:current][incident(model, nexts, :next)], :current_state, model[:next_state][nexts])
        set_subpart!(model, model[:current][vcat(incident(model, nexts, :next)...)], :current_state, model[:next_state][nexts])
        set_subpart!(model, :next, 0)
        rem_parts!(model, :NextInstance, nexts)
        # for i = parts(model, :NextInstance) # assumes each person has a current
        #     actual_person = incident(model, i, :next)
        #     set_subpart!(model, model[:current][actual_person], :current_state, model[:next_state][i])
        # end

    end
end





using StatsBase

# N = 20
# I = 5
# R = 5
# to_set = sample(1:N, I+R, replace = false)

# initial_states = fill("S", N)
# initial_states[to_set[1:I]] .= "I"
# initial_states[to_set[I+1:end]] .= "R"
# state_labels = ["S", "I", "R"];

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


SIR = MarkovIBM{String}()

add_parts!(SIR, :State, 3, statelabel = state_labels)
add_parts!(SIR, :Person, N)

add_parts!(SIR, :CurrentInstance, N)
set_subpart!(SIR, 1:N, :current_state, indexin(initial_states, state_labels))

set_subpart!(SIR, 1:N, :current, 1:N)

npeople(SIR)
npeople(SIR, ["S", "I", "R"])
npeople(SIR, "S")
npeople(SIR, "I")
npeople(SIR, "R")


function render_states(model::AbstractIBM, steps::Integer)
    out = Array{Int64}(undef, steps, nstate(model))

    output_states(t::Int) = begin
        out[t, :] = [length(incident(model, i, :current_state)) for i = parts(model, :State)]
    end

    return (out, output_states)
end


function infection_process(t::Int)
    I = npeople(SIR, "I")
    N = npeople(SIR)
    λ = β * I/N
    S = get_index_state(SIR, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR, S, "I")
end

function recovery_process(t::Int)
    I = get_index_state(SIR, "I")
    I = bernoulli_sample(I, γ, Δt)
    queue_state_update(SIR, I, "R")
end

state_out, render_process = render_states(SIR, steps)

# t=1
# infection_process(t)
# recovery_process(t)

simulation_loop(SIR, [infection_process, recovery_process, render_process], steps)

using Plots

plot(
    (1:steps) * Δt,
    state_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)

""" Define a schema and ACSet which can be used as the base for most individual-based epidemiological models.
    Alone, this module allows for simulation of Markov models.
"""
module schema_base

export TheoryIBM, AbstractIBM, IBM,
    npeople, nstate, statelabel, get_index_state,
    queue_state_update, apply_state_updates, output_states

using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

""" ACSet definition for a basic individual-based model
    See Catlab.jl documentation for description of the @present syntax.
"""
@present TheoryIBM(FreeSchema) begin
    Person::Ob
    State::Ob

    state::Hom(Person, State)
    state_update::Hom(Person, State)

    StateLabel::AttrType
    statelabel::Attr(State, StateLabel)
end

""" An abstract ACSet for a basic Markov individual-based model inheriting from `AbstractIBM`
    which allows for events to be scheduled for persons.
"""
@abstract_acset_type AbstractIBM

""" A concrete ACSet for a basic Markov individual-based model inheriting from `AbstractIBM`.
"""
@acset_type IBM(TheoryIBM,index = [:state, :state_update]) <: AbstractIBM

""" npeople(model::AbstractIBM, states)

    Return the number of people in some set of `states` (an element of the State Ob).
    If called without the argument `states`, simply return the total population size.
"""
npeople(model::AbstractIBM) = nparts(model, :Person)
npeople(model::AbstractIBM, states) = length(incident(model, states, [:state, :statelabel]))

""" nstate(model::AbstractIBM)

    Return the size of the finite state space.
"""
nstate(model::AbstractIBM) = nparts(model, :State)

""" statelabel(model::AbstractIBM)

    Return the labels (names) of the states in the finite state space.
"""
statelabel(model::AbstractIBM) = subpart(model, :statelabel)

""" get_index_state(model::AbstractIBM, states)

    Return an integer vector giving the persons who are in the states specified in `states`.
    If called without the argument `states`, simply return everyone's index.
"""
get_index_state(model::AbstractIBM, states) = incident(model, states, [:state, :statelabel])
get_index_state(model::AbstractIBM) = parts(model, :Person)


""" queue_state_update(model::AbstractIBM, persons, state)

    For persons specified in `persons`, queue a state update to `state`, which will be applied at the
    end of the time step.
"""
function queue_state_update(model::AbstractIBM, persons, state)
    @assert length(state) == 1
    if length(persons) > 0
        set_subpart!(model, persons, :state_update, incident(model, state, :statelabel)[1])
    end
end

""" apply_state_updates(model::AbstractIBM)

    Apply all queued state updates.
"""
function apply_state_updates(model::AbstractIBM)
    for state = parts(model, :State)
        people_to_update = incident(model, state, :state_update)
        if length(people_to_update) > 0
            set_subpart!(model, people_to_update, :state, state)
        end
    end
    set_subpart!(model, :state_update, 0)
end

""" output_states(t::Int, model::AbstractIBM)

    Return a vector counting the number of persons in each state.
"""
function output_states(t::Int, model::AbstractIBM)
    [length(incident(model, i, :state)) for i = parts(model, :State)]
end

end
""" Define a schema and ACSet which can be used as the base for most individual-based epidemiological models.
    Alone, this module allows for simulation of Markov models.
"""
module schema_base

export TheoryIBM, AbstractIBM, IBM,
    npeople, nstate, statelabel, get_index_state,
    queue_state_update, apply_state_updates, 
    render_states,
    initialize_states, reset_states

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

""" render_states(model::AbstractIBM, steps::Integer)

    Return a tuple whose first element is a matrix containing counts of
    states (columns) by time step (rows), and whose second element is a _process_
    function which can be used in the simulation loop.
"""
function render_states(model::AbstractIBM, steps::Integer)
    out = Array{Int64}(undef, steps, nstate(model))

    output_states(t::Int) = begin
        out[t, :] = [length(incident(model, i, :state)) for i = parts(model, :State)]
    end

    return (out, output_states)
end

""" initialize_states(model::AbstractIBM, initial_states, state_labels::Vector{String})

    Initialize the categorical states of a model. The argument `initial_states` can either
    be provided as a vector of integers, corresponding to the internal storage of the ACSet,
    or as a vector of strings. It should be equal in length to the population which is to be
    simulated.
"""
function initialize_states(model::AbstractIBM, initial_states::Vector{T}, state_labels::Vector{String}) where {T <: Integer}
    length(unique(initial_states)) <= length(state_labels) || throw(ArgumentError("'initial_states' has more unique values than 'state_labels', please fix"))
    if nparts(model, :State) > 0
        reset_states(model, initial_states)
    else
        add_parts!(model, :State, length(state_labels), statelabel = state_labels)
        people = add_parts!(model, :Person, length(initial_states))
        set_subpart!(model, people, :state, initial_states);
    end
end

function initialize_states(model::AbstractIBM, initial_states::Vector{String}, state_labels::Vector{String})
    length(unique(initial_states)) <= length(state_labels) || throw(ArgumentError("'initial_states' has more unique values than 'state_labels', please fix"))
    if nparts(model, :State) > 0
        reset_states(model, initial_states)
    else
        add_parts!(model, :State, length(state_labels), statelabel = state_labels)
        people = add_parts!(model, :Person, length(initial_states))
        set_subpart!(model, people, :state, indexin(initial_states, state_labels));
    end
end


""" initialize_states(model::AbstractIBM, initial_states)

    Reset a model's categorical states.
"""
function reset_states(model::AbstractIBM, initial_states::Vector{T}) where {T <: Integer}
    nparts(model, :Person) == length(initial_states) || throw(ArgumentError("'initial_states' must be equal to the number of persons in the model"))
    set_subpart!(model, :state_update, 0)
    set_subpart!(model, :state, initial_states);
end

function reset_states(model::AbstractIBM, initial_states::Vector{String})
    nparts(model, :Person) == length(initial_states) || throw(ArgumentError("'initial_states' must be equal to the number of persons in the model"))
    set_subpart!(model, :state_update, 0)
    set_subpart!(model, :state, indexin(initial_states, subpart(model, :statelabel)));
end

end
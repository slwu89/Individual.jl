""" Define a schema and ACSet which can be used as the base for most individual-based epidemiological models.
    Alone, this module allows for simulation of Markov models.
"""
module SchemaBase

export TheoryIBM, AbstractIBM, IBM,
    npeople, nstate, statelabel, get_index_state,
    queue_state_update, apply_state_updates, 
    render_states,
    initialize_states, reset_states,
    create_state_update,
    simulation_loop

using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

# using Catlab.CSetDataStructures: StructACSet
# using Catlab.Theories: FreeSchema, SchemaDesc, SchemaDescType, CSetSchemaDescType,
# SchemaDescTypeType, ob_num, codom_num, attr, attrtype

""" ACSet definition for a basic individual-based model
    See [Catlab.jl documentation](https://algebraicjulia.github.io/Catlab.jl/stable/generated/sketches/smc/#Presentations) 
    for description of the `@present` syntax.    
"""
@present TheoryIBM(FreeSchema) begin
    Person::Ob
    State::Ob

    state::Hom(Person, State)
    state_update::Hom(Person, State)

    StateLabel::AttrType
    statelabel::Attr(State, StateLabel)
end

""" An abstract ACSet for a basic Markov individual-based model.
"""
@abstract_acset_type AbstractIBM

""" 
A concrete ACSet for a basic Markov individual-based model inheriting from `AbstractIBM`.
"""
@acset_type IBM(TheoryIBM, index = [:state, :state_update], unique_index = [:statelabel]) <: AbstractIBM

""" 
    npeople(model::AbstractIBM, states)

Return the number of people in some set of `states` (an element of the State Ob).
If called without the argument `states`, simply return the total population size.
"""
npeople(model::AbstractIBM) = nparts(model, :Person)
npeople(model::AbstractIBM, states) = length(incident(model, states, [:state, :statelabel]))

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
get_index_state(model::AbstractIBM, states) = incident(model, states, [:state, :statelabel])
get_index_state(model::AbstractIBM) = parts(model, :Person)


""" 
    queue_state_update(model::AbstractIBM, persons, state)

For persons specified in `persons`, queue a state update to `state`, which will be applied at the
end of the time step.
"""
function queue_state_update(model::AbstractIBM, persons, state)
    if length(persons) > 0
        state_index = incident(model, state, :statelabel)
        state_index > 0 || throw(ArgumentError("state $(state) is not is the set of state labels"))
        set_subpart!(model, persons, :state_update, state_index)
    end
end


""" 
    render_states(model::AbstractIBM, steps::Integer)

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

""" 
    initialize_states(model::AbstractIBM, initial_states, state_labels::Vector{String})

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


""" 
    initialize_states(model::AbstractIBM, initial_states)

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


""" 
    create_state_update(model::AbstractIBM)

Return a function that is called with no arguments that updates any `Ob` that has an accompanying update `Ob`.
For example, if you provide both `risk` and `risk_update`, then `risk_update` will be used to update `risk` and
then cleared.
"""
function create_state_update(model::AbstractIBM)
    s = acset_schema(model)
    homs = s.homs
    homs = map((x)->String(x), homs)
    homs = split.(homs, "_")

    # all the homs that end in 'update'
    update_ix = findall(homs) do x
        if length(x) < 2
            return false
        else
            return x[end] == "update"
        end
    end

    # membership homs that correspond to the update homs
    state_ix = map(update_ix) do x
        for i = 1:length(homs)
            if i == x
                continue
            else
                if homs[x][1:end-1] == homs[i]
                    return i
                end
            end
        end
    end

    # the obs that the update homs are updating
    state_obs = map(update_ix) do x
        s.codoms[s.homs[x]]
    end

    state_homs = s.homs[state_ix]
    update_homs = s.homs[update_ix]

    length(update_ix) == length(state_ix) == length(state_obs) || throw(AssertionError("some update homs do not have corresponding membership homs, please check your schema"))

    function update()
        # all Obs that need updating
        for ob in 1:length(state_obs)
            # all particular states in that Ob
            for state in parts(model, state_obs[ob])
                people_to_update = incident(model, state, update_homs[ob])
                if length(people_to_update) > 0
                    set_subpart!(model, people_to_update, state_homs[ob], state)
                end
            end
            set_subpart!(model, update_homs[ob], 0)
        end
    end

    return update
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

    apply_state_updates = create_state_update(model)

    for t = 1:steps
        for p = processes
            p(t)
        end
        apply_state_updates()
    end
end

end
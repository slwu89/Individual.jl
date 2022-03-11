""" Define a schema and ACSet which can be used as the base for most individual-based epidemiological models.
    Alone, this module allows for simulation of Markov models.
"""
module SchemaBase

export TheoryMarkovIBM, AbstractIBM, MarkovIBM,
    npeople, nstate, statelabel, get_index_state,
    queue_state_update, apply_state_updates, 
    render_states,
    initialize_states, reset_states,
    apply_queued_updates,
    simulation_loop

using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories
using Catlab.Theories: FreeSchema, SchemaDesc, SchemaDescType, CSetSchemaDescType,
SchemaDescTypeType, ob_num, codom_num, attr, attrtype


""" ACSet definition for a basic individual-based model
    See [Catlab.jl documentation](https://algebraicjulia.github.io/Catlab.jl/stable/generated/sketches/smc/#Presentations) 
    for description of the `@present` syntax.    
"""
@present TheoryMarkovIBM(FreeSchema) begin
  Person::Ob
  Current::Ob
  Next::Ob

  State::Ob

  current::Hom(Person, Current)
  next::Hom(Person, Next)
  
  current_state::Hom(Current, State)
  next_state::Hom(Next, State)

  StateLabel::AttrType
  statelabel::Attr(State, StateLabel)
end


""" An abstract ACSet for a basic Markov individual-based model.
"""
@abstract_acset_type AbstractIBM


""" 
A concrete ACSet for a basic Markov individual-based model inheriting from `AbstractIBM`.
"""
# the Homs current and next should be uniquely indexed but waiting on Catlab issues:
# https://github.com/AlgebraicJulia/Catlab.jl/issues/606
# https://github.com/AlgebraicJulia/Catlab.jl/issues/597
@acset_type MarkovIBM(TheoryMarkovIBM, index = [:current_state, :next_state, :current, :next], unique_index = [:statelabel]) <: AbstractIBM


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
        add_parts!(model, :Current, length(people))
        set_subpart!(model, people, :current_state, initial_states)
        set_subpart!(model, people, :current, people);
    end
end

function initialize_states(model::AbstractIBM, initial_states::Vector{String}, state_labels::Vector{String})
    length(unique(initial_states)) <= length(state_labels) || throw(ArgumentError("'initial_states' has more unique values than 'state_labels', please fix"))
    if nparts(model, :State) > 0
        reset_states(model, initial_states)
    else
      initial_states_int = indexin(initial_states, state_labels)
      add_parts!(model, :State, length(state_labels), statelabel = state_labels)
      people = add_parts!(model, :Person, length(initial_states_int))
      add_parts!(model, :Current, length(people))
      set_subpart!(model, people, :current_state, initial_states_int)
      set_subpart!(model, people, :current, people);
    end
end


""" 
reset_states(model::AbstractIBM, initial_states)

Reset a model's categorical states.
"""
function reset_states(model::AbstractIBM, initial_states::Vector{T}) where {T <: Integer}
    nparts(model, :Person) == length(initial_states) || throw(ArgumentError("'initial_states' must be equal to the number of persons in the model"))
    rem_parts!(model, :Next, parts(model, :Next))
    people = parts(model, :Person)
    set_subpart!(model, people, :current_state, initial_states)
    set_subpart!(model, people, :current, people);
end

function reset_states(model::AbstractIBM, initial_states::Vector{String})
    nparts(model, :Person) == length(initial_states) || throw(ArgumentError("'initial_states' must be equal to the number of persons in the model"))
    rem_parts!(model, :Next, parts(model, :Next))
    people = parts(model, :Person)
    set_subpart!(model, people, :current_state, indexin(initial_states, subpart(model, :statelabel)))
    set_subpart!(model, people, :current, people);
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
        out[t, :] = [length(incident(model, i, :current_state)) for i = parts(model, :State)]
    end

    return (out, output_states)
end



function get_already_queued(model::AbstractIBM, persons::AbstractArray{T}) where {T <: Integer}
    return persons .∈ Ref(vcat(incident(model, filter(>(0), subpart(model, :next)), :next)...))
end

""" 
    queue_state_update(model::AbstractIBM, persons, state)

For persons specified in `persons`, queue a state update to `state`, which will be applied at the
end of the time step.
"""
function queue_state_update(model::AbstractIBM, persons::AbstractArray{T}, state) where {T <: Integer}
    if length(persons) > 0
        state_index = only(incident(model, state, :statelabel))
        state_index > 0 || throw(ArgumentError("state $(state) is not is the set of state labels"))
        # find who in `persons` is already assigned a Next
        already_scheduled = get_already_queued(model, persons)
        if any(already_scheduled)
            # set `next_state` for those already-scheduled persons
            nexts = subpart(model, persons[already_scheduled], :next)
            set_subpart!(model, nexts, :next_state, state_index)
        end
        # people who are not already scheduled for update
        persons = persons[.!already_scheduled]
        if length(persons) > 0
            nexts = add_parts!(model, :Next, length(persons), next_state = state_index)
            nexts = length(nexts) > 1 ? nexts : only(nexts) # change if https://github.com/AlgebraicJulia/Catlab.jl/issues/606 changes
            set_subpart!(model, persons, :next, nexts)
        end
    end
end

function queue_state_update(model::AbstractIBM, persons::T, state) where {T <: Integer}
    queue_state_update(model, [persons], state)
end


""" 
    apply_queued_updates(acs::AbstractIBM)

Apply queued updates to dynamic Obs in an individual based model.
The argument should be a subtype of `AbstractIBM`. Any Ob that has exactly two Homs
with it as its codomain and Current and Next as domains of those two Homs is a dynamic Ob. 

This is a generated function, meaning it uses the information about your schema (as long as it inherits from `AbstractIBM`)
to find the dynamic Obs and Attrs and specialized code that will be fast for updating your model.
"""
apply_queued_updates(acs::AbstractIBM) = _apply_queued_updates(acs)

# ugly but works, its like a slice category, but we need to wait on the implementation
@generated function _apply_queued_updates(acs::StructACSet{S}) where {S}
  # struct containing the schema
  s = SchemaDesc(S)

  # get Obs with 2 Homs with it as codomain and Current/Next as domains
  dyn_ob = Symbol[] # dynamic obs
  dyn_hom_current = Symbol[] # hom from Current -> dyn ob
  dyn_hom_next = Symbol[] # hom from Next -> dyn ob

  for ob in s.obs
    # don't need to check for (Person,Current,Next)
    if ob == :Person || ob == :Current || ob == :Next
      continue
    end
    # filter obs that dont have 2 homs with it as codomain
    if length(findall(values(s.codoms) .== ob)) != 2
      continue
    end
    # k: hom, v: codomain
    for (k, v) in s.codoms
      if v == ob
        if get(s.doms, k, nothing) == :Current
          push!(dyn_hom_current, k)
        elseif get(s.doms, k, nothing) == :Next
          push!(dyn_hom_next, k)
        else
          throw(ArgumentError("homs in schema into dynamic objects need to have only Next or Current as domain, $(k) does not"))
        end
      end
    end
    push!(dyn_ob, ob)
  end

  n_dyn_ob = length(dyn_ob)

  # get Attrs with 2 Homs with it as codomain and Current/Next as domains
  dyn_attr = Symbol[] # dynamic attrs
  dyn_hom_current_attr = Symbol[] # hom from Current -> dyn attr
  dyn_hom_next_attr = Symbol[] # hom from Next -> dyn attr

  # do the same for attributes
  for attr in s.attrs
    # filter attrs that dont have 2 homs with it as codomain
    if length(findall(values(s.codoms) .== attr)) != 2
      continue
    end
    # k: hom, v: codomain
    for (k, v) in s.codoms
      if v == attr
        if get(s.doms, k, nothing) == :Current
          push!(dyn_hom_current_attr, k)
        elseif get(s.doms, k, nothing) == :Next
          push!(dyn_hom_next_attr, k)
        else
          throw(ArgumentError("homs in schema into dynamic attrs need to have only Next or Current as domain, $(k) does not"))
        end
      end
    end
    push!(dyn_attr, attr)
  end

  n_dyn_attr = length(dyn_attr)

  # code to update dyn Obs
  code = quote 
    nexts = parts(acs, :Next)
    if (length(nexts) > 0)
      who = subpart(acs, vcat(incident(acs, nexts, :next)...), :current) # need vcat(...) until switch to unique_index after refactor (#597)
      for ob = 1:$(n_dyn_ob)
        ob_update = subpart(acs, nexts,  getindex($(dyn_hom_next), ob))
        set_subpart!(acs, who, getindex($(dyn_hom_current), ob), ob_update)
      end
    end
  end

  # update dyn Attrs if any
  if length(n_dyn_attr) > 0
    push!(
      code.args,
      quote
        for attr = 1:$(n_dyn_attr)
          attr_update = subpart(acs, nexts,  getindex($(dyn_hom_next_attr), attr))
          set_subpart!(acs, who, getindex($(dyn_hom_current_attr), attr), attr_update)
        end
      end
    )
  end

  # erase queued updates now that they have been applied
  push!(
    code.args,
    quote
      if (length(nexts) > 0)
        set_subpart!(acs, :next, 0)
        rem_parts!(acs, :Next, nexts)
      end
    end
  )

  code
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
        apply_queued_updates(model)
    end
end

end
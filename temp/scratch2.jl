using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

@present TheoryIBM(FreeSchema) begin
    # set of people and a finite state space
    Person::Ob
    State::Ob    

    # each person's current state
    state::Hom(Person, State)

    # queued state transitions
    state_update::Hom(Person, State)

    # labels of finite states
    StateLabel::AttrType
    statelabel::Attr(State, StateLabel)

    # some state which is not dynamic (no update)
    StaticState::Ob
    staticstate::Hom(Person, StaticState)
end

@abstract_acset_type AbstractIBM
@acset_type IBM(TheoryIBM,index = [:state, :state_update, :staticstate]) <: AbstractIBM



health_states = rand(1:3, 10)
static_states = rand(1:2, 10)

SIR = IBM{String}()

people = add_parts!(SIR, :Person, 10)
add_parts!(SIR, :State, 3, statelabel = ["S", "I", "R"])
add_parts!(SIR, :StaticState, 2)
set_subpart!(SIR, people, :state, health_states)

set_subpart!(SIR, people, :staticstate, static_states)

# queue update
# function create_state_update(acs)
    s = acset_schema(acs)
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

    function update()
        # all Obs that need updating
        for ob in 1:length(state_obs)
            # all particular states in that Ob
            for state in parts(acs, state_obs[ob])
                people_to_update = incident(acs, state, update_homs[ob])
                if length(people_to_update) > 0
                    set_subpart!(acs, people_to_update, state_homs[ob], state)
                end
            end
            set_subpart!(acs, update_homs[ob], 0)
        end
    end

    return update
# end



function test_closure(x)
    fn(x) = x + 2
    return fn
end

g = test_closure(2)
g(4)
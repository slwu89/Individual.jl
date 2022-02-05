using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

using Catlab.CSetDataStructures: StructACSet
using Catlab.Theories: FreeSchema, SchemaDesc, SchemaDescType, CSetSchemaDescType,
SchemaDescTypeType, ob_num, codom_num, attr, attrtype


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
end

@abstract_acset_type AbstractIBM
@acset_type IBM(TheoryIBM,index = [:state, :state_update]) <: AbstractIBM

N = 1000
I0 = 5
S0 = N - I0

health_states = fill(1, N)
health_states[rand(1:N, I0)] .= 2

SIR = IBM{String}()

people = add_parts!(SIR, :Person, N)
add_parts!(SIR, :State, 3, statelabel = ["S", "I", "R"])
set_subpart!(SIR, people, :state, health_states)




s = acset_schema(SIR)

# update state (Ob)
test_update_Ob(acs::StructACSet) = _test_update_Ob(acs)

function test_update_Ob_body(s::SchemaDesc, acs)
    homs = s.homs
    quote
        # acs.homs[$(homs)[1]]
        set_subpart!(acs, 1, $(homs)[1], 2)
    end
end

@generated function _test_update_Ob(acs::StructACSet{S, Ts, idxed}) where {S, Ts, idxed}
    test_update_Ob_body(SchemaDesc(S), acs)
end



test_update_Ob(SIR)

set_subpart!(SIR, 1, :state, 1)

test_update_Ob(SIR)


y=map(x) do i
    if i == -1
        return i
    end
end
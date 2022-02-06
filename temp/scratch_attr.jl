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
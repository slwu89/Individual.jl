using Individual.SchemaBase
using Catlab
using Catlab.ACSetInterface
using Catlab.Present
using Catlab.Theories
using Catlab.CategoricalAlgebra
using Test

@testset "construct model with integer initial states" begin

    initial_states = [1,2,3,1,2,3]
    state_labels = ["S", "I", "R"]

    SIR = MarkovIBM{String}()
    initialize_states(SIR, initial_states, state_labels)

    @test nparts(SIR, :Person) == length(initial_states)
    @test nparts(SIR, :State) == length(state_labels)
    @test subpart(SIR, :statelabel) == state_labels
    @test subpart(SIR, :state) == initial_states
    @test subpart(SIR, :state_update) == zeros(Int64, length(initial_states))

    @test npeople(SIR) == length(initial_states)
    @test npeople(SIR, "S") == count(x -> x == 1, initial_states)
    @test npeople(SIR, "I") == count(x -> x == 2, initial_states)
    @test npeople(SIR, "R") == count(x -> x == 3, initial_states)
    @test nstate(SIR) == length(state_labels)
    @test statelabel(SIR) == state_labels
    @test get_index_state(SIR) == 1:length(initial_states)
    @test get_index_state(SIR, "S") == findall(x -> x == 1, initial_states)
    @test get_index_state(SIR, "I") == findall(x -> x == 2, initial_states)
    @test get_index_state(SIR, "R") == findall(x -> x == 3, initial_states)

end

@testset "construct model with string initial states" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R"]

    SIR = IBM{String}()
    initialize_states(SIR, initial_states, state_labels)

    @test nparts(SIR, :Person) == length(initial_states)
    @test nparts(SIR, :State) == length(state_labels)
    @test subpart(SIR, :statelabel) == state_labels
    @test subpart(SIR, :state) == indexin(initial_states, state_labels)
    @test subpart(SIR, :state_update) == zeros(Int64, length(initial_states))

    @test npeople(SIR) == length(initial_states)
    @test npeople(SIR, "S") == count(x -> x == "S", initial_states)
    @test npeople(SIR, "I") == count(x -> x == "I", initial_states)
    @test npeople(SIR, "R") == count(x -> x == "R", initial_states)
    @test nstate(SIR) == length(state_labels)
    @test statelabel(SIR) == state_labels
    @test get_index_state(SIR) == 1:length(initial_states)
    @test get_index_state(SIR, "S") == findall(x -> x == "S", initial_states)
    @test get_index_state(SIR, "I") == findall(x -> x == "I", initial_states)
    @test get_index_state(SIR, "R") == findall(x -> x == "R", initial_states)

end

@testset "construct model errors properly" begin

    initial_states = [1,2,3,1,2,3,4]
    state_labels = ["S", "I", "R"]

    SIR = IBM{String}()
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

    initial_states = ["S", "I", "R", "S", "I", "R", "X"]
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

end

@testset "queuing and applying state updates works" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R"]

    SIR = IBM{String}()
    initialize_states(SIR, initial_states, state_labels)

    @test_throws ArgumentError queue_state_update(SIR, 1, "X")
    queue_state_update(SIR, 1, "R")
    @test findfirst(x -> x == 3, subpart(SIR, :state_update)) == 1

    queue_state_update(SIR, 6, "S")
    @test findfirst(x -> x == 1, subpart(SIR, :state_update)) == 6

    apply_state_updates = create_state_update(SIR)

    apply_state_updates()

    new_state = initial_states
    new_state[1] = "R"
    new_state[6] = "S"
    @test subpart(SIR, :state) == indexin(new_state, state_labels)
    @test subpart(SIR, :state_update) == zeros(Int64, length(initial_states))

    queue_state_update(SIR, 1:length(initial_states), "I")
    reset_states(SIR, initial_states)
    @test subpart(SIR, :state) == indexin(initial_states, state_labels)
    @test subpart(SIR, :state_update) == zeros(Int64, length(initial_states))

end

@testset "create_state_update is working properly" begin

    # fails properly
    @present TheoryStatesBadIBM <: TheoryIBM begin
        StateStatic::Ob
        statestatic::Hom(Person, StateStatic)

        StateDynamic::Ob
        statedynamic::Hom(Person, StateDynamic)
        statedynamicblah_update::Hom(Person, StateDynamic)
    end

    @abstract_acset_type AbstractStatesBadIBM <: AbstractIBM
    @acset_type StatesBadIBM(TheoryStatesBadIBM) <: AbstractStatesBadIBM

    SIR = StatesBadIBM{String}()

    @test_throws AssertionError create_state_update(SIR)

    # works
    @present TheoryStatesIBM <: TheoryIBM begin
        StateStatic::Ob
        statestatic::Hom(Person, StateStatic)

        StateDynamic::Ob
        statedynamic::Hom(Person, StateDynamic)
        statedynamic_update::Hom(Person, StateDynamic)
    end

    @abstract_acset_type AbstractStatesIBM <: AbstractIBM
    @acset_type StatesIBM(TheoryStatesIBM) <: AbstractStatesIBM

    SIR = StatesIBM{String}()

    initial_states = ["S", "I", "R", "S", "I", "R"]
    initial_statedynamic = [1,2,3,1,2,3]
    initial_statestatic = [1,1,1,2,2,2]
    state_labels = ["S", "I", "R"]
    initialize_states(SIR, initial_states, state_labels)

    add_parts!(SIR, :StateStatic, 2)
    set_subpart!(SIR, parts(SIR, :Person), :statestatic, initial_statestatic);

    add_parts!(SIR, :StateDynamic, 3)
    set_subpart!(SIR, parts(SIR, :Person), :statedynamic, initial_statedynamic);

    # updating function
    apply_state_updates = create_state_update(SIR)

    # expect state and statedynamic to be updated
    queue_state_update(SIR, [1,2], "R")
    set_subpart!(SIR, [4,5], :statedynamic_update, 3)

    apply_state_updates()

    @test SIR[:state] == [3,3,3,1,2,3]
    @test SIR[:statedynamic] == [1,2,3,3,3,3]
    @test SIR[:statestatic] == initial_statestatic

end

@testset "create_attr_update is working properly" begin

    # fails properly
    @present TheoryAttrBadIBM <: TheoryIBM begin
        AttrStatic::AttrType
        attrstatic::Attr(Person, AttrStatic)

        AttrDynamic::AttrType
        attrdynamic::Attr(Person, AttrDynamic)
        attrdynamicblah_update::Attr(Person, AttrDynamic)
    end

    @abstract_acset_type AbstractAttrBadIBM <: AbstractIBM
    @acset_type AttrBadIBM(TheoryAttrBadIBM) <: AbstractAttrBadIBM

    SIR = AttrBadIBM{String, Int64, Float64}()

    @test_throws AssertionError create_attr_update(SIR)

    # works
    @present TheoryAttrIBM <: TheoryIBM begin
        AttrStatic::AttrType
        attrstatic::Attr(Person, AttrStatic)

        AttrDynamic::AttrType
        attrdynamic::Attr(Person, AttrDynamic)
        attrdynamic_update::Attr(Person, AttrDynamic)
    end

    @abstract_acset_type AbstractAttrBadIBM <: AbstractIBM
    @acset_type AttrIBM(TheoryAttrIBM) <: AbstractAttrBadIBM

    SIR = AttrIBM{String, Int64, Float64}()

    initial_states = ["S", "I", "R", "S", "I", "R"]
    initial_attrstatic = [1,1,1,2,2,2]
    initial_attrdynamic = [1.0,2.0,3.0,1.0,2.0,3.0]
    state_labels = ["S", "I", "R"]
    initialize_states(SIR, initial_states, state_labels)

    set_subpart!(SIR, 1:6, :attrstatic, initial_attrstatic);
    set_subpart!(SIR, 1:6, :attrdynamic, initial_attrdynamic);

    @test_throws AssertionError create_attr_update(SIR)

    set_subpart!(SIR, 1:6, :attrdynamic_update, initial_attrdynamic);

    # updating function
    apply_attr_updates = create_attr_update(SIR)

    # expect state and statedynamic to be updated
    set_subpart!(SIR, [1,2], :attrdynamic_update, 3.0)

    apply_attr_updates()

    @test SIR[:state] == indexin(initial_states, state_labels)
    @test SIR[:attrdynamic] ≈ [3.0,3.0,3.0,1.0,2.0,3.0]
    @test SIR[:attrstatic] == initial_attrstatic

end
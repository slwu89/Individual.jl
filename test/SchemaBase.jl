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
    @test subpart(SIR, :current) == collect(1:6)
    @test subpart(SIR, :current_state) == initial_states
    @test subpart(SIR, :next) == zeros(Int64, 6)
    @test length(parts(SIR, :Next)) == 0 

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

    SIR = MarkovIBM{String}()
    initialize_states(SIR, initial_states, state_labels)

    @test nparts(SIR, :Person) == length(initial_states)
    @test nparts(SIR, :State) == length(state_labels)
    @test subpart(SIR, :statelabel) == state_labels
    @test subpart(SIR, :current) == collect(1:6)
    @test subpart(SIR, :current_state) == indexin(initial_states, state_labels)
    @test subpart(SIR, :next) == zeros(Int64, 6)
    @test length(parts(SIR, :Next)) == 0 

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

    SIR = MarkovIBM{String}()
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

    initial_states = ["S", "I", "R", "S", "I", "R", "X"]
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

end

@testset "queuing and applying state updates works" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R"]

    SIR = MarkovIBM{String}()
    initialize_states(SIR, initial_states, state_labels)

    @test_throws ArgumentError queue_state_update(SIR, 1, "X")
    queue_state_update(SIR, 1, "R")
    @test nparts(SIR, :Next) == 1
    @test incident(SIR, 3, [:next, :next_state]) == [1]

    queue_state_update(SIR, 2, "R")
    @test nparts(SIR, :Next) == 2
    @test incident(SIR, 3, [:next, :next_state]) == [1, 2]

    queue_state_update(SIR, 1, "I")
    @test nparts(SIR, :Next) == 2
    @test incident(SIR, 3, [:next, :next_state]) == [2]
    @test incident(SIR, 2, [:next, :next_state]) == [1]

    queue_state_update(SIR, 6, "S")
    @test nparts(SIR, :Next) == 3
    @test incident(SIR, 3, [:next, :next_state]) == [2]
    @test incident(SIR, 2, [:next, :next_state]) == [1]
    @test incident(SIR, 1, [:next, :next_state]) == [6]

    apply_queued_updates(SIR)

    new_state = initial_states
    new_state[1] = "I"
    new_state[2] = "R"
    new_state[6] = "S"

    @test subpart(SIR, :current_state) == indexin(new_state, state_labels)
    @test nparts(SIR, :Next) == 0

    queue_state_update(SIR, 1:length(initial_states), "I")
    reset_states(SIR, initial_states)
    @test subpart(SIR, :current_state) == indexin(initial_states, state_labels)
    @test nparts(SIR, :Next) == 0

end






@testset "dynamic Obs/Attrs can be updated properly" begin

    @present TheoryStatesIBM <: TheoryMarkovIBM begin
        StateStatic::Ob
        statestatic::Hom(Person, StateStatic)

        StateDynamic::Ob
        current_statedynamic::Hom(Current, StateDynamic)
        next_statedynamic::Hom(Next, StateDynamic)

        AttrStatic::AttrType
        attrstatic::Attr(Person, AttrStatic)

        AttrDynamic::AttrType
        current_attrdynamic::Attr(Current, AttrDynamic)
        next_attrdynamic::Attr(Next, AttrDynamic)
    end

    @abstract_acset_type AbstractStatesIBM <: AbstractIBM
    @acset_type StatesIBM(TheoryStatesIBM) <: AbstractStatesIBM

    # set up model
    SIR = StatesIBM{String, Int64, Int64}()

    initial_states = ["S", "I", "R", "S", "I", "R"]
    initial_statedynamic = [1,2,3,1,2,3]
    initial_statestatic = [1,1,1,2,2,2]
    state_labels = ["S", "I", "R"]
    initialize_states(SIR, initial_states, state_labels)

    add_parts!(SIR, :StateStatic, 2)
    set_subpart!(SIR, parts(SIR, :Person), :statestatic, initial_statestatic);

    add_parts!(SIR, :StateDynamic, 3)
    set_subpart!(SIR, parts(SIR, :Person), :current_statedynamic, initial_statedynamic);

    initial_attrstatic = [1,2,3,4,5,6]
    initial_attrdynamic = [7,8,9,10,11,12]

    set_subpart!(SIR, 1:6, :attrstatic, initial_attrstatic)
    set_subpart!(SIR, 1:6, :current_attrdynamic, initial_attrdynamic)

    # apply updates
    apply_queued_updates(SIR)

    @test subpart(SIR, :statestatic) == initial_statestatic
    @test subpart(SIR, :current_statedynamic) == initial_statedynamic
    @test subpart(SIR, :attrstatic) == initial_attrstatic
    @test subpart(SIR, :current_attrdynamic) == initial_attrdynamic
    @test nparts(SIR, :Current) == 6
    @test nparts(SIR, :Next) == 0

    queue_state_update(SIR, 1, "R")
    queue_state_update(SIR, 3, "S")

    @test nparts(SIR, :Next) == 2
    

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
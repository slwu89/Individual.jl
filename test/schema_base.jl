using individual.schema_base
using Catlab.ACSetInterface
using Test

@testset "construct model with integer initial states" begin

    initial_states = [1,2,3,1,2,3]
    state_labels = ["S", "I", "R"]

    SIR = IBM{String}()
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

    @test_throws BoundsError queue_state_update(SIR, 1, "X")
    queue_state_update(SIR, 1, "R")
    @test findfirst(x -> x == 3, subpart(SIR, :state_update)) == 1

    queue_state_update(SIR, 6, "S")
    @test findfirst(x -> x == 1, subpart(SIR, :state_update)) == 6

    apply_state_updates(SIR)

    new_state = initial_states
    new_state[1] = "R"
    new_state[6] = "S"
    @test subpart(SIR, :state) == indexin(new_state, state_labels)
    @test subpart(SIR, :state_update) == zeros(Int64, length(initial_states))

    reset_states(SIR, initial_states)
    @test subpart(SIR, :state) == indexin(initial_states, state_labels)

end

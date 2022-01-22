using individual.schema_base
using individual.schema_events
using Catlab.ACSetInterface
using Test

@testset "basic model construction with integer initial states works" begin

    initial_states = [1,2,3,1,2,3]
    state_labels = ["S", "I", "R"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
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

@testset "basic model construction with string initial states works" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
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

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

    initial_states = ["S", "I", "R", "S", "I", "R", "X"]
    @test_throws ArgumentError initialize_states(SIR, initial_states, state_labels)

end

@testset "events can be added to model" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
    initialize_states(SIR, initial_states, state_labels)

    function listener1(target, t::Int)
        queue_state_update(SIR, target, "R")
    end

    add_event(SIR, "Recovery", listener1)

    @test length(subpart(SIR, 1, :eventlistener)) == 1
    @test subpart(SIR, 1, :eventlistener) isa Vector{Function}
    @test subpart(SIR, 1, :eventlabel) == "Recovery"

    function listener2(target, t::Int)
        queue_state_update(SIR, target, "I")
    end

    add_event(SIR, "Infection", listener2)

    @test length(subpart(SIR, 2, :eventlistener)) == 1
    @test subpart(SIR, 2, :eventlistener) isa Vector{Function}
    @test subpart(SIR, 2, :eventlabel) == "Infection"

    function listener3(target, t::Int)
        queue_state_update(SIR, target[1], "I")
    end

    function listener4(target, t::Int)
        queue_state_update(SIR, target[2], "I")
    end

    add_event(SIR, "Infection1", listener3, listener4)

    @test length(subpart(SIR, 3, :eventlistener)) == 2
    @test subpart(SIR, 3, :eventlistener) isa Vector{Function}
    @test subpart(SIR, 3, :eventlabel) == "Infection1"

end

@testset "events can be scheduled, canceled, and fired" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R", "D"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
    initialize_states(SIR, initial_states, state_labels)

    function listener1(target, t::Int)
        queue_state_update(SIR, target, "R")
    end

    add_event(SIR, "Recovery", listener1)

    function listener2(target, t::Int)
        queue_state_update(SIR, target, "D")
    end

    add_event(SIR, "Death", listener2)

    schedule_event(SIR, 2:4, 3, "Recovery")

    @test get_scheduled(SIR, "Recovery") == 2:4
    @test subpart(SIR, :delay) == fill(3,3)
    @test subpart(SIR, :scheduled_to_event) == fill(1,3)

    clear_schedule(SIR, 3)
    @test get_scheduled(SIR, "Recovery") == [2,4]

    schedule_event(SIR, [1,5], [2,4], "Death")

    # tick 1
    event_tick(SIR)
    event_process(SIR, 1)
    apply_state_updates(SIR)
    @test subpart(SIR, :state) == indexin(initial_states, state_labels)

    # tick 2
    event_tick(SIR)
    event_process(SIR, 1)
    apply_state_updates(SIR)
    @test subpart(SIR, :state) == indexin(["D", "I", "R", "S", "I", "R"], state_labels)

    # tick 3
    event_tick(SIR)
    event_process(SIR, 1)
    apply_state_updates(SIR)
    @test subpart(SIR, :state) == indexin(["D", "R", "R", "R", "I", "R"], state_labels)

    # tick 4
    event_tick(SIR)
    event_process(SIR, 1)
    apply_state_updates(SIR)
    @test subpart(SIR, :state) == indexin(["D", "R", "R", "R", "D", "R"], state_labels)

end

@testset "events with multiple listeners work" begin

    initial_states = ["S", "S", "S", "S", "S", "S"]
    state_labels = ["S", "I", "R"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
    initialize_states(SIR, initial_states, state_labels)

    function listener1(target, t::Int)
        queue_state_update(SIR, target[1], "I")
    end

    function listener2(target, t::Int)
        queue_state_update(SIR, target[2], "I")
    end

    add_event(SIR, "Infection", listener1, listener2)

    schedule_event(SIR, [1,5,3], [0,0,0], "Infection")

    event_process(SIR, 1)
    apply_state_updates(SIR)

    @test subpart(SIR, :state) == indexin(["I", "S", "S", "S", "I", "S"], state_labels)

end

@testset "can clear all events" begin

    initial_states = ["S", "I", "R", "S", "I", "R"]
    state_labels = ["S", "I", "R", "D"]

    SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()
    initialize_states(SIR, initial_states, state_labels)

    function listener1(target, t::Int)
        queue_state_update(SIR, target, "R")
    end

    add_event(SIR, "Recovery", listener1)

    schedule_event(SIR, 2:4, 3, "Recovery")

    @test get_scheduled(SIR, "Recovery") == 2:4

    clear_schedule(SIR)

    @test length(get_scheduled(SIR, "Recovery")) == 0

end
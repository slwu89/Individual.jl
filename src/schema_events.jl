""" Define a schema and ACSet which allows for simulations that schedule events which occur
    after some time delay. When an event occurs, a function called an event listener is called
    on the subset of persons who were scheduled for that event, which may queue state updates or
    schedule further events. This allows simulation of processes with memory (i.e. non-Markovian models).
"""
module schema_events

export TheorySchedulingIBM, AbstractSchedulingIBM, SchedulingIBM,
    add_event, schedule_event, get_scheduled, clear_schedule,
    event_tick, event_process,
    simulation_loop

using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

using ..schema_base

""" A schema for an individual-based model inheriting from `TheoryIBM`
    which allows for events to be scheduled for persons.
"""
@present TheorySchedulingIBM <: TheoryIBM begin
    # set of events which occur after a timed delay
    Event::Ob
    Scheduled::Ob
    scheduled_to_event::Hom(Scheduled, Event)
    scheduled_to_person::Hom(Scheduled, Person)

    Delay::AttrType
    delay::Attr(Scheduled, Delay)

    # labels of events
    EventLabel::AttrType
    eventlabel::Attr(Event, EventLabel)

    # event listeners
    EventListener::AttrType
    eventlistener::Attr(Event, EventListener)
end

""" An abstract ACSet for an individual-based model inheriting from `AbstractIBM`
    which allows for events to be scheduled for persons.
"""
@abstract_acset_type AbstractSchedulingIBM <: AbstractIBM

""" 
A concrete ACSet for an individual-based model inheriting from `AbstractSchedulingIBM`
which allows for events to be scheduled for persons.
"""
@acset_type SchedulingIBM(TheorySchedulingIBM, index=[:state, :state_update, :scheduled_to_event, :scheduled_to_person]) <: AbstractSchedulingIBM

""" 
    add_event(model::AbstractSchedulingIBM, label::String, listeners...)

Add an event to the model, with name 'label',
"""
function add_event(model::AbstractSchedulingIBM, label::String, listeners...)
    !(label in subpart(model, :eventlabel)) || throw(ArgumentError("event with name 'label' already assigned in model"))
    listener_vec = Function[]
    for func = listeners
        push!(listener_vec, func)
    end
    add_parts!(model, :Event, 1, eventlabel = label, eventlistener = [listener_vec]);
end

""" 
    schedule_event(model::AbstractSchedulingIBM, target, delay, event)

Schedule a set of persons in `target` for the `event` after some `delay`. Note that `event` should correspond to an element
in the set `EventLabel` in your model.
"""
function schedule_event(model::AbstractSchedulingIBM, target, delay, event)
    add_parts!(model, :Scheduled, length(target), scheduled_to_person = target, delay = delay, scheduled_to_event = incident(model, event, :eventlabel))
end

""" 
    get_scheduled(model::AbstractSchedulingIBM, event)

Get the set of persons scheduled for `event`. Note that `event` should correspond to an element
in the set `EventLabel` in your model.
"""
function get_scheduled(model::AbstractSchedulingIBM, event)
    model[:scheduled_to_person][incident(model, event, [:scheduled_to_event, :eventlabel])]
end

""" 
    clear_schedule(model::AbstractSchedulingIBM, target)

Clear the persons in `target` from any events they are scheduled for.
If 'target' is not specified, clear all scheduled events.
"""
function clear_schedule(model::AbstractSchedulingIBM, target)
    rem_parts!(model, :Scheduled, incident(model, target, [:scheduled_to_person]))
end

function clear_schedule(model::AbstractSchedulingIBM)
    rem_parts!(model, :Scheduled, parts(model, :Scheduled))
end

""" 
    event_tick(model::AbstractSchedulingIBM)

Reduce all delays by 1, called at the end of a time step.
"""
function event_tick(model::AbstractSchedulingIBM)
    subpart(model, :delay) .-= 1
end

""" 
    event_process(model::AbstractSchedulingIBM, t::Int)

Process events which are ready to fire.
"""
function event_process(model::AbstractSchedulingIBM, t::Int)
# get every event ready to fire
ready_to_fire = incident(model, 0, :delay)
    if length(ready_to_fire) > 0
        # apply the event listener for each event type that is ready to fire
        for event = parts(model, :Event)
            fire_this_event = ready_to_fire[model[:scheduled_to_event][ready_to_fire] .== event]
            fire_this_event = model[:scheduled_to_person][fire_this_event]
            # if individuals are scheduled for this event, fire all listeners
            if length(fire_this_event) > 0
                for listener = subpart(model, event, :eventlistener)
                    listener(fire_this_event, t)
                end
            end
        end
        # remove people whose events have fired    
        rem_parts!(model, :Scheduled, ready_to_fire)
    end
end

""" 
    simulation_loop(model::AbstractSchedulingIBM, processes::Union{Function, AbstractVector{Function}}, steps::Integer)

A simple predefined simulation loop for individual based models with event scheduling. Processes are called first,
followed by event listeners, and finally state updates.
"""
function simulation_loop(model::AbstractSchedulingIBM, processes::Union{Function, AbstractVector{Function}}, steps::Integer)
    if processes isa Function
        processes = [processes]
    end
    for t = 1:steps
        for p = processes
            p(t)
        end
        event_process(model, t)
        event_tick(model)
        apply_state_updates(model)
    end
end


end
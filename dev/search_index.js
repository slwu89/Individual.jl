var documenterSearchIndex = {"docs":
[{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"EditURL = \"https://github.com/slwu89/individual.jl/blob/master/examples/sir-basic.jl\"","category":"page"},{"location":"examples/sir-basic/#sir_basic","page":"Basic SIR example","title":"Basic SIR example","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"Sean L. Wu (@slwu89), 2021-1-8","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"using individual.sampling\nusing individual.schema_base\n\nusing Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs\nusing Plots, GraphViz","category":"page"},{"location":"examples/sir-basic/#Introduction","page":"Basic SIR example","title":"Introduction","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"The SIR (Susceptible-Infected-Recovered) model is the \"hello, world!\" model of for infectious disease simulations, and here we describe how to use the basic schema for Markov models to build it in individual.jl. We only use the base TheoryIBM schema, because the model is a Markov chain. This tutorial largely mirrors the SIR model tutorial from the R package \"individual\", which inspired individual.jl.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"The schema looks like this:","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"to_graphviz(TheoryIBM)","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"There are morphisms from the set Person into State. The first, state gives the current state of each individual in the simulation. The second state_update is where state updates can be queued; at the end of a time step, state is swapped with state_update and state_update is reset. This ensures that state updates obey a FIFO order, and that individuals update synchronously.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"There is also a set of labels for states to make it easier to write self-documenting models.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"The basic schema could be extended with further Attrs if needing to model individual level heterogeneity, like immmune respose, etc.","category":"page"},{"location":"examples/sir-basic/#Parameters","page":"Basic SIR example","title":"Parameters","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"To start, we should define some parameters. The epidemic will be simulated in a population of 1000, where 5 persons are initially infectious, whose indices are randomly sampled. The effective contact rate β will be a function of the deterministic R0 and recovery rate γ. We also specify dt, which is the size of the time step (Δt). Because individual’s time steps are all of unit length, we scale transition probabilities by dt to create models with different sized steps, interpreting the discrete time model as a discretization of a continuous time model. If the maximum time is tmax then the overall number of time steps is tmax/dt.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"N = 1000\nI0 = 5\nS0 = N - I0\nΔt = 0.1\ntmax = 100\nsteps = Int(tmax/Δt)\nγ = 1/10 # recovery rate\nR0 = 2.5\nβ = R0 * γ # R0 for corresponding ODEs\n\ninitial_states = fill(\"S\", N)\ninitial_states[rand(1:N, I0)] .= \"I\"\nstate_labels = [\"S\", \"I\", \"R\"];\nnothing #hide","category":"page"},{"location":"examples/sir-basic/#Model-object","page":"Basic SIR example","title":"Model object","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"SIR = IBM{String}()\ninitialize_states(SIR, initial_states, state_labels)","category":"page"},{"location":"examples/sir-basic/#Processes","page":"Basic SIR example","title":"Processes","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"In order to model infection, we need a process. This is a function that takes only a single argument, t, for the current time step (unused here, but can model time-dependent processes, such as seasonality or school holiday). Within the function, we get the current number of infectious individuals, then calculate the per-capita force of infection on each susceptible person, λ=βI/N. Next we get the set of susceptible individuals and use the sample method to randomly select those who will be infected on this time step. The probability is given by $ 1- e^{-\\lambda \\Delta t} $. The method bernoulli_sample will automatically calculate that probability when given 3 arguments. Finally, we queue a state update for those individuals who were sampled.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"function infection_process(t::Int)\n    I = npeople(SIR, \"I\")\n    N = npeople(SIR)\n    λ = β * I/N\n    S = get_index_state(SIR, \"S\")\n    S = bernoulli_sample(S, λ, Δt)\n    queue_state_update(SIR, S, \"I\")\nend","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"The recovery process is simpler, as the per-capita transition probability from I to R does not depend on the state of the system.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"function recovery_process(t::Int)\n    I = get_index_state(SIR, \"I\")\n    I = bernoulli_sample(I, γ, Δt)\n    queue_state_update(SIR, I, \"R\")\nend","category":"page"},{"location":"examples/sir-basic/#Simulation","page":"Basic SIR example","title":"Simulation","text":"","category":"section"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"We draw a trajectory and plot the results.","category":"page"},{"location":"examples/sir-basic/","page":"Basic SIR example","title":"Basic SIR example","text":"out = Array{Int64}(undef, steps, 3)\n\nfor t = 1:steps\n    infection_process(t)\n    recovery_process(t)\n    out[t, :] = output_states(t, SIR)\n    apply_state_updates(SIR)\nend\n\nplot(\n    (1:steps) * Δt,\n    out,\n    label=[\"S\" \"I\" \"R\"],\n    xlabel=\"Time\",\n    ylabel=\"Number\"\n)","category":"page"},{"location":"api/#ref_api","page":"Library Reference","title":"API reference","text":"","category":"section"},{"location":"api/#Basic-schema","page":"Library Reference","title":"Basic schema","text":"","category":"section"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"Functions to create basic Markov individual-based models (IBM).","category":"page"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"individual.schema_base.TheoryIBM\nindividual.schema_base.AbstractIBM\nindividual.schema_base.IBM\nindividual.schema_base.npeople\nindividual.schema_base.nstate\nindividual.schema_base.statelabel\nindividual.schema_base.get_index_state\nindividual.schema_base.queue_state_update\nindividual.schema_base.apply_state_updates\nindividual.schema_base.output_states\nindividual.schema_base.initialize_states\nindividual.schema_base.reset_states","category":"page"},{"location":"api/#individual.schema_base.TheoryIBM","page":"Library Reference","title":"individual.schema_base.TheoryIBM","text":"ACSet definition for a basic individual-based model     See Catlab.jl documentation for description of the @present syntax.\n\n\n\n\n\n","category":"constant"},{"location":"api/#individual.schema_base.AbstractIBM","page":"Library Reference","title":"individual.schema_base.AbstractIBM","text":"An abstract ACSet for a basic Markov individual-based model inheriting from AbstractIBM     which allows for events to be scheduled for persons.\n\n\n\n\n\n","category":"type"},{"location":"api/#individual.schema_base.npeople","page":"Library Reference","title":"individual.schema_base.npeople","text":"npeople(model::AbstractIBM, states)\n\nReturn the number of people in some set of `states` (an element of the State Ob).\nIf called without the argument `states`, simply return the total population size.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.nstate","page":"Library Reference","title":"individual.schema_base.nstate","text":"nstate(model::AbstractIBM)\n\nReturn the size of the finite state space.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.statelabel","page":"Library Reference","title":"individual.schema_base.statelabel","text":"statelabel(model::AbstractIBM)\n\nReturn the labels (names) of the states in the finite state space.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.get_index_state","page":"Library Reference","title":"individual.schema_base.get_index_state","text":"getindexstate(model::AbstractIBM, states)\n\nReturn an integer vector giving the persons who are in the states specified in `states`.\nIf called without the argument `states`, simply return everyone's index.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.queue_state_update","page":"Library Reference","title":"individual.schema_base.queue_state_update","text":"queuestateupdate(model::AbstractIBM, persons, state)\n\nFor persons specified in `persons`, queue a state update to `state`, which will be applied at the\nend of the time step.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.apply_state_updates","page":"Library Reference","title":"individual.schema_base.apply_state_updates","text":"applystateupdates(model::AbstractIBM)\n\nApply all queued state updates.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.output_states","page":"Library Reference","title":"individual.schema_base.output_states","text":"output_states(t::Int, model::AbstractIBM)\n\nReturn a vector counting the number of persons in each state.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.initialize_states","page":"Library Reference","title":"individual.schema_base.initialize_states","text":"initializestates(model::AbstractIBM, initialstates, state_labels::Vector{String})\n\nInitialize the categorical states of a model. The argument `initial_states` can either\nbe provided as a vector of integers, corresponding to the internal storage of the ACSet,\nor as a vector of strings. It should be equal in length to the population which is to be\nsimulated.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_base.reset_states","page":"Library Reference","title":"individual.schema_base.reset_states","text":"initializestates(model::AbstractIBM, initialstates)\n\nReset a model's categorical states.\n\n\n\n\n\n","category":"function"},{"location":"api/#Event-scheduling-schema","page":"Library Reference","title":"Event scheduling schema","text":"","category":"section"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"Create IBMs with event scheduling capabilities.","category":"page"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"individual.schema_events.TheorySchedulingIBM\nindividual.schema_events.AbstractSchedulingIBM\nindividual.schema_events.SchedulingIBM\nindividual.schema_events.schedule_event\nindividual.schema_events.get_scheduled\nindividual.schema_events.clear_schedule\nindividual.schema_events.event_tick\nindividual.schema_events.event_process","category":"page"},{"location":"api/#individual.schema_events.TheorySchedulingIBM","page":"Library Reference","title":"individual.schema_events.TheorySchedulingIBM","text":"A schema for an individual-based model inheriting from TheoryIBM     which allows for events to be scheduled for persons.\n\n\n\n\n\n","category":"constant"},{"location":"api/#individual.schema_events.AbstractSchedulingIBM","page":"Library Reference","title":"individual.schema_events.AbstractSchedulingIBM","text":"An abstract ACSet for an individual-based model inheriting from AbstractIBM     which allows for events to be scheduled for persons.\n\n\n\n\n\n","category":"type"},{"location":"api/#individual.schema_events.schedule_event","page":"Library Reference","title":"individual.schema_events.schedule_event","text":"schedule_event(model::AbstractSchedulingIBM, target, delay, event)\n\nSchedule a set of persons in `target` for the `event` after some `delay`. Note that `event` should correspond to an element\nin the set `EventLabel` in your model.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_events.get_scheduled","page":"Library Reference","title":"individual.schema_events.get_scheduled","text":"get_scheduled(model::AbstractSchedulingIBM, event)\n\nGet the set of persons scheduled for `event`. Note that `event` should correspond to an element\n    in the set `EventLabel` in your model.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_events.clear_schedule","page":"Library Reference","title":"individual.schema_events.clear_schedule","text":"clear_schedule(model::AbstractSchedulingIBM, target)\n\nClear the persons in `target` from any events they are scheduled for.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_events.event_tick","page":"Library Reference","title":"individual.schema_events.event_tick","text":"event_tick(model::AbstractSchedulingIBM)\n\nReduce all delays by 1, called at the end of a time step.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.schema_events.event_process","page":"Library Reference","title":"individual.schema_events.event_process","text":"event_process(model::AbstractSchedulingIBM, t::Int)\n\nProcess events which are ready to fire.\n\n\n\n\n\n","category":"function"},{"location":"api/#Sampling","page":"Library Reference","title":"Sampling","text":"","category":"section"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"Methods for sampling random variates commonly used in IBMs.","category":"page"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"individual.sampling.delay_sample\nindividual.sampling.bernoulli_sample\nindividual.sampling.choose","category":"page"},{"location":"api/#individual.sampling.delay_sample","page":"Library Reference","title":"individual.sampling.delay_sample","text":"delay_sample(n::Integer, rate::AbstractFloat, dt::AbstractFloat)\n\nSample time steps until an event fires given a rate and dt.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.sampling.bernoulli_sample","page":"Library Reference","title":"individual.sampling.bernoulli_sample","text":"bernoulli_sample(target::AbstractVector, prob::AbstractFloat)\n\nSample without replacement from target with success probability prob.\n\n\n\n\n\nbernoulli_sample(target::AbstractVector, rate::AbstractFloat, dt::AbstractFloat)\n\nSample without replacement from target with success probability calculated from 1 - e^-mathrmrate * mathrmdt\n\n\n\n\n\nbernoulli_sample(target::AbstractVector{T}, prob::Vector)\n\nSample without replacement from target where each element has a unique success probability  given in the vector prob.\n\n\n\n\n\nbernoulli_sample(target::AbstractVector{T}, rate::Vector, dt::AbstractFloat)\n\nSample without replacement from target where each element's success probability is calculated from 1 - e^-mathrmrate * mathrmdt.\n\n\n\n\n\n","category":"function"},{"location":"api/#individual.sampling.choose","page":"Library Reference","title":"individual.sampling.choose","text":"choose(target::T, K::Integer)\n\nReturn a vector of size K with that number of random elements selected without replacement from target.\n\n\n\n\n\n","category":"function"},{"location":"#Introduction","page":"individual.jl","title":"Introduction","text":"","category":"section"},{"location":"","page":"individual.jl","title":"individual.jl","text":"individual.jl is a Julia package for specifying and simulating individual based models (IBMs), which relies on Catlab.jl, especially attributed C-Sets to create schemas which can represent a broad class of IBMs useful for epidemiology, ecology, and the computational social sciences. It is inspired by the R software individual.","category":"page"},{"location":"#Documentation","page":"individual.jl","title":"Documentation","text":"","category":"section"},{"location":"","page":"individual.jl","title":"individual.jl","text":"For tutorials on how to use the software, see the examples:","category":"page"},{"location":"","page":"individual.jl","title":"individual.jl","text":"SIR model tutorial here\nSIR model using event scheduling here","category":"page"},{"location":"","page":"individual.jl","title":"individual.jl","text":"Exported objects are documented at the API reference.","category":"page"},{"location":"#Contributing","page":"individual.jl","title":"Contributing","text":"","category":"section"},{"location":"","page":"individual.jl","title":"individual.jl","text":"blah","category":"page"},{"location":"#Acknowledgements","page":"individual.jl","title":"Acknowledgements","text":"","category":"section"},{"location":"","page":"individual.jl","title":"individual.jl","text":"individual.jl is written and maintained by Sean L. Wu (@slwu89).","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"EditURL = \"https://github.com/slwu89/individual.jl/blob/master/examples/sir-scheduling.jl\"","category":"page"},{"location":"examples/sir-scheduling/#sir_scheduling","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"Sean L. Wu (@slwu89), 2021-1-9","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"using individual.sampling\nusing individual.schema_base\nusing individual.schema_events\n\nusing Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs\nusing Plots, GraphViz","category":"page"},{"location":"examples/sir-scheduling/#Introduction","page":"SIR example with event scheduling","title":"Introduction","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"This tutorial shows how to simulate the SIR model using the event scheduling schema available in individual.jl. The stochastic process being simulated is exactly the same as the basic Markov SIR model tutorial, and all parameters are identical, so please see that tutorial for reference if needed.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The schema looks like this:","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"to_graphviz(TheorySchedulingIBM)","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The schema expands on the basic TheoryIBM for Markov models; the relationship between states and people is the same. There is a set of Events, which in epidemiological models might correspond to recovery, hospitalization, death, etc. Each event has a label for writing self-documenting models, and an EventListener, which can be used to store functions called \"event listeners\" which are called with the set of persons scheduled for that event on that timestep, and may queue state updates, and schedule or cancel other events.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The set of scheduled (queued) events is also a set Scheduled, with morphisms into the set of events and persons, and a delay Attr. For each queued event these tell us which event will occur, who it will happen to, and after how many timesteps it (the event listener) should fire.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"If we had additional combinatorial data describing each person (e.g. discrete age bin for each person), we could make another set and a morphism from people to that set. Additional atomic data for each person (e.g. neutralizing antibody titre) would be an Attr of people. In this way we can simulate a general class of individual based models relevant to epidemiology, ecology, and the social sciences.","category":"page"},{"location":"examples/sir-scheduling/#Parameters","page":"SIR example with event scheduling","title":"Parameters","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"N = 1000\nI0 = 5\nS0 = N - I0\nΔt = 0.1\ntmax = 100\nsteps = Int(tmax/Δt)\nγ = 1/10 # recovery rate\nR0 = 2.5\nβ = R0 * γ # R0 for corresponding ODEs\n\ninitial_states = fill(1, N)\ninitial_states[rand(1:N, I0)] .= 2\nstate_labels = [\"S\", \"I\", \"R\"];\nnothing #hide","category":"page"},{"location":"examples/sir-scheduling/#Model-object","page":"SIR example with event scheduling","title":"Model object","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"SIR = SchedulingIBM{String, Int64, String, Vector{Function}}()\ninitialize_states(SIR, initial_states, state_labels)","category":"page"},{"location":"examples/sir-scheduling/#Processes","page":"SIR example with event scheduling","title":"Processes","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The infection process is the same as the basic SIR model.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"function infection_process(t::Int)\n    I = npeople(SIR, \"I\")\n    N = npeople(SIR)\n    λ = β * I/N\n    S = get_index_state(SIR, \"S\")\n    S = bernoulli_sample(S, λ, Δt)\n    queue_state_update(SIR, S, \"I\")\nend","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The recovery process is queues future recovery events. We first find who is infected, and then take the set difference of those persons with those who are already scheduled for recovery, which is just the set of persons who need a recovery scheduled.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"function recovery_process(t::Int)\n\n    I = get_index_state(SIR, \"I\")\n    already_scheduled = get_scheduled(SIR, \"Recovery\")\n    to_schedule = setdiff(I, already_scheduled)\n\n    if length(to_schedule) > 0\n        rec_times = delay_sample(length(to_schedule), γ, Δt)\n        schedule_event(SIR, to_schedule, rec_times, \"Recovery\")\n    end\nend","category":"page"},{"location":"examples/sir-scheduling/#Events","page":"SIR example with event scheduling","title":"Events","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"The event listener associated with recovery is quite simple, just updating the state to R. We create an event with the label \"Recovery\" and a single listener, and add it to the model.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"function recovery_listener(target, t::Int)\n    queue_state_update(SIR, target, \"R\")\nend\n\nrecovery_listeners = Function[]\npush!(recovery_listeners, recovery_listener)\nadd_parts!(SIR, :Event, 1, eventlabel = \"Recovery\", eventlistener = [recovery_listeners]);\nnothing #hide","category":"page"},{"location":"examples/sir-scheduling/#Simulation","page":"SIR example with event scheduling","title":"Simulation","text":"","category":"section"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"We draw a trajectory and plot the results.","category":"page"},{"location":"examples/sir-scheduling/","page":"SIR example with event scheduling","title":"SIR example with event scheduling","text":"out = Array{Int64}(undef, steps, 3)\n\nfor t = 1:steps\n    infection_process(t)\n    recovery_process(t)\n    event_process(SIR, t)\n    event_tick(SIR)\n    out[t, :] = output_states(t, SIR)\n    apply_state_updates(SIR)\nend\n\nplot(\n    (1:steps) * Δt,\n    out,\n    label=[\"S\" \"I\" \"R\"],\n    xlabel=\"Time\",\n    ylabel=\"Number\"\n)","category":"page"}]
}

# # [Basic SIR example](@id sir_basic)
# Sean L. Wu (@slwu89), 2021-1-8

using Individual.Sampling
using Individual.SchemaBase

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs
using Plots
using GraphViz

# ## Introduction
# The SIR (Susceptible-Infected-Recovered) model is the "hello, world!" model of for infectious disease simulations, 
# and here we describe how to use the basic schema for Markov models to build it in Individual.jl. We only use the
# base `TheoryIBM` schema, because the model is a Markov chain. This tutorial largely mirrors the SIR model tutorial from
# the [R package "individual"](https://mrc-ide.github.io/individual/articles/Tutorial.html), which inspired individual.jl.

# For more information about the SIR model and stochastic epidemic models in general, please see ["A primer on stochastic epidemic models: Formulation, numerical simulation, and analysis"](https://doi.org/10.1016/j.idm.2017.03.001).

# The schema looks like this:

to_graphviz(TheoryIBM)

# There are morphisms from the object `Person` into `State`. The first, `state` gives the current state of each individual in the
# simulation. The second `state_update` is where state updates can be queued; at the end of a time step, `state` is swapped
# with `state_update` and `state_update` is reset. This ensures that state updates obey a FIFO order, and that individuals
# update synchronously.

# There are also labels for states to make it easier to write self-documenting models.

# The basic schema could be extended with further `Attr`s if needing to model individual level heterogeneity, like immmune respose, etc.

# When extending the schema with combinatorial states (i.e. categorical states, like further stratification of compartments), these are best
# set up as more objects `Ob` in your schema, which should inherit from `TheoryIBM` or `TheorySchedulingIBM` (see the article ["SIR example with age structure"](@ref sir_age) for an example of extending a schema).
# You might want to add `Attr` (attributes) to your schema if each person in your simulation has associated atomic data, such as floating point (real) variables, 
# of more complex data structures associated with them. In either case, if the added object or attribute is not static, add a duplicate `Hom` or `Attr`
# with the same name but ending in `_update`. That was `simulation_loop` knows to grab copy the "\_update" object or attribute into the 
# one containins the current state at the end of the time step. For example, you might add another `Ob` "risk", and "risk_update", to which
# you could add updates using the ACSet interface function `set_subpart!`.

# ## Parameters

# To start, we should define some parameters. The epidemic will be simulated in a population of 1000, where 8 persons are initially infectious, whose indices are randomly sampled. 
# The effective contact rate β will be a function of the deterministic R0 and recovery rate γ. We also specify Δt, which is the size of the time step. 
# Because individual’s time steps are all of unit length, we scale transition probabilities by Δt to create models with different sized steps, interpreting the discrete time model as a discretization of a continuous time model. 
# If the maximum time is tmax then the overall number of time steps is tmax/Δt.

N = 1000
I0 = 8
S0 = N - I0
Δt = 0.1
tmax = 100
steps = Int(tmax/Δt)
γ = 1/10 # recovery rate
R0 = 2.5
β = R0 * γ # R0 for corresponding ODEs

initial_states = fill("S", N)
initial_states[rand(1:N, I0)] .= "I"
state_labels = ["S", "I", "R"];

# ## Model object

# The "IBM" (Individual Based Model) schema needs the type parameter `String` because it defines a
# single attribute, that giving names to the categorical set of states.  

const SIR = IBM{String}()
initialize_states(SIR, initial_states, state_labels);

# ## Processes

# In order to model infection, we need a process. This is a function that takes only a single argument, `t`, for the current time step (unused here, but can model time-dependent processes, such as seasonality or school holiday). 
# Within the function, we get the current number of infectious individuals, then calculate the per-capita force of infection on each susceptible person, λ=βI/N. 
# Next we get the set of susceptible individuals and use the sample method to randomly select those who will be infected on this time step. 
# The probability is given by $$ 1- e^{-\lambda \Delta t} $$. The method `bernoulli_sample` will automatically calculate that probability when given 3 arguments. Finally, we queue a state update for those individuals who were sampled.

function infection_process(t::Int)
    I = npeople(SIR, "I")
    N = npeople(SIR)
    λ = β * I/N
    S = get_index_state(SIR, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR, S, "I")
end

# The recovery process is simpler, as the per-capita transition probability from I to R does not depend on the state of the system.

function recovery_process(t::Int)
    I = get_index_state(SIR, "I")
    I = bernoulli_sample(I, γ, Δt)
    queue_state_update(SIR, I, "R")
end

# ## Simulation

# We use `render_process` to create a rendering (output) process and 
# a matrix giving state counts by time step. 

# Then we draw a trajectory using `simulation_loop` and plot the results.
# Please note that `simulation_loop` is a simple wrapper around the correct updating order
# and that a user can always write a simple for loop to update the model. 

state_out, render_process = render_states(SIR, steps)

simulation_loop(SIR, [infection_process, recovery_process, render_process], steps)

plot(
    (1:steps) * Δt,
    state_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)

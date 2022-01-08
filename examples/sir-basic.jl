# # [Basic SIR example](@id sir_basic)
#

using individual.sampling
using individual.schema_base

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs

# ## Introduction
# The SIR (Susceptible-Infected-Recovered) model is the "hello, world!" model of for infectious disease simulations, 
# and here we describe how to use the basic schema for Markov models to build it in individual.jl. We only use the
# base `TheoryIBM` schema, because the model is a Markov chain.

# The schema looks like this:

to_graphviz(TheoryIBM)

# There are morphisms from the set `Person`` into `State`. The first, `state` gives the current state of each individual in the
# simulation. The second `state_update`` is where state updates can be queued; at the end of a time step, `state` is swapped
# with `state_update` and `state_update` is reset. This ensures that state updates obey a FIFO order, and that individuals
# update synchronously.

# There is also a set of labels for states to make it easier to write self-documenting models.

## Parameters

# We run the model with a population of 1000 persons, 5 of whom are initially infected. 
# Our time step size is Δt=0.1, which is used to scale transition probabilities.

N = 1000
I0 = 5
S0 = N - I0
dt = 0.1
tmax = 100
steps = Int(tmax/dt)
gamma = 1/10 # recovery rate
R0 = 2.5
beta = R0 * gamma # R0 for corresponding ODEs

# initial conditions
# S = 1, I = 2, R = 3
health_states = fill(1, N)
health_states[rand(1:N, I0)] .= 2
health_labels = ["S", "I", "R"]

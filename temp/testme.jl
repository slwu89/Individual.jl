using Individual.Sampling
using Individual.SchemaBase

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs
using Plots
using Random

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

SIR_normal = IBM{String}()
SIR_generated = IBM{String}()

initialize_states(SIR_normal, initial_states, state_labels);
initialize_states(SIR_generated, initial_states, state_labels);

# ## Processes : normal

function infection_process(t::Int)
    I = npeople(SIR_normal, "I")
    N = npeople(SIR_normal)
    λ = β * I/N
    S = get_index_state(SIR_normal, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR_normal, S, "I")
end

function recovery_process(t::Int)
    I = get_index_state(SIR_normal, "I")
    I = bernoulli_sample(I, γ, Δt)
    queue_state_update(SIR_normal, I, "R")
end

state_out, render_process = render_states(SIR_normal, steps)

# Processes : generated

function infection_process_generated(t::Int)
    I = npeople(SIR_generated, "I")
    N = npeople(SIR_generated)
    λ = β * I/N
    S = get_index_state(SIR_generated, "S")
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR_generated, S, "I")
end

function recovery_process_generated(t::Int)
    I = get_index_state(SIR_generated, "I")
    I = bernoulli_sample(I, γ, Δt)
    queue_state_update(SIR_generated, I, "R")
end

state_out_generated, render_process_generated = render_states(SIR_generated, steps)

# sim normal

Random.seed!(93242358)

for t = 1:steps
    infection_process(t)
    recovery_process(t)
    render_process(t)
    apply_state_updates(SIR_normal)
end

plot(
    (1:steps) * Δt,
    state_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)

# sim generated

Random.seed!(93242358)

for t = 1:steps
    infection_process_generated(t)
    recovery_process_generated(t)
    render_process_generated(t)
    SchemaBase.test_update_Ob(SIR_generated)
end

plot(
    (1:steps) * Δt,
    state_out_generated,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)

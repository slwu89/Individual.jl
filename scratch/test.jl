using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

# for graphics
using Catlab.Graphics, Catlab.Graphs
using Plots
using GraphViz

# sample
using StatsBase


@present TheoryMarkovIBM(FreeSchema) begin
  Person::Ob
  CurrentInstance::Ob
  NextInstance::Ob

  State::Ob # allow the user to have many states

  current::Hom(Person, CurrentInstance)
  next::Hom(Person, NextInstance)
  
  current_state::Hom(CurrentInstance, State)
  next_state::Hom(NextInstance, State)

  StateLabel::AttrType
  statelabel::Attr(State, StateLabel)
end

@abstract_acset_type AbstractIBM

# current_state and next_state are *not* uniquely indexed because it is a many to one mapping (e.g. many people can be S)
@acset_type MarkovIBM(TheoryMarkovIBM, index = [:current_state, :next_state], unique_index = [:statelabel, :current, :next]) <: AbstractIBM

# @acset_type MarkovIBM(TheoryMarkovIBM, index = [:current_state, :next_state, :current, :next], unique_index = [:statelabel]) <: AbstractIBM

# to_graphviz(TheoryMarkovIBM)

N = 15
I = 5
R = 3
idx = sample(1:N, I+R, replace = false)

initial_states = fill("S", N)
initial_states[idx[1:I]] .= "I"
initial_states[idx[I+1:end]] .= "R"
state_labels = ["S", "I", "R"];

initial_states_int = indexin(initial_states, state_labels)


SIR = MarkovIBM{String}()

# add states and labels
add_parts!(SIR, :State, 3, statelabel = state_labels)

# add people, add to Person ob
add_parts!(SIR, :Person, N)

# add current state of persons (current instance)
add_parts!(SIR, :CurrentInstance, N)
set_subpart!(SIR, 1:N, :current_state, initial_states_int)

# set the current state of Person to those CurrentInstance s
set_subpart!(SIR, 1:N, :current, 1:N)


# set_subpart!(SIR, 1:N, :current, fill(0, N))



# example for Catlab zulip
@present ExSchema(FreeSchema) begin
    Ob1::Ob
    Ob2::Ob
    Fn::Hom(Ob1, Ob2)
end

@acset_type Example(ExSchema, unique_index = [:Fn])

ExampleInstance = Example()

add_parts!(ExampleInstance, :Ob1, 5)
add_parts!(ExampleInstance, :Ob2, 4)

set_subpart!(ExampleInstance, 1:3, :Fn, 2:4)

incident(ExampleInstance, 1, :Fn)
set_subpart!(ExampleInstance, 2, :Fn, 0)


@acset_type ExampleNoUnique(ExSchema, index = [:Fn])

ExampleNoUniqueInstance = ExampleNoUnique()

add_parts!(ExampleNoUniqueInstance, :Ob1, 5)
add_parts!(ExampleNoUniqueInstance, :Ob2, 4)

set_subpart!(ExampleNoUniqueInstance, 1:3, :Fn, 2:4)

incident(ExampleNoUniqueInstance, 1, :Fn)
set_subpart!(ExampleNoUniqueInstance, 2, :Fn, 0)

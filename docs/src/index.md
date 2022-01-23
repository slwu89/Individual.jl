## Introduction

individual.jl is a Julia package for specifying and simulating individual based models (IBMs), using applied category theory. The package relies on
[Catlab.jl](https://algebraicjulia.github.io/Catlab.jl/stable/), especially attributed C-Sets to
create schemas which can represent a broad class of IBMs useful for epidemiology, ecology, and the computational
social sciences. It is inspired by the R software [individual](https://mrc-ide.github.io/individual/).

## Documentation

For tutorials on how to use the software, see the examples:

- start by reading a basic SIR model tutorial [here](@ref sir_basic)
- read about using event scheduling for events which occur after a non-Geometric delay with an SIR model using event scheduling [here](@ref sir_scheduling)
- learn how to extend the types in indiviudal.jl with additional attributes, via a SIR model with age-structure [here](@ref sir_age)

The [API reference](@ref ref_api) contains information about objects and functions available to users.

## Design

individual.jl uses ACSets based on schemas to provide data structures well-suited for individual-based models. Every schema has the objects `Person` and `State`, and a morphism from people to states, and may have additional objects and morphisms as required to implement additional functionality, such as event scheduling. ACSets are the data structures that turn these rather abstract schemas into useful tools for computing with, and each schema in individual.jl comes with an associated ACSet type so that methods can be written for a type hierarchy. For more information about ACSets, please see the paper ["Categorical Data Structures for Technical Computing"](https://arxiv.org/abs/2106.04703) and the [AlgebraicJulia blog](https://www.algebraicjulia.org/blog).

### Simulation

Each time step follows a specific order of computation to build consistent models. First, functions called _processes_ are run, which take the current time step as an argument. These may query state, and queue state updates or schedule _events_, but cannot update state. Next (if being used) events are processed, meaning any event whose delay is currently `0` is "fired", and a set of associated functions called _event listeners_ is called for the set of persons experiencing that event. Much like processes, event listeners can queue state updates and schedule future events. Next, the delay on all events is decremented by one. Finally, all queued state updates are applied.

The simulation loop ensures that models in individual.jl follow a synchronous updating scheme (i.e. all state is updated simultaneously at the end of a time step).

## Contributing

### Issues

If you find a bug, have a question about how to use a feature that does not have sufficient documentation, or have a suggestion for improvement, please [leave an issue](https://github.com/slwu89/individual.jl/issues) at our GitHub repo.

For bug reports please include:

- individual.jl version
- Operating system
- Julia version
- Steps to recreate
- Expected behaviour
- Actual behaviour

## Acknowledgements

individual.jl is written and maintained by Sean L. Wu [(@slwu89)](https://github.com/slwu89).

We acknowledge help and advice from [Sophie Libkind](http://slibkind.github.io/) and [Evan Patterson](https://www.epatters.org/) regarding use of Catlab's ACSets. 
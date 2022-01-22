## Introduction

individual.jl is a Julia package for specifying and simulating individual based models (IBMs), which relies on
[Catlab.jl](https://algebraicjulia.github.io/Catlab.jl/stable/), especially attributed C-Sets to
create schemas which can represent a broad class of IBMs useful for epidemiology, ecology, and the computational
social sciences. It is inspired by the R software [individual](https://mrc-ide.github.io/individual/).

## Documentation

For tutorials on how to use the software, see the examples:

- SIR model tutorial [here](@ref sir_basic)
- SIR model using event scheduling [here](@ref sir_scheduling)
- SIR model with age-structure, demonstrating how to extend the ACSet types in individual.jl for more complex models [here](@ref sir_age)

The [API reference](@ref ref_api) contains information about objects and functions available to users.

## Contributing

blah

## Acknowledgements

individual.jl is written and maintained by Sean L. Wu [(@slwu89)](https://github.com/slwu89).
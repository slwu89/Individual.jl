# Individual.jl

<!-- badges start -->
[![Documentation](https://github.com/slwu89/Individual.jl/actions/workflows/docs.yml/badge.svg?branch=main)](https://slwu89.github.io/Individual.jl/dev/)
[![Tests](https://github.com/slwu89/Individual.jl/actions/workflows/tests.yml/badge.svg)](https://github.com/slwu89/Individual.jl/actions/workflows/tests.yml)
<!-- badges end -->

Individual.jl is a package which uses [Catlab.jl](https://algebraicjulia.github.io/Catlab.jl/stable/),
especially attributed C-Sets to create a set of data types and methods useful for building
individual-based epidemiological models. It is inspired by the R software [individual](https://mrc-ide.github.io/individual/).
Please read our [documentation website](https://slwu89.github.io/Individual.jl/dev/) to
learn more about the package.

## Installation

To install the version at the Julia general repository:

```
using Pkg
Pkg.add("Individual")
```

You can install directly from GitHub with:

```
using Pkg
Pkg.add(url="https://github.com/slwu89/Individual.jl")
```
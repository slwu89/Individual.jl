using Test

@testset "sampling" begin
  include("sampling.jl")
end

@testset "schema_base" begin
  include("schema_base.jl")
end

@testset "schema_events" begin
  include("schema_events.jl")
end
using Individual.Sampling
using Test

@testset "delay_geom_sample with scalar rate" begin

    @test length(delay_geom_sample(0, 1.0, 1.0)) == 0
    @test length(delay_geom_sample(10, 0.05, 1.0)) == 10

end

@testset "delay_geom_sample with vector rate" begin

    @test_throws ArgumentError delay_geom_sample(1, [1.0, 2.0], 1.0) 

    @test length(delay_geom_sample(1, [1.0], 1.0)) == 1
    @test length(delay_geom_sample(10, fill(0.5, 10), 1.0)) == 10

end

@testset "bernoulli_sample with vector target, vector prob" begin

    @test_throws ArgumentError bernoulli_sample([1,2,3], [0.5,0.5,0.5,0.5]) 
    @test_throws ArgumentError bernoulli_sample([1,2,3], Float64[])
    @test_throws ErrorException bernoulli_sample([1,2,3], [1.0, Inf, 0.5])

    @test length(bernoulli_sample([1,2,3], zeros(3))) == 0 
    @test length(bernoulli_sample([1,2,3], ones(3))) == 3 
    @test length(bernoulli_sample([1,2,3], [1.0,0.5,1.0])) ∈ [2,3]

end

@testset "bernoulli_sample with vector target, vector rate" begin
    @test_throws ArgumentError bernoulli_sample([1,2,3], [0.5,0.5,0.5,0.5], 1.0)
    @test_throws ArgumentError bernoulli_sample([1,2,3], [0.5, -999.0, 0.5], 1.0)
    @test_throws ArgumentError bernoulli_sample([1,2,3], Float64[], 1.0)

    @test length(bernoulli_sample([1,2,3], zeros(3), 1.0)) == 0 
    @test length(bernoulli_sample([1,2,3], fill(Inf, 3), 1.0)) == 3 
    @test length(bernoulli_sample([1,2,3], [Inf,1.0,Inf], 1.0)) ∈ [2,3]

end

@testset "bernoulli_sample with vector target, scalar prob" begin

    @test_throws ArgumentError bernoulli_sample([1,2,3], -5.0)

    @test length(bernoulli_sample([1], 0.0)) == 0 
    @test length(bernoulli_sample([1], 1.0)) == 1 

    @test length(bernoulli_sample([1,2,3], 0.0)) == 0 
    @test length(bernoulli_sample([1,2,3], 1.0)) == 3 

end

@testset "bernoulli_sample with vector target, scalar rate" begin

    @test_throws ArgumentError bernoulli_sample([1,2,3], -999.0, 1.0)

    @test length(bernoulli_sample([1,2,3], 0.0, 1.0)) == 0 
    @test length(bernoulli_sample([1,2,3], Inf, 1.0)) == 3 

    @test length(bernoulli_sample([1], 0.0, 1.0)) == 0 
    @test length(bernoulli_sample([1], Inf, 1.0)) == 1 

    @test bernoulli_sample([1,2,3], Inf, 1.0) == [1,2,3]

end

@testset "bernoulli_sample with scalar target, scalar prob" begin

    @test_throws ArgumentError bernoulli_sample(1, -5.0)

    @test length(bernoulli_sample(1, 0.0)) == 0
    @test length(bernoulli_sample(1, 1.0)) == 1
    @test bernoulli_sample(1, 1.0) == [1]

end

@testset "bernoulli_sample with scalar target, scalar rate" begin

    @test_throws ArgumentError bernoulli_sample(1, -999.0, 1.0)

    @test length(bernoulli_sample(1, 0.0, 1.0)) == 0 
    @test length(bernoulli_sample(1, Inf, 1.0)) == 1 

    @test bernoulli_sample(1, Inf, 1.0) == [1]

end
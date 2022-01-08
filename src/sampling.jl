""" Functions for the types of random variate draws often used in individual-based epidemiological models.
"""
module sampling

export bernoulli_sample, choose_sample

using Distributions: Exponential, cdf
using Random: randsubseq
using StatsBase: sample

function rate_to_prob(x::AbstractFloat) 
    0.0 <= x || throw(ArgumentError("rate $x not in [0,Inf)"))
    cdf(Exponential(), x)
end

""" bernoulli_sample(target::AbstractVector, prob::AbstractFloat)

Sample without replacement from `target` with success probability `prob`.
"""
function bernoulli_sample(target::T, prob::AbstractFloat) where {T <: Integer}
    0.0 <= prob <= 1.0 || throw(ArgumentError("probability $prob not in [0,1]"))
    if rand() < prob
        return [target]
    else
        return T[]
    end
end

function bernoulli_sample(target::AbstractVector, prob::AbstractFloat) 
    randsubseq(target, prob)
end

"""
    bernoulli_sample(target::AbstractVector, rate::AbstractFloat, dt::AbstractFloat)

Sample without replacement from `target` with success probability calculated
from ``1 - \\exp(-\\mathrm{rate} * \\mathrm{dt})``.
"""
function bernoulli_sample(target::T, rate::AbstractFloat, dt::AbstractFloat) where {T <: Integer}
    prob = rate_to_prob(rate * dt)
    if rand() < prob
        return [target]
    else
        return T[]
    end
end

function bernoulli_sample(target::AbstractVector, rate::AbstractFloat, dt::AbstractFloat)
    randsubseq(target, rate_to_prob(rate * dt))
end

""" bernoulli_sample(target::AbstractVector{T}, prob::Vector)

Sample without replacement from `target` where each element has a unique success probability 
given in the vector `prob`.
"""
function bernoulli_sample(target::AbstractVector{T}, prob::Vector) where {T <: Integer}
    length(target) == length(prob) || throw(ArgumentError("target and prob not of equal length"))
    samp = Vector{T}(undef, length(target))
    runif = rand(length(target))
    j = 0
    for i = 1:length(target)
        0.0 <= prob[i] <= 1.0 || throw(ErrorException("probability $(prob[i]) not in [0,1]"))
        @assert prob[i] <= 1.0 && prob[i] >= 0.0
        if runif[i] < prob[i]
            j += 1
            samp[j] = target[i]
        end
    end

    # return sampled set
    if j > 0
        return samp[1:j]
    else
        return T[]
    end
end

""" bernoulli_sample(target::AbstractVector{T}, rate::Vector, dt::AbstractFloat)

Sample without replacement from `target` where each element's success probability is calculated
from ``1 - \\exp(-\\mathrm{rate} * \\mathrm{dt})``.
"""
function bernoulli_sample(target::AbstractVector{T}, rate::Vector, dt::AbstractFloat) where {T <: Integer}
    length(target) == length(rate) || throw(ArgumentError("target and rate not of equal length"))
    prob = map((x) -> rate_to_prob(x), rate * dt)
    samp = Vector{T}(undef, length(target))
    runif = rand(length(target))
    j = 0
    for i = 1:length(target)
        if runif[i] < prob[i]
            j += 1
            samp[j] = target[i]
        end
    end

    # return sampled set
    if j > 0
        return samp[1:j]
    else
        return T[]
    end
end


""" choose_sample(target::T, K::Integer)

Return a vector of size `K` with that number of random elements selected
without replacement from `target`.
"""
function choose_sample(target::T, K::Integer) where {T <: Integer}
    if K > 0 # should K > 1 be an error?
        return target
    else
        return T[]
    end
end

function choose_sample(target::AbstractVector{T}, K::Integer) where {T <: Integer}
    if K > 0
        target[sample(1:length(target), K, replace = false)]
    else
        return T[]
    end
end

end # end module
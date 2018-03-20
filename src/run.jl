@doc doc"""
Lagged differencing

`diffn(x::Array{Float64}; n::Int64=1)::Array{Float64}`
""" ->
function diffn(x::Array{Float64}; n::Int64=1)::Array{Float64}
    @assert n<size(x,1) && n>0 "Argument n out of bounds."
    dx = zeros(x)
    dx[1:n] = NaN
    @inbounds for i=n+1:size(x,1)
        dx[i] = x[i] - x[i-n]
    end
    return dx
end

@doc doc"""
Lagged differencing

`diffn(X::Array{Float64,2}; n::Int64=1)::Array{Float64}`
""" ->
function diffn(X::Array{Float64,2}; n::Int64=1)::Matrix{Float64}
    @assert n<size(X,1) && n>0 "Argument n out of bounds."
    dx = zeros(X)
    @inbounds for j = 1:size(X,2)
        dx[:,j] = diffn(X[:,j], n=n)
    end
    return dx
end

@doc doc"""
(Adapted from StatsBase: https://raw.githubusercontent.com/JuliaStats/StatsBase.jl/master/src/scalarstats.jl)

`Compute the mode of an arbitrary array::Array{Float64}`
""" ->
function mode(a::AbstractArray{Float64})
    isempty(a) && error("mode: input array cannot be empty.")
    cnts = Dict{Float64,Int64}()
    # first element
    mc = 1
    mv = a[1]
    cnts[mv] = 1
    # find the mode along with table construction
    @inbounds for i = 2 : length(a)
        x = a[i]
        if haskey(cnts, x)
            c = (cnts[x] += 1)
            if c > mc
                mc = c
                mv = x
            end
        else
            cnts[x] = 1
            # in this case: c = 1, and thus c > mc won't happen
        end
    end
    return mv
end

@doc doc"""
Compute a running or rolling arithmetic mean of an array.

`runmean(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}`
""" ->
function runmean(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        fi = 1.0:size(x,1)
        @inbounds for i = n:size(x,1)
            out[i] = sum(x[1:i])/fi[i]
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = mean(x[i-n+1:i])
        end
    end
    return out
end


@doc doc"""
Compute a running or rolling summation of an array.

`runsum(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}`
""" ->
function runsum(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    if cumulative
        out = cumsum(x)
        out[1:n-1] = NaN
    else
        out = zeros(x)
        out[1:n-1] = NaN
        @inbounds for i = n:size(x,1)
            out[i] = sum(x[i-n+1:i])
        end
    end
	return out
end

@doc doc"""
Welles Wilder summation of an array

`wilder_sum(x::Array{Float64}; n::Int64=10)::Array{Float64}`
""" ->
function wilder_sum(x::Array{Float64}; n::Int64=10)::Array{Float64}
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    nf = float(n)  # type stability -- all arithmetic done on floats
    out = zeros(x)
    out[1] = x[1]
    @inbounds for i = 2:size(x,1)
        out[i] = x[i] + out[i-1]*(nf-1.0)/nf
    end
    return out
end

@doc doc"""
Compute the running or rolling mean absolute deviation of an array

`runmad(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, fun::Function=median)::Array{Float64}`
""" ->
function runmad(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, fun::Function=median)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    center = 0.0
    if cumulative
        fi = collect(1.0:size(x,1))
        @inbounds for i = n:size(x,1)
            center = fun(x[1:i])
            out[i] = sum(abs.(x[1:i]-center)) / fi[i]
        end
    else
        fn = float(n)
        @inbounds for i = n:size(x,1)
            center = fun(x[i-n+1:i])
            out[i] = sum(abs.(x[i-n+1:i]-center)) / fn
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling variance of an array

`runvar(x::Array{Float64}; n::Int64=10, cumulative=true)::Array{Float64}`
""" ->
function runvar(x::Array{Float64}; n::Int64=10, cumulative=true)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:size(x,1)
            out[i] = var(x[1:i])
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = var(x[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling standard deviation of an array

`runsd(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}`
""" ->
function runsd(x::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}
    return sqrt.(runvar(x, n=n, cumulative=cumulative))
end

@doc doc"""
Compute the running or rolling covariance of two arrays

`runcov(x::Array{Float64}, y::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}`
""" ->
function runcov(x::Array{Float64}, y::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cov(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cov(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling correlation of two arrays

`runcor(x::Array{Float64}, y::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}`
""" ->
function runcor(x::Array{Float64}, y::Array{Float64}; n::Int64=10, cumulative::Bool=true)::Array{Float64}
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cor(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cor(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling maximum of an array.

`runmax(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, inclusive::Bool=true)::Array{Float64}`
""" ->
function runmax(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, inclusive::Bool=true)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    if inclusive
        if cumulative
            out[n] = maximum(x[1:n])
            @inbounds for i = n+1:size(x,1)
                out[i] = max(out[i-1], x[i])
            end
        else
            @inbounds for i = n:size(x,1)
                out[i] = maximum(x[i-n+1:i])
            end
        end
        out[1:n-1] = NaN
        return out
    else
        if cumulative
            out[n+1] = maximum(x[1:n])
            @inbounds for i = n+1:size(x,1)-1
                out[i+1] = max(out[i-1], x[i-1])
            end
        else
            @inbounds for i = n:size(x,1)-1
                out[i+1] = maximum(x[i-n+1:i])
            end
        end
        out[1:n] = NaN
        return out
    end
end

@doc doc"""
Compute the running or rolling minimum of an array.

`runmin(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, inclusive::Bool=true)::Array{Float64}`
""" ->
function runmin(x::Array{Float64}; n::Int64=10, cumulative::Bool=true, inclusive::Bool=true)::Array{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(x)
    if inclusive
        if cumulative
            out[n] = minimum(x[1:n])
            @inbounds for i = n+1:size(x,1)
                out[i] = min(out[i-1], x[i])
            end
        else
            @inbounds for i = n:size(x,1)
                out[i] = minimum(x[i-n+1:i])
            end
        end
        out[1:n-1] = NaN
        return out
    else
        if cumulative
            out[n+1] = minimum(x[1:n])
            @inbounds for i = n+1:size(x,1)-1
                out[i+1] = min(out[i-1], x[i-1])
            end
        else
            @inbounds for i = n:size(x,1)-1
                out[i+1] = minimum(x[i-n+1:i])
            end
        end
        out[1:n] = NaN
        return out
    end
end

@doc doc"""
Compute the running/rolling quantile of an array.

`runquantile(x::Vector{Float64}; p::Vector{Float64}=[0.05,0.95], n::Int=10, cumulative::Bool=true)::Matrix{Float64}`
"""
function runquantile(x::Vector{Float64}; p::Vector{Float64}=[0.05,0.95], n::Int=10, cumulative::Bool=true)::Matrix{Float64}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    k = length(p)
    N = length(x)
    out = zeros(Float64, (length(x), k))
    if cumulative
        @inbounds for j in 1:k, i in 2:N
            out[i,j] = quantile(x[1:i], p[j])
        end
        out[1,:] = NaN
    else
        @inbounds for j in 1:k, i in n:N
            out[i,j] = quantile(x[i-n+1:i], p[j])
        end
        out[1:n-1,:] = NaN
    end
    return out
end

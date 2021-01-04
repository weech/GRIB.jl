# Structs and functions related to the codes_nearest type

export Nearest, find, findmultiple, destroy

mutable struct codes_nearest
end

struct Nearest
    ptr::Ptr{codes_nearest}
end

"""
    Nearest(handle::Message)

Create a Nearest from a Message.
"""
function Nearest(handle::Message)::Nearest
    eref = Ref(Int32(0))
    ptr = ccall((:codes_grib_nearest_new, eccodes), Ptr{codes_nearest},
                (Ptr{codes_handle}, Ref{Cint}), handle.ptr, eref)
    errorcheck(eref[])
    return Nearest(ptr)
end

"""
    Nearest(f::Function, handle::Message)

Create a Nearest from a Message and automatically destroy when finished.

# Example
```Julia
Nearest(handle) do near
    find(near, handle, inlat, inlon)
end
```
"""
function Nearest(f::Function, handle::Message)
    near = Nearest(handle)
    try
        f(near)
    finally
        destroy(near)
    end
end

"""
    find(near::Nearest, handle::Message, inlon::Float64, inlat::Float64; samepoint=true, samegrid=true)

Find the nearest 4 points to the given point sorted by distance.

Setting samepoint and samegrid to true (default) speeds up the calculation but restricts the point
and grid, respectively, from changing from call to call. Distance is in kilometers.

# Example
```Julia
Nearest(handle) do near
    lons, lats, values, distances = find(near, handle, inlon, inlat)
end
```
"""
function find(near::Nearest, handle::Message, inlon, inlat; samepoint=true, samegrid=true)
    flags = samepoint && samegrid ? CODES_NEAREST_SAME_POINT | CODES_NEAREST_SAME_GRID :
            samepoint ? CODES_NEAREST_SAME_POINT :
            samegrid ? CODES_NEAREST_SAME_GRID :
            UInt64(0)
    outlats = Vector{Float64}(undef, 4)
    outlons = similar(outlats)
    values = similar(outlats)
    distances = similar(outlats)
    indexes = Vector{Int32}(undef, 4)
    len = Csize_t(4)
    err = ccall((:codes_grib_nearest_find, eccodes), Cint,
                (Ptr{codes_nearest}, Ptr{codes_handle}, Cdouble, Cdouble, Culong,
                 Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ref{Csize_t}),
                near.ptr, handle.ptr, inlat, inlon, flags, outlats, outlons, values, distances,
                indexes, Ref(len))
    errorcheck(err)
    sorting = sortperm(distances)
    return outlons[sorting], outlats[sorting], values[sorting], distances[sorting]
end

"""
    findmultiple(handle::Message, inlons::Vector{Float64}, inlats::Vector{Float64}; islsm=false)

Find the nearest point to each point given.

Setting islsm to true finds the nearest land point and only works when `handle`
represents a land-sea-mask. Distance is in kilometers.

# Example
```Julia
lons, lats, values, distances = findmultiple(handle, inlons, inlats)
```
"""
function findmultiple(handle::Message, inlons::Vector{Float64}, inlats::Vector{Float64}; islsm=false)
    if length(inlats) != length(inlons)
        throw(DomainError("Length of inlats must be equal to length of inlons"))
    end
    npoints = Clong(length(inlats))
    outlats = similar(inlats)
    outlons = similar(inlats)
    outvals = similar(inlats)
    outdists = similar(inlats)
    outidx = Vector{Int32}(undef, npoints)
    intlsm = Int32(islsm)
    err = ccall((:codes_grib_nearest_find_multiple, eccodes), Cint,
                (Ptr{codes_handle}, Cint, Ref{Cdouble}, Ref{Cdouble}, Clong, Ref{Cdouble},
                 Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cint}),
                handle.ptr, intlsm, inlats, inlons, npoints, outlats, outlons,
                outvals, outdists, outidx)
    errorcheck(err)
    return outlons, outlats, outvals, outdists
end

""" Safely destroy a nearest object. """
function destroy(near::Nearest)::Nothing
    err = ccall((:codes_grib_nearest_delete, eccodes), Cint, (Ptr{codes_nearest},), near.ptr)
    errorcheck(err)
end
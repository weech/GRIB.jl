# Structs and functions related to the various iterators in eccodes

export eachpoint

mutable struct codes_keys_iterator
end

struct EachKey
    ptr::Ptr{codes_keys_iterator}
    msg::Message
end

function Base.iterate(iter::EachKey, state=())
    next = ccall((:codes_keys_iterator_next, eccodes), Cint, (Ptr{codes_keys_iterator},), iter.ptr)
    if next == 0
        destroy(iter)
        return nothing
    else
        element = ccall((:codes_keys_iterator_get_name, eccodes), Cstring,
                        (Ptr{codes_keys_iterator},),
                        iter.ptr)
        elestring = unsafe_string(element)

        # Skip unreadable keys and keys with unsupported types
        native = Tuple{}
        try
            native = getnativetype(iter.msg, elestring)
        catch e
            return iterate(iter, ())
        end
        if native == Tuple{}
            return iterate(iter, ())
        else
            return (elestring, ())
        end
    end
end

Base.IteratorSize(::Type{EachKey}) = Base.SizeUnknown()
Base.eltype(::Type{EachKey}) = String

function destroy(iter::EachKey)
    err = ccall((:codes_keys_iterator_delete, eccodes), Cint, (Ptr{codes_keys_iterator},), iter.ptr)
    errorcheck(err)
end

struct EachValue
    keyiter::EachKey
end

function Base.iterate(iter::EachValue, state=())
    ret = iterate(iter.keyiter)
    if isnothing(ret)
        nothing
    else
        (iter.keyiter.msg[ret[1]], ())
    end
end

Base.IteratorSize(::Type{EachValue}) = Base.SizeUnknown()

function Base.iterate(iter::Message, state=(keys(iter),))
    keyitr = state[1]
    ret = iterate(keyitr)
    if isnothing(ret)
        nothing
    else
        (ret[1] => iter[ret[1]], (keyitr,))
    end
end

Base.IteratorSize(::Type{Message}) = Base.SizeUnknown()
Base.eltype(::Type{Message}) = Pair{String, Any}

"""
    keys(message::Message)

Iterate through each key in the message.

# Example
```Julia
for key in keys(message)
    println(key)
end
```
"""
function Base.keys(handle::Message)
    ptr = ccall((:codes_keys_iterator_new, eccodes), Ptr{codes_keys_iterator},
          (Ptr{codes_handle}, Culong, Cstring), handle.ptr, CODES_KEYS_ITERATOR_ALL_KEYS, C_NULL)
    EachKey(ptr, handle)
end

"""
    values(message::Message)

Iterate through each value in the message.

# Example
```Julia
for v in values(message)
    println(v)
end
```
"""
function Base.values(handle::Message)
    keyiter = keys(handle)
    EachValue(keyiter)
end

mutable struct codes_iterator
end

struct GribIterator
    ptr::Ptr{codes_iterator}
    npoints::Int
end

"""
    eachpoint(message::Message)

Iterate through each point in the message, returning the lon, lat, and value.

# Example
```Julia
for (lon, lat, val) in eachpoint(message)
    println("Value at (\$lat, \$lon) is \$val")
end
```
"""
function eachpoint(handle::Message)
    eref = Ref(Int32(0))
    ptr = ccall((:codes_grib_iterator_new, eccodes),
                Ptr{codes_iterator}, (Ptr{codes_handle}, Culong, Ref{Cint}),
                handle.ptr, 0, eref)
    errorcheck(eref[])
    if ptr == C_NULL
        throw(ErrorException("Could not create GribIterator"))
    end
    GribIterator(ptr, handle["numberOfPoints"])
end

function Base.iterate(iter::GribIterator, state=())
    lon = 0.0
    lat = 0.0
    value = 0.0
    lonref = Ref(lon)
    latref = Ref(lat)
    valref = Ref(value)
    next = ccall((:codes_grib_iterator_next, eccodes), Cint,
                (Ptr{codes_iterator}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
                iter.ptr, latref, lonref, valref)
    if next == 0
        destroy(iter)
        nothing
    else
        rets = (lonref[], latref[], valref[])
        (rets, ())
    end
end

function destroy(iter::GribIterator)
    err = ccall((:codes_grib_iterator_delete, eccodes), Cint, (Ptr{codes_iterator},), iter.ptr)
    errorcheck(err)
end

Base.eltype(::Type{GribIterator}) = Tuple{Float64, Float64, Float64}
Base.length(iter::GribIterator) = iter.npoints
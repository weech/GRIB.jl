# Structs and functions related to the codes_index type

export Index, addfile!, keycount, select!, destroy

mutable struct codes_index
end

struct Index
    ptr::Ptr{codes_index}
    keys::Vector{String}
end

"""
    Index(filename::AbstractString, keys...)

Create an index from a file with the given keys.
"""
function Index(filename::String, keys...)::Index
    eref = Ref(Int32(0))
    strkeys = join(keys, ",")
    ptr = ccall((:codes_index_new_from_file, eccodes), Ptr{codes_index},
                (Ptr{codes_context}, Cstring, Cstring, Ref{Cint}),
                C_NULL, filename, strkeys, eref)
    errorcheck(eref[])
    arrkeys = [k for k in keys]
    return Index(ptr, arrkeys)
end

"""
    Index(f::Function, filename::AbstractString, keys...)

Create an index from a file with the given keys and automatically close the file.

# Example
```Julia
Index(filename, "shortName", "level") do index
    # Do things with index
end
```
"""
function Index(f::Function, filename::String, keys...)
    index = Index(filename, keys...)
    try
        f(index)
    finally
        destroy(index)
    end
end

"""
    addfile!(index::Index, filename::AbstractString)
Index the file at `filename` using `index`.
"""
function addfile!(index::Index, filename::AbstractString)
    err = ccall((:codes_index_add_file, eccodes), Cint,
                (Ptr{codes_index}, Cstring), index.ptr, filename)
    errorcheck(err)
end

"""
    keycount(index::Index, key::AbstractString)
Get the number of distinct values of the key contained in the index.
"""
function keycount(index::Index, key::AbstractString)
    refsize = Ref(Csize_t(0))
    err = ccall((:codes_index_get_size, eccodes), Cint,
                (Ptr{codes_index}, Cstring, Ref{Csize_t}), index.ptr, key, refsize)
    errorcheck(err)
    return refsize[]
end

"""
    select!(index::Index, key::AbstractString, value::AbstractString)
    select!(index::Index, key::AbstractString, value::AbstractFloat)
    select!(index::Index, key::AbstractString, value::AbstractFloat)

Reduce the size of the index to messages that match the key-value pair.

# Examples
```Julia
Index(filename, "shortName") do index
    select!(index, "shortName", "tp")
    # Index now only has messages about total precipitation
end

Index(filename, "level") do index
    select!(index, "level", 850)
    # Index now only has messages at level 850
end
```
"""
function select!(index::Index, key::AbstractString, value::AbstractString)
    err = ccall((:codes_index_select_string, eccodes), Cint,
                (Ptr{codes_index}, Cstring, Cstring), index.ptr, key, value)
    errorcheck(err)
end

function select!(index::Index, key::AbstractString, value::AbstractFloat)
    err = ccall((:codes_index_select_double, eccodes), Cint,
                (Ptr{codes_index}, Cstring, Cdouble), index.ptr, key, value)
    errorcheck(err)
end

function select!(index::Index, key::AbstractString, value::Integer)
    err = ccall((:codes_index_select_long, eccodes), Cint,
                (Ptr{codes_index}, Cstring, Clong), index.ptr, key, value)
    errorcheck(err)
end

""" Iterate through the messages in the index. """
function Base.iterate(f::Index, state=())
    next = Message(f)
    if next == nothing
        return nothing
    else
        return (next, ())
    end
end

Base.eltype(f::Index) = Message

""" Safely destroy the index. """
function destroy(idx::Index)
    ccall((:codes_index_delete, eccodes), Cvoid, (Ptr{codes_index},), idx.ptr)
end

# Functions related to printing
function Base.show(io::IO, mime::MIME"text/plain", index::Index)
    str = "Index with keys [$(join(index.keys, ", "))]"
    print(io, str)
end

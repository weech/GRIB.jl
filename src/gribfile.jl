# Structs and functions related to the C file pointer type as used in eccodes

export GribFile, destroy

mutable struct File
end

"""
Represents a grib file. Implements many of the Julia I/O functions.
"""
mutable struct GribFile
    ptr::Ptr{File}
    filename::String
    mode::String
    pos::Int
end

function handle_fopen_errors(ptr, fname)
    if ptr == C_NULL 
        # Automatically reads errno
        throw(SystemError("Failed to open $fname"))
    end
end

"""
    GribFile(filename::AbstractString, mode="r")

Open a grib file. `mode` is a mode as described by `Base.open`.
"""
function GribFile(filename::AbstractString; mode="r")
    f = ccall(:fopen, Ptr{File}, (Cstring, Cstring), filename, mode)
    handle_fopen_errors(f, filename)
    nref = Ref(Int32(0))

    GribFile(f, filename, mode, 0)
end

"""
    GribFile(f::Function, filename::AbstractString, mode="r")

Open a grib file and automatically close after exucuting `f`.
`mode` is a mode as described by `Base.open`.

# Example
```julia
GribFile(filename) do f
    # do things in read mode
end
```
"""
function GribFile(f::Function, filename::AbstractString; mode="r")
    file = GribFile(filename, mode=mode)
    try
        f(file)
    finally
        destroy(file)
    end
end

function Base.iterate(f::GribFile, state=())
    next = Message(f)
    if isnothing(next)
        nothing
    else
        (next, ())
    end
end

Base.eltype(::Type{GribFile}) = Message

Base.IteratorSize(::Type{GribFile}) = Base.SizeUnknown()

function Base.seekstart(f::GribFile)
    close(f.ptr)
    fptr = ccall(:fopen, Ptr{File}, (Cstring, Cstring), f.filename, f.mode)
    handle_fopen_errors(fptr, f.filename)
    f.ptr = fptr
    f.pos = 0
end

""" Read without allocating a return vector """
function readnoreturn(f::GribFile, nm::Integer)
    for i in 1:nm
        Message(f)
    end
end

"""
    read(f::GribFile[, nm::Integer])

Read `nm` messages from `f` and return as vector. Default is 1.
"""
function Base.read(f::GribFile, nm::Integer) 
    vec = Vector{Message}(undef, nm)
    valid_count = 0
    for i in 1:nm 
        msg = Message(f)
        if !isnothing(msg)
            vec[i] = msg 
            valid_count += 1
        end
    end
    resize!(vec, valid_count)
    vec
end
# 0.4 TODO: This should return a Vector. Fixing it will be breaking.
Base.read(f::GribFile) = Message(f)

"""
    position(f::GribFile)

Get the current position of the file.
"""
Base.position(f::GribFile) = f.pos

"""
    seek(f::GribFile, n::Integer)

Seek the file to the given position `n`. Throws a `DomainError`
if `n` is negative.
"""
function Base.seek(f::GribFile, n::Integer)
    if n < 0
        throw(DomainError(n, "Cannot seek to before the start of the file"))
    elseif n < f.pos
        seekstart(f)
        readnoreturn(f, n)
    elseif n > f.pos
        readnoreturn(f, n-f.pos)
    end
end

"""
    skip(f::GribFile, offset::Integer)

Seek the file relative to the current position. Throws a `DomainError`
if `offset` brings the file position to before the start of the file.
"""
function Base.skip(f::GribFile, offset::Integer)
    if f.pos + offset < 0 
        throw(DomainError(offset, "Cannot skip to before the start of the file"))
    elseif offset < 0
        oldpos = f.pos
        seekstart(f)
        readnoreturn(f, oldpos+offset)
    else
        readnoreturn(f, offset)
    end
end

"""
    destroy(f::GribFile)

Safely close the file.
"""
function destroy(f::GribFile)
    err = ccall(:fclose, Cint, (Ptr{File},), f.ptr)
    if err != 0
        # 0.4 TODO: Change this to SystemError
        throw(ErrorException("GribFile closed with errorcode $(LibC.errno())"))
    end
end

function close(f::Ptr{File})
    err = ccall(:fclose, Cint, (Ptr{File},), f)
    if err != 0
        # 0.4 TODO: Change this to SystemError
        throw(ErrorException("GribFile closed with errorcode $(LibC.errno())"))
    end
end

# Functions related to printing
function Base.show(io::IO, mime::MIME"text/plain", f::GribFile)
    str = "GribFile $(f.filename) at position $(f.pos) in mode $(f.mode)"
    write(io, str)
end


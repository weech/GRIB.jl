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
    nmessages::Int32
end

"""
    GribFile(filename::AbstractString, mode="r")

Open a grib file. `mode` is a mode as described by `Base.open`.
"""
function GribFile(filename::AbstractString; mode="r")
    if !isfile(filename)
        throw(SystemError("opening file $filename: no such file"))
    end
    f = ccall(:fopen, Ptr{File}, (Cstring, Cstring), filename, mode)

    nref = Ref(Int32(0))
    err = ccall((:codes_count_in_file, eccodes), Cint, (Ptr{codes_context}, Ptr{File}, Ref{Cint}),
                C_NULL, f, nref)
    errorcheck(err)

    GribFile(f, filename, mode, 0, nref[])
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

Base.eltype(f::GribFile) = Message

Base.IteratorSize(f::GribFile) = Base.SizeUnknown()

function handle_fopen_errors(ptr, fname)
    if ptr == C_NULL 
        # Automatically reads errno
        throw(SystemError("Failed to open $fname"))
    end
end

function Base.seekstart(f::GribFile)
    close(f.ptr)
    fptr = ccall(:fopen, Ptr{File}, (Cstring, Cstring), f.filename, f.mode)
    handle_fopen_errors(fptr, f.filename)
    f.ptr = fptr
    f.pos = 0
end

""" Read without allocating a return vector """
function readnoreturn(f::GribFile, nm::Integer)
    total = f.nmessages
    nm = nm + f.pos > total ? total - f.pos : nm
    nm <= 0 && return
    for i in 1:nm
        Message(f)
    end
end

"""
    read(f::GribFile[, nm::Integer])

Read `nm` messages from `f` and return as vector. Default is 1.
"""
function Base.read(f::GribFile, nm::Integer)
    total = f.nmessages
    nm = nm + f.pos > total ? total - f.pos : nm
    nm <= 0 && return nothing
    ret = Vector{Message}(undef, nm)
    for i in 1:nm
        ret[i] = Message(f)
    end
    ret
end
Base.read(f::GribFile) = Message(f)

"""
    position(f::GribFile)

Get the current position of the file.
"""
Base.position(f::GribFile) = f.pos

"""
    seek(f::GribFile, n::Integer)

Seek the file to the given position `n`
"""
function Base.seek(f::GribFile, n::Integer)
    if n < 0 || n > f.nmessages
        throw(DomainError("n is out of range for file length $(f.nmessages)"))
    end
    if n < f.pos
        seekstart(f)
        readnoreturn(f, n)
    elseif n > f.pos
        readnoreturn(f, n-f.pos)
    end
end

"""
    skip(f::GribFile, offset::Integer)

Seek the file relative to the current position
"""
function Base.skip(f::GribFile, offset::Integer)
    # 0.4 TODO: Should just do it and throw EOFError at end
    if f.pos + offset > f.nmessages
        throw(DomainError("offset is out of range for file length $(f.nmessages)"))
    end
    if offset < 0
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



# GribFile

A `GribFile` functions similarly to a Julia `IOStream`, except that instead of working as a stream
of bytes, `GribFile` works as a stream of messages. Basic access looks like
```Julia
GribFile(filename) do f
    # Do things with f
end
```
Using the `do`-block construct guarantees that the resources are released after exiting the
`do`-block. The style
```Julia
f = GribFile(filename)
# Do things with f
destroy(f)
```
is also valid, but be sure to call `destroy` when finished with the file.

A `GribFile` is an iterable, and it defines `seek`, `skip`, and `seekfirst` to aid in navigating
the file.

## API
```@docs
GribFile(::AbstractString)

GribFile(::Function, ::AbstractString)

Base.filter

Base.read

Base.position

Base.seek

Base.skip

destroy(::GribFile)
```
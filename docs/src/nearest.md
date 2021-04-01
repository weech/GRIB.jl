# Nearest
GRIB.jl wraps the ecCodes functions for finding points that are 
close to a given point.

## API
```@docs
Nearest(::Message)

Nearest(::Function, ::Message)

find

findmultiple

destroy(::Nearest)
```
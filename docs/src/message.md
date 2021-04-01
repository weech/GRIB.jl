# Message
The `Message` type represents a single GRIB record. It works like a dictionary where the indices
are of type `String`. Creating a `Message` looks like
```Julia
GribFile(filename) do f
    # Get the first message from f
    msg = Message(f)

    # Get the second and third messages from f
    msgs = read(f, 2)

    # Work on the rest of the messages in f
    for message in f
        # Do things with message
    end
end
```
An important thing to note is that creating a `Message` moves the position of the `GribFile`.
This means that in order to access a message that has already passed, the `seek` function
must be used to change the position of the `GribFile`.

The `Message` type behaves like a dictionary in that data is accessed like `value = msg[key]`.
The most important keys are listed above, and the other keys are discoverable using the `keys`
function. The `keys` function returns an iterable, but this iterable does not define `length`,
so the best way to get a list of all keys in the message is to do
```Julia
keylist = Vector{String}()
for key in keys(message)
    push!(keylist, key)
end
```

Another important function for the `Message` type is `data`. This function returns a tuple of
longitudes, latitudes, and values for each point in the message. The following is true
```Julia
lons, lats, values = data(message)
valuesfromkey = data["values"]
valuesfromkey == values
```
The `eachpoint` function returns an iterable that iterates through the points returning a
longitude, latitude, and value for each point.

GRIB messages often have missing values. The value that represents missing can be discovered
using the `missingvalue` function. There is also a convenience function `maskedvalues` that
returns the values with the missing values replaced with `missing`.

Calling `print` or `println` on a `Message` returns the hexidecimal representation of the message,
since those functions are meant return a string that can be used to recreate the object. Use
`display` instead for an informative summary of the `Message`.

## API
```@docs
Message(::Index)

Message(::Vector{UInt8})

getbytes

writemessage

missingvalue

maskedvalues

clone

data

Base.keys(::Message)

Base.values(::Message)

eachpoint

destroy(::Message)

```
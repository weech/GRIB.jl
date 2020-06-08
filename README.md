# GRIB.jl

The Gridded Binary (GRIB) format is a format commonly used in meteorology. A GRIB file is a
collection of independent records that store 2D data. This package is an interface to the ECMWF
[ecCodes](https://confluence.ecmwf.int/display/ECC/ecCodes+Home) library. In ecCodes, each
GRIB file is composed of a series of messages, and a message is an object with keys and values.
Each message has many keys. Some are actually stored in the data, while others are computed
by ecCodes on access. Some commonly used keys include:

| key         | value                         |
| ----------- | ----------------------------- |
| name        | long name of the quantity     |
| shortName   | standard abbreviation of name |
| latitudes   | array of latitudes            |
| longitudes  | array of longitudes           |
| values      | array of data values          |
| units       | units of quantity             |
| date        | date in YYYYmmdd format       |
| typeOfLevel | kind of vertical level        |
| level       | value of vertical level       |


## Installation
You can install this package through the normal methods:
`Pkg.add("GRIB")` or `]add GRIB`. 

This package currently doesn't work on Windows. Any help in
getting it to work would be greatly appreciated!

## GribFile
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

## Message
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

## Index
The `Index` type is a way to reduce the size of a file so that only messages with specific
key-value pairs are included. A typical use-case looks like this:
```Julia
Index(filename, "shortName", "typeOfLevel", "level") do index
    select!(index, "shortName", "t")
    select!(index, "typeOfLevel", "isobaricInhPa")
    select!(index, "level", 500)
    for msg in index
        # Do things with msg
    end
end
```
This example selects all messages that are temperature at the 500 hPa level. Indexes are
invaluable for reducing the complexity of the file before retreiving data from it. There are
a few important things to note:
* Only keys passed to the `Index` when it is created can be `select!`ed.
* All keys passed to `Index` must be `select!`ed before accessing any messages.
* Like with `GribFile`, retreiving a message from an `Index` advances the `Index`.
* Only the latest value `select!`ed per key is kept in the `Index`.
* Files with multi-field messages cannot be used with `Index`. This includes most files created
  by NCEP.

## Other notes
This package has support for multi-field messages on by default. If you are not working with files
with multi-field messages, you may turn off support with a call
to the function `nomultisupport`.

## Bug Reporting
This package has been tested mainly with well-behaved GRIB files, but some files exist that
push the boundaries of the format. If you encounter any issues, please file an issue. A good issue
has
* A full stack trace. The error can't be understood without knowing where it comes from.
* The file causing the issue, if possible.
* A hypothesis of what you think is going wrong.

## Future plans (good places to help out)
* Add support for BUFR files
* Add examples
* Fix the bug in `eachpoint` that occasionally causes Julia to segfault (probably something with
  the GC).


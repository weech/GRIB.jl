# Index
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

## API

```@docs
Index(::String)

Index(::Function, ::String)

addfile!

keycount

select!

Base.iterate(::Index)

destroy(::Index)

```
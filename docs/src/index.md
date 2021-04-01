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


## Manual Outline
```@contents 
Pages = [
    "gribfile.md"
    "message.md"
    "indexer.md"
    "nearest.md"
]
Depth = 1
```

## Other notes
This package has support for multi-field messages on by default. If you are not working with files
with multi-field messages, you may turn off support with a call
to the function `nomultisupport`.
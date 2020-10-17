# About
From time to time a center releases GRIB files into the wild that include local-use 
codes. The ecCodes library includes definition files for some of these, but its 
store of local codes hasn't been updated in years, so newer models (such as the 
HRRR) have missing product codes. This folder is a collection of local code definitions 
to cover those gaps.

# How to contribute
The ECMWF [has instructions](https://confluence.ecmwf.int/display/UDOC/Creating+your+own+local+definitions+-+ecCodes+GRIB+FAQ) 
on how to create definition files. Basically, you need to find the discipline, parameter 
category, and parameter number of the product that is missing and add the relevant 
information to this folder.

## Finding the numbers
The easiest way to find the code numbers is to use `GRIB.jl` itself. Let's say you 
have a file named `hrrr.t00z.wrfsfcf00.grib2` where the second message is an unknown 
product.
```Julia
file = GribFile("hrrr.t00z.wrfsfcf00.grib2")
seek(file, 1)
msg = read(file)
println("The discipline is ", msg["discipline"],
"\nThe parameterCategory is ", msg["parameterCategory"],
"\nThe parameterNumber is ", msg["parameterNumber"]
)
```
prints
```
The discipline is 0
The parameterCategory is 16
The parameterNumber is 3
```


## Finding the correct metadata
If the GRIB file is from NCEP (`centre` = 7), you can get the correct name, units, 
and short name from [this table](https://www.nco.ncep.noaa.gov/pmb/docs/grib2/grib2_doc/grib2_table4-2.shtml). 
NCEP and ECMWF have different guidelines for short names, and I think the best way 
to go for now is to use the NCEP abbreviation but in lowercase. Units use `**` to 
mark exponents and have spaces between each term of the unit. For example, `'m m**6 m**-3'` 
for equivalent radar reflectivity factors.

A paramId is required by ecCodes, and that's just supposed to be a unique ID. I do not 
know what ECMWF's system is for generating this ID, so for now I'm going with combining 
the four numbers together in a near-unique way. As an illustrative example, let's 
say the `centre` is 7, the `discipline` is 0, the `parameterCategory` is 16, and 
the `parameterNumber` is 3. The combined number would be `70016003`. The `parameterCategory` 
and `parameterNumber` are padded to 3 places in this scheme.

## Putting it together
There are examples in the `grib2/localConcepts/kwbc` directory of what the definitions 
look like. You need to add the name, paramId, shortName, and units for the new product 
in the appropriate files. Please keep them sorted, and try not to add definitions 
for products [already in ecCodes](https://github.com/ecmwf/eccodes/). Pull requests 
welcome!
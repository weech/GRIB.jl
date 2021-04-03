var documenterSearchIndex = {"docs":
[{"location":"message/#Message","page":"Message","title":"Message","text":"","category":"section"},{"location":"message/","page":"Message","title":"Message","text":"The Message type represents a single GRIB record. It works like a dictionary where the indices are of type String. Creating a Message looks like","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"GribFile(filename) do f\n    # Get the first message from f\n    msg = Message(f)\n\n    # Get the second and third messages from f\n    msgs = read(f, 2)\n\n    # Work on the rest of the messages in f\n    for message in f\n        # Do things with message\n    end\nend","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"An important thing to note is that creating a Message moves the position of the GribFile. This means that in order to access a message that has already passed, the seek function must be used to change the position of the GribFile.","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"The Message type behaves like a dictionary in that data is accessed like value = msg[key]. The most important keys are listed above, and the other keys are discoverable using the keys function. The keys function returns an iterable, but this iterable does not define length, so the best way to get a list of all keys in the message is to do","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"keylist = Vector{String}()\nfor key in keys(message)\n    push!(keylist, key)\nend","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"Another important function for the Message type is data. This function returns a tuple of longitudes, latitudes, and values for each point in the message. The following is true","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"lons, lats, values = data(message)\nvaluesfromkey = data[\"values\"]\nvaluesfromkey == values","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"The eachpoint function returns an iterable that iterates through the points returning a longitude, latitude, and value for each point.","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"GRIB messages often have missing values. The value that represents missing can be discovered using the missingvalue function. There is also a convenience function maskedvalues that returns the values with the missing values replaced with missing.","category":"page"},{"location":"message/","page":"Message","title":"Message","text":"Calling print or println on a Message returns the hexidecimal representation of the message, since those functions are meant return a string that can be used to recreate the object. Use display instead for an informative summary of the Message.","category":"page"},{"location":"message/#API","page":"Message","title":"API","text":"","category":"section"},{"location":"message/","page":"Message","title":"Message","text":"Message(::Index)\n\nMessage(::Vector{UInt8})\n\ngetbytes\n\nwritemessage\n\nmissingvalue\n\nmaskedvalues\n\nclone\n\ndata\n\nBase.keys(::Message)\n\nBase.values(::Message)\n\neachpoint\n\ndestroy(::Message)\n","category":"page"},{"location":"message/#GRIB.Message-Tuple{Index}","page":"Message","title":"GRIB.Message","text":"Message(index::Index)\nMessage(file::GribFile)\n\nRetrieve the next message.\n\nReturns nothing if there are no more messages.\n\n\n\n\n\n","category":"method"},{"location":"message/#GRIB.Message-Tuple{Vector{UInt8}}","page":"Message","title":"GRIB.Message","text":"Message(raw::Vector{UInt8})\nMessage(messages::Vector{Vector{UInt8}})\n\nCreate a Message from a bytes array or array of bytes arrays.\n\nThe Message will share its underlying data with the inputed data.\n\n\n\n\n\n","category":"method"},{"location":"message/#GRIB.getbytes","page":"Message","title":"GRIB.getbytes","text":"getbytes(message::Message)\n\nGet a coded representation of the Message.\n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.writemessage","page":"Message","title":"GRIB.writemessage","text":"writemessage(handle::Message, filename::AbstractString; mode=\"w\")\n\nWrite the message respresented by handle to the file at filename.\n\nmode is a mode as described by Base.open.\n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.missingvalue","page":"Message","title":"GRIB.missingvalue","text":"missingvalue(msg::Message)\n\nReturn the missing value of the message. If one isn't included returns 1e30.\n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.maskedvalues","page":"Message","title":"GRIB.maskedvalues","text":"maskedvalues(msg::Message)\n\nReturn the values of the message masked so the missing value is missing.\n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.clone","page":"Message","title":"GRIB.clone","text":"Duplicate a message. \n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.data","page":"Message","title":"GRIB.data","text":"data(handle::Message)\n\nRetrieve the longitudes, latitudes, and values from the message.\n\nExample\n\nGribFile(filename) do f\n    msg = Message(f)\n    lons, lats, values = data(msg)\nend\n\n\n\n\n\n","category":"function"},{"location":"message/#Base.keys-Tuple{Message}","page":"Message","title":"Base.keys","text":"keys(message::Message)\n\nIterate through each key in the message.\n\nExample\n\nfor key in keys(message)\n    println(key)\nend\n\n\n\n\n\n","category":"method"},{"location":"message/#Base.values-Tuple{Message}","page":"Message","title":"Base.values","text":"values(message::Message)\n\nIterate through each value in the message.\n\nExample\n\nfor v in values(message)\n    println(v)\nend\n\n\n\n\n\n","category":"method"},{"location":"message/#GRIB.eachpoint","page":"Message","title":"GRIB.eachpoint","text":"eachpoint(message::Message)\n\nIterate through each point in the message, returning the lon, lat, and value.\n\nExample\n\nfor (lon, lat, val) in eachpoint(message)\n    println(\"Value at ($lat, $lon) is $val\")\nend\n\n\n\n\n\n","category":"function"},{"location":"message/#GRIB.destroy-Tuple{Message}","page":"Message","title":"GRIB.destroy","text":"Safely destroy a message handle. \n\n\n\n\n\n","category":"method"},{"location":"gribfile/#GribFile","page":"GribFile","title":"GribFile","text":"","category":"section"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"A GribFile functions similarly to a Julia IOStream, except that instead of working as a stream of bytes, GribFile works as a stream of messages. Basic access looks like","category":"page"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"GribFile(filename) do f\n    # Do things with f\nend","category":"page"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"Using the do-block construct guarantees that the resources are released after exiting the do-block. The style","category":"page"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"f = GribFile(filename)\n# Do things with f\ndestroy(f)","category":"page"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"is also valid, but be sure to call destroy when finished with the file.","category":"page"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"A GribFile is an iterable, and it defines seek, skip, and seekfirst to aid in navigating the file.","category":"page"},{"location":"gribfile/#API","page":"GribFile","title":"API","text":"","category":"section"},{"location":"gribfile/","page":"GribFile","title":"GribFile","text":"GribFile(::AbstractString)\n\nGribFile(::Function, ::AbstractString)\n\nBase.filter\n\nBase.read\n\nBase.position\n\nBase.seek\n\nBase.skip\n\ndestroy(::GribFile)","category":"page"},{"location":"gribfile/#GRIB.GribFile-Tuple{AbstractString}","page":"GribFile","title":"GRIB.GribFile","text":"GribFile(filename::AbstractString, mode=\"r\")\n\nOpen a grib file. mode is a mode as described by Base.open.\n\n\n\n\n\n","category":"method"},{"location":"gribfile/#GRIB.GribFile-Tuple{Function, AbstractString}","page":"GribFile","title":"GRIB.GribFile","text":"GribFile(f::Function, filename::AbstractString, mode=\"r\")\n\nOpen a grib file and automatically close after exucuting f. mode is a mode as described by Base.open.\n\nExample\n\nGribFile(filename) do f\n    # do things in read mode\nend\n\n\n\n\n\n","category":"method"},{"location":"gribfile/#Base.filter","page":"GribFile","title":"Base.filter","text":"filter(func, gfile)\n\nReturn a vector of messages in gfile where func returns true\n\n\n\n\n\n","category":"function"},{"location":"gribfile/#Base.read","page":"GribFile","title":"Base.read","text":"read(f::GribFile[, nm::Integer])\n\nRead nm messages from f and return as vector. Default is 1.\n\n\n\n\n\n","category":"function"},{"location":"gribfile/#Base.position","page":"GribFile","title":"Base.position","text":"position(f::GribFile)\n\nGet the current position of the file.\n\n\n\n\n\n","category":"function"},{"location":"gribfile/#Base.seek","page":"GribFile","title":"Base.seek","text":"seek(f::GribFile, n::Integer)\n\nSeek the file to the given position n\n\n\n\n\n\n","category":"function"},{"location":"gribfile/#Base.skip","page":"GribFile","title":"Base.skip","text":"skip(f::GribFile, offset::Integer)\n\nSeek the file relative to the current position\n\n\n\n\n\n","category":"function"},{"location":"gribfile/#GRIB.destroy-Tuple{GribFile}","page":"GribFile","title":"GRIB.destroy","text":"destroy(f::GribFile)\n\nSafely close the file.\n\n\n\n\n\n","category":"method"},{"location":"indexer/#Index","page":"Index","title":"Index","text":"","category":"section"},{"location":"indexer/","page":"Index","title":"Index","text":"The Index type is a way to reduce the size of a file so that only messages with specific key-value pairs are included. A typical use-case looks like this:","category":"page"},{"location":"indexer/","page":"Index","title":"Index","text":"Index(filename, \"shortName\", \"typeOfLevel\", \"level\") do index\n    select!(index, \"shortName\", \"t\")\n    select!(index, \"typeOfLevel\", \"isobaricInhPa\")\n    select!(index, \"level\", 500)\n    for msg in index\n        # Do things with msg\n    end\nend","category":"page"},{"location":"indexer/","page":"Index","title":"Index","text":"This example selects all messages that are temperature at the 500 hPa level. Indexes are invaluable for reducing the complexity of the file before retreiving data from it. There are a few important things to note:","category":"page"},{"location":"indexer/","page":"Index","title":"Index","text":"Only keys passed to the Index when it is created can be select!ed.\nAll keys passed to Index must be select!ed before accessing any messages.\nLike with GribFile, retreiving a message from an Index advances the Index.\nOnly the latest value select!ed per key is kept in the Index.\nFiles with multi-field messages cannot be used with Index. This includes most files created by NCEP.","category":"page"},{"location":"indexer/#API","page":"Index","title":"API","text":"","category":"section"},{"location":"indexer/","page":"Index","title":"Index","text":"Index(::String)\n\nIndex(::Function, ::String)\n\naddfile!\n\nkeycount\n\nselect!\n\nBase.iterate(::Index)\n\ndestroy(::Index)\n","category":"page"},{"location":"indexer/#GRIB.Index-Tuple{String}","page":"Index","title":"GRIB.Index","text":"Index(filename::AbstractString, keys...)\n\nCreate an index from a file with the given keys.\n\n\n\n\n\n","category":"method"},{"location":"indexer/#GRIB.Index-Tuple{Function, String}","page":"Index","title":"GRIB.Index","text":"Index(f::Function, filename::AbstractString, keys...)\n\nCreate an index from a file with the given keys and automatically close the file.\n\nExample\n\nIndex(filename, \"shortName\", \"level\") do index\n    # Do things with index\nend\n\n\n\n\n\n","category":"method"},{"location":"indexer/#GRIB.addfile!","page":"Index","title":"GRIB.addfile!","text":"addfile!(index::Index, filename::AbstractString)\n\nIndex the file at filename using index.\n\n\n\n\n\n","category":"function"},{"location":"indexer/#GRIB.keycount","page":"Index","title":"GRIB.keycount","text":"keycount(index::Index, key::AbstractString)\n\nGet the number of distinct values of the key contained in the index.\n\n\n\n\n\n","category":"function"},{"location":"indexer/#GRIB.select!","page":"Index","title":"GRIB.select!","text":"select!(index::Index, key::AbstractString, value::AbstractString)\nselect!(index::Index, key::AbstractString, value::AbstractFloat)\nselect!(index::Index, key::AbstractString, value::AbstractFloat)\n\nReduce the size of the index to messages that match the key-value pair.\n\nExamples\n\nIndex(filename, \"shortName\") do index\n    select!(index, \"shortName\", \"tp\")\n    # Index now only has messages about total precipitation\nend\n\nIndex(filename, \"level\") do index\n    select!(index, \"level\", 850)\n    # Index now only has messages at level 850\nend\n\n\n\n\n\n","category":"function"},{"location":"indexer/#Base.iterate-Tuple{Index}","page":"Index","title":"Base.iterate","text":"Iterate through the messages in the index. \n\n\n\n\n\n","category":"method"},{"location":"indexer/#GRIB.destroy-Tuple{Index}","page":"Index","title":"GRIB.destroy","text":"Safely destroy the index. \n\n\n\n\n\n","category":"method"},{"location":"nearest/#Nearest","page":"Nearest","title":"Nearest","text":"","category":"section"},{"location":"nearest/","page":"Nearest","title":"Nearest","text":"GRIB.jl wraps the ecCodes functions for finding points that are  close to a given point.","category":"page"},{"location":"nearest/#API","page":"Nearest","title":"API","text":"","category":"section"},{"location":"nearest/","page":"Nearest","title":"Nearest","text":"Nearest(::Message)\n\nNearest(::Function, ::Message)\n\nfind\n\nfindmultiple\n\ndestroy(::Nearest)","category":"page"},{"location":"nearest/#GRIB.Nearest-Tuple{Message}","page":"Nearest","title":"GRIB.Nearest","text":"Nearest(handle::Message)\n\nCreate a Nearest from a Message.\n\n\n\n\n\n","category":"method"},{"location":"nearest/#GRIB.Nearest-Tuple{Function, Message}","page":"Nearest","title":"GRIB.Nearest","text":"Nearest(f::Function, handle::Message)\n\nCreate a Nearest from a Message and automatically destroy when finished.\n\nExample\n\nNearest(handle) do near\n    find(near, handle, inlat, inlon)\nend\n\n\n\n\n\n","category":"method"},{"location":"nearest/#GRIB.find","page":"Nearest","title":"GRIB.find","text":"find(near::Nearest, handle::Message, inlon::Float64, inlat::Float64; samepoint=true, samegrid=true)\n\nFind the nearest 4 points to the given point sorted by distance.\n\nSetting samepoint and samegrid to true (default) speeds up the calculation but restricts the point and grid, respectively, from changing from call to call. Distance is in kilometers.\n\nExample\n\nNearest(handle) do near\n    lons, lats, values, distances = find(near, handle, inlon, inlat)\nend\n\n\n\n\n\n","category":"function"},{"location":"nearest/#GRIB.findmultiple","page":"Nearest","title":"GRIB.findmultiple","text":"findmultiple(handle::Message, inlons::Vector{Float64}, inlats::Vector{Float64}; islsm=false)\n\nFind the nearest point to each point given.\n\nSetting islsm to true finds the nearest land point and only works when handle represents a land-sea-mask. Distance is in kilometers.\n\nExample\n\nlons, lats, values, distances = findmultiple(handle, inlons, inlats)\n\n\n\n\n\n","category":"function"},{"location":"nearest/#GRIB.destroy-Tuple{Nearest}","page":"Nearest","title":"GRIB.destroy","text":"Safely destroy a nearest object. \n\n\n\n\n\n","category":"method"},{"location":"#GRIB.jl","page":"Home","title":"GRIB.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The Gridded Binary (GRIB) format is a format commonly used in meteorology. A GRIB file is a collection of independent records that store 2D data. This package is an interface to the ECMWF ecCodes library. In ecCodes, each GRIB file is composed of a series of messages, and a message is an object with keys and values. Each message has many keys. Some are actually stored in the data, while others are computed by ecCodes on access. Some commonly used keys include:","category":"page"},{"location":"","page":"Home","title":"Home","text":"key value\nname long name of the quantity\nshortName standard abbreviation of name\nlatitudes array of latitudes\nlongitudes array of longitudes\nvalues array of data values\nunits units of quantity\ndate date in YYYYmmdd format\ntypeOfLevel kind of vertical level\nlevel value of vertical level","category":"page"},{"location":"#Manual-Outline","page":"Home","title":"Manual Outline","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\n    \"gribfile.md\"\n    \"message.md\"\n    \"indexer.md\"\n    \"nearest.md\"\n]\nDepth = 1","category":"page"},{"location":"#Other-notes","page":"Home","title":"Other notes","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package has support for multi-field messages on by default. If you are not working with files with multi-field messages, you may turn off support with a call to the function nomultisupport.","category":"page"}]
}

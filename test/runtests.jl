using GRIB
using Test
using Statistics

@testset "GRIB" begin

    GribFile(joinpath(dirname(@__FILE__), "samples", "regular_latlon_surface.grib2")) do f

        # Test that it starts at 0
        @test position(f) == 0

        # Get the message
        msg = Message(f)

        # Test that position has changed
        @test position(f) == 1

        # Test haskey
        @test haskey(msg, "shortName")
        @test !haskey(msg, "gibberish")

        # Test getindex
        @test msg["shortName"] == "2t"
        @test msg["level"] == 2
        @test missingvalue(msg) == 9999
        @test typeof(maskedvalues(msg)) == Array{Union{Missing,Float64},2}

        # Test data
        lons, lats, vals = data(msg)
        validlats = collect(0.0:2:60.0)
        validlons = collect(0.0:2:30.0)
        @test all([l in validlats for l in lats])
        @test all([l in validlons for l in lons])
        @test size(vals) == (16, 31)
        @test mean(vals) == msg["average"]
        @test vals == msg["values"]
        nx, ny = size(lons)
        @test all([lons[1, y] - lons[1, 1] == 0 for y in 1:ny]) || all([lons[x, 1] - lons[1, 1] == 0 for x in 1:nx])
        @test all([lats[1, y] - lats[1, 1] == 0 for y in 1:ny]) || all([lats[x, 1] - lats[1, 1] == 0 for x in 1:nx])

        # Test clone, setindex!, and write
        msg2 = clone(msg)
        @test data(msg2) == data(msg)
        msg2["shortName"] = "t"
        msg2["level"] = 10
        msg2["latitudeOfFirstGridPointInDegrees"] = msg["latitudeOfFirstGridPointInDegrees"] + 10
        msg2["values"] = msg["values"] .+ 20
        writemessage(msg2, joinpath(dirname(@__FILE__), "samples", "modified_latlon_surface.grib2"))
        GribFile(joinpath(dirname(@__FILE__), "samples", "modified_latlon_surface.grib2")) do f
            msg3 = Message(f)
            @test msg3["shortName"] == "t"
            @test msg3["level"] == 10
        end

        # Just testing to make sure these don't throw
        bytes = getbytes(msg)
        msg3 = Message(bytes)
        @test msg3["shortName"] == msg["shortName"]
        bytesarr = [bytes, getbytes(msg2)]
        msg4 = Message(bytesarr)
        msg5 = Message(msg3)
        msg6 = deepcopy(msg5)

        # Test GribIterate
        lons1d = Vector{Float64}(undef, length(lons))
        lats1d = similar(lons1d)
        vals1d = similar(lons1d)
        @test length(eachpoint(msg)) == length(vals)
        for (i, pt) in enumerate(eachpoint(msg))
            lons1d[i] = pt[1]
            lats1d[i] = pt[2]
            vals1d[i] = pt[3]
        end
        @test vec(lons) == lons1d
        @test vec(lats) == lats1d
        @test vec(vals) == vals1d

        # Test keys and values
        ks = Set{String}()
        for k in keys(msg)
            push!(ks, k)
        end
        @test eltype(keys(msg)) == String
        @test "skewness" in ks && "latitudes" in ks && "centre" in ks && "maximum" in ks
        vs = Set()
        for v in values(msg)
            push!(vs, v)
        end
        @test "2t" in vs && 2 in vs && 9999 in vs
        ks2 = Set{String}()
        vs2 = Set()
        for (key, value) in msg
            push!(ks2, key)
            push!(vs2, value)
        end
        @test issetequal(ks, ks2)
        @test issetequal(vs, vs2)

        # Test Nearest
        lons, lats, vals, dists = Nearest(msg) do n
            find(n, msg, 25.75, 25.25)
        end
        @test lons == [26, 26, 24, 24]
        @test lats == [26, 24, 26, 24]
        @test all(isapprox.(dists, [87.08, 141.28, 194.27, 224.97], atol=0.01))

        inlons = collect(2.0:2:10.0)
        inlats = collect(2.0:2:10.0)
        lons, lats, vals, dists = findmultiple(msg, inlons, inlats)
        @test all([d == 0 for d in dists])
        @test_throws DomainError findmultiple(msg, inlons[1:2], inlats)
    end

    # Test Index
    if !Sys.iswindows()
        Index(joinpath(dirname(@__FILE__), "samples", "flux.grb"), "edition") do index
            select!(index, "edition", 2)
            count = 0
            for msg in index
                count += 1
            end
            @test count == 4
        end

        Index(joinpath(dirname(@__FILE__), "samples", "flux.grb"), "typeOfLevel") do index
            select!(index, "typeOfLevel", "surface")
            @test keycount(index, "typeOfLevel") == 2
            names = Set{String}()
            for msg in index
                push!(names, msg["shortName"])
            end
            @test issetequal(names, ["prate", "sp"])
        end

        Index(joinpath(dirname(@__FILE__), "samples", "flux.grb"), "latitudeOfFirstGridPointInDegrees") do index
            addfile!(index, joinpath(dirname(@__FILE__), "samples", "regular_latlon_surface.grib2"))
            select!(index, "latitudeOfFirstGridPointInDegrees", 88.542)
        end
    end

    GribFile(joinpath(dirname(@__FILE__), "samples", "flux.grb")) do f
        count = 0
        for msg in f
            count += 1
        end
        @test count == 4
    end

    # Test the seeking methods
    GribFile(joinpath(dirname(@__FILE__), "samples", "flux.grb")) do f
        @test eltype(f) == Message
        msgs = read(f, 2)
        @test length(msgs) == 2
        @test position(f) == 2
        seekstart(f)
        @test position(f) == 0
        seek(f, 3)
        @test position(f) == 3
        skip(f, -2)
        @test position(f) == 1
        skip(f, 1)
        @test position(f) == 2
        seek(f, 1)
        @test position(f) == 1
        @test_throws DomainError seek(f, -1)
        @test_throws DomainError skip(f, -15)
        @test length(read(f, 8)) == 3
        @test position(f) == 9
    end

    # Test that it doesn't try to open a non-existent file
    if isfile(joinpath(dirname(@__FILE__), "samples", "nofilehere.grb"))
        rm(joinpath(dirname(@__FILE__), "samples", "nofilehere.grb"))
    end
    @test_throws SystemError GribFile(joinpath(dirname(@__FILE__), "samples", "nofilehere.grb"))

    # Test multi-field
    GribFile(joinpath(dirname(@__FILE__), "samples", "isobaricsmaller.grb2")) do f
        shortnames = AbstractString[]
        for msg in f
            push!(shortnames, msg["shortName"])
        end
        @test "v" in shortnames
        @test length(shortnames) == 18
    end

    GribFile(joinpath(dirname(@__FILE__), "samples", "isobaricsmaller.grb2")) do f
        @test eltype(f) == Message
        msgs = read(f, 2)
        @test length(msgs) == 2
        @test position(f) == 2
        seekstart(f)
        @test position(f) == 0
        seek(f, 3)
        @test position(f) == 3
        skip(f, -2)
        @test position(f) == 1
        skip(f, 1)
        @test position(f) == 2
        seek(f, 1)
        @test position(f) == 1
    end

    nomultisupport()
    GribFile(joinpath(dirname(@__FILE__), "samples", "isobaricsmaller.grb2")) do f
        shortnames = AbstractString[]
        for msg in f
            push!(shortnames, msg["shortName"])
        end
        @test !("v" in shortnames)
        @test length(shortnames) == 12
    end

    GribFile(joinpath(dirname(@__FILE__), "samples", "isobaricsmaller.grb2")) do f
        @test eltype(f) == Message
        msgs = read(f, 2)
        @test length(msgs) == 2
        @test position(f) == 2
        seekstart(f)
        @test position(f) == 0
        seek(f, 3)
        @test position(f) == 3
        skip(f, -2)
        @test position(f) == 1
        skip(f, 1)
        @test position(f) == 2
        seek(f, 1)
        @test position(f) == 1
    end

    # Test that iterator methods are defined because Julia assumes weird defaults
    GribFile(joinpath(dirname(@__FILE__), "samples", "isobaricsmaller.grb2")) do f
        @test Base.IteratorSize(f) == Base.SizeUnknown()
        msg = read(f)
        @test Base.IteratorSize(keys(msg)) == Base.SizeUnknown()
        @test Base.IteratorSize(values(msg)) == Base.SizeUnknown()
    end

    # Test that the local definitions are working
    GribFile(joinpath(dirname(@__FILE__), "samples", "hrrr.echotop.grib2")) do f
        msg = read(f)
        @test msg["name"] == "Echo Top"
    end
end

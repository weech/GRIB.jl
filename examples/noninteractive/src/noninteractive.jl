module noninteractive

export main

import Dates
import Downloads
import GeoInterface: coordinates
import GRIB
import Proj4
import PyPlot
import Shapefile
import ZipFile

"""
    fetch_natural_earth(layerurl)

Fetch a Shapefile.Table of the zip file located at `layerurl`
"""
function fetch_natural_earth(layerurl)
    # In a real workflow, you'd have Natural Earth saved somewhere
    #   and load it in, rather than getting from the website every time
    ziptemp = Downloads.download(layerurl)
    reader = ZipFile.Reader(ziptemp)
    tempdir = mktempdir()
    for file in reader.files 
        open(joinpath(tempdir, file.name), "w") do io 
            write(io, read(file, String))
        end
    end
    basename = split(layerurl, '/')[end]
    Shapefile.Table(joinpath(tempdir, splitext(basename)[1]))
end


"""
    fetch_cfs(time)

Downloads the CFS analysis for the given time. Returns the path to a temporary
file if successful. Returns a DomainError if the time cannot represent a valid
analysis time (00/06/12/18Z between April 2011 and a few days ago).
"""
function fetch_cfs(time)
    base = "https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-analysis/6-hourly-by-pressure/"
    tail = ".pgrbhanl.grib2"
    if Dates.hour(time) ∉ [0, 6, 12, 18]
        return DomainError(Dates.hour(time), "The hour must be either 0, 6, 12, or 18")
    end
    if time < Dates.DateTime(2011, 4, 1, 0) || time > Dates.now()
        return DomainError(time, "The date is outside of the period of record (2011-04 to several days ago)")
    end
    center = Dates.format(time, "yyyy/yyyymm/yyyymmdd/")
    full = "$(base)$(center)cdas1.t$(Dates.hour(time))z$(tail)"
    # Be aware that this is a large file (~80 MB)
    Downloads.download(full)
end

"""
    subset_indices(lats, lons, bbox)

Create a masking array the same size as `lats` and `lons` that will
subset the portion of lats and lons within `bbox`. `bbox` has fields
`ymin`, `ymax`, `xmin`, `xmax`.
"""
function subset_indices(lats, lons, bbox)
    valid_lats = map(l -> bbox.ymin < l < bbox.ymax, lats)
    valid_lons = map(l -> bbox.xmin < l < bbox.xmax, lons)
    valid_lats .& valid_lons
end

"""
    relative_vorticity(u, v, x, y)

Compute the relative vorticity (ζ). It is recommended to have `x` and `y`
be in a CRS that preserves direction like the Mercator projection.
"""
function relative_vorticity(u, v, x, y)
    ζ = zeros(size(u))
    for col in 2:size(ζ, 2)-1, row in 2:size(ζ, 1)-1, 
        ∂v = v[row, col+1] + v[row, col-1] - 2*v[row, col]
        ∂x = (x[row, col+1] - x[row, col-1]) / 2
        ∂u = u[row+1, col] + u[row-1, col] - 2*u[row, col]
        ∂y = (y[row+1, col] - y[row-1, col]) / 2
        ζ[row, col] = ∂v / ∂x - ∂u / ∂y 
    end
    ζ
end

mps_to_kt(x) = x * 60. * 60. / 1852.

function main()
    # Download data and wait on CFS
    cfstime = Dates.DateTime(2013, 2, 9, 12)
    # A bug in Download.downloads means we can't put it in another thread
    cfsfut = @async fetch_cfs(cfstime) 
    statesfut = Threads.@spawn fetch_natural_earth("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_1_states_provinces_lakes.zip")
    countriesfut = Threads.@spawn fetch_natural_earth("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries_lakes.zip")

    # Do work that doesn't depend on an Internet download while we wait
    merc = Proj4.Projection(Proj4.epsg[3395]) # Use Mercator because to preserves direction
    wgs84 = Proj4.Projection(Proj4.epsg[4326]) # Input isn't really WGS84 but close enough

    cfsfname = fetch(cfsfut)
    # Just throw errors for this non-operational case
    if isa(cfsfname, DomainError)
        throw(cfsname)
    end

    # Open the file. Since we're only opening one, there's no harm in doing it this way
    grib = GRIB.GribFile(cfsfname)

    # Filter for the messages we want (500 hPa Z, T, U, and V)
    wanted = filter(grib) do msg
        msg["level"] == 500 && msg["shortName"] ∈ ["t", "gh", "u", "v"]
    end

    # We don't know their order, but we can use filter to disambiguate them
    # Spawn a thread to uncompress the values as we go because that takes a while
    umsg = only(filter(msg -> msg["shortName"] == "u", wanted))
    ufut = Threads.@spawn umsg["values"]
    vmsg = only(filter(msg -> msg["shortName"] == "v", wanted))
    vfut = Threads.@spawn vmsg["values"]
    heightmsg = only(filter(msg -> msg["shortName"] == "gh", wanted))
    heightfut = Threads.@spawn heightmsg["values"]
    tempmsg = only(filter(msg -> msg["shortName"] == "t", wanted))
    tempfut = Threads.@spawn tempmsg["values"]

    # While the messages could have different grids, we know from prior examination that they don't
    lats = reshape(heightmsg["latitudes"], heightmsg["Ni"], heightmsg["Nj"])
    lons = reshape(heightmsg["longitudes"], heightmsg["Ni"], heightmsg["Nj"])

    # Subset to the NW quadrant so we don't have to deal with periodicity
    goodlats = findall(l -> 0. < l < 84., lats[1, 1:end])
    goodlons = findall(l -> 180. < l < 360., lons[1:end, 1])
    lats = permutedims(lats[goodlons, goodlats])
    lons = map(x -> x - 360, permutedims(lons[goodlons, goodlats]))

    # Calculate Mercator projection (it's fine because it preserves direction)
    xs, ys = map([1, 2]) do i
         a = map(x -> Proj4.transform(wgs84, merc, [x[1], x[2]]), zip(lons, lats))
         getindex.(a, i)
    end

    xs = reshape(xs, size(lats))
    ys = reshape(ys, size(lats))

    # Wait on u and v and compute ζ
    us = permutedims(fetch(ufut)[goodlons, goodlats])
    vs = permutedims(fetch(vfut)[goodlons, goodlats])
    ζ = map(value -> value * 1e5, relative_vorticity(us, vs, xs, ys))

    # Plot filled ζ contours
    PyPlot.figure(figsize=(12., 8.))
    fills = PyPlot.contourf(lons, lats, ζ, 5:50)

    # Next come the state lines
    nestates = fetch(statesfut)
    for row in nestates
        if row.iso_a2 ∈ ["US", "CA"]
            linestring = coordinates(coordinates(Shapefile.shape(row))[1])[1]
            shapex, shapey = map([1, 2]) do i
                a = coordinates(linestring)
                getindex.(a, i)
            end
            PyPlot.plot(shapex, shapey, color="brown", linewidth=1, marker=nothing)
        end
    end

    # Then country lines 
    necountries = fetch(countriesfut)
    for row in necountries
        if row.CONTINENT == "North America"
            linestring = coordinates(coordinates(Shapefile.shape(row))[1])[1]
            shapex, shapey = map([1, 2]) do i
                a = coordinates(linestring)
                getindex.(a, i)
            end
            PyPlot.plot(shapex, shapey, color="brown", linewidth=1, marker=nothing)
        end
    end    

    # Plot contour lines of height 
    heights = map(value -> value / 10, permutedims(fetch(heightfut)[goodlons, goodlats]))
    PyPlot.contour(lons, lats, heights, 492:6:600, colors="k")

    # Plot wind barbs 
    ukt = map(mps_to_kt, us)
    vkt = map(mps_to_kt, vs)
    barbstep = 6
    PyPlot.barbs(lons[1:barbstep:end, 1:barbstep:end], lats[1:barbstep:end, 1:barbstep:end], ukt[1:barbstep:end, 1:barbstep:end], vkt[1:barbstep:end, 1:barbstep:end])

    # Plot prettiness
    timestr = Dates.format(cfstime, "yyyy-mm-dd HHZ")
    PyPlot.title("CFS 500 hPa Analysis at $timestr\nGeopotential Height (dam, contour), Relative Vorticity (\$10^{-5} s^{-1}\$, shaded), Wind (kt)")
    PyPlot.xlim(-130, -55)
    PyPlot.ylim(20, 60)
    PyPlot.colorbar(fills)
    PyPlot.savefig("output.png")
end
main()

end # module

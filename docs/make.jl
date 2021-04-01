using Documenter
using GRIB

makedocs(
    sitename = "GRIB.jl Documentation",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [GRIB],
    authors = "Alex Weech and contributors",
    pages = [
        "Home" => "index.md",
        "Manual" => ["gribfile.md", "message.md", "indexer.md", "nearest.md"]
    ]
)


deploydocs(
    repo = "github.com/weech/GRIB.jl.git"
)

using BinDeps
import CondaBinDeps

@BinDeps.setup
eccodes = library_dependency("eccodes", aliases=["libeccodes"])

CondaBinDeps.Conda.add_channel("conda-forge")
provides(CondaBinDeps.Manager, "eccodes", eccodes)

@BinDeps.install Dict(:eccodes => :eccodes)
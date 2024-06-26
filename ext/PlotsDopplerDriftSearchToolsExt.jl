module PlotsDopplerDriftSearchToolsExt

using DopplerDriftSearchTools: clusterrange
import DopplerDriftSearchTools: clusterheatmap, waterfall

if isdefined(Base, :get_extension)
    import Plots: heatmap, scatter!, plot!, default
else
    import ..Plots: heatmap, scatter!, plot!, default
end

"""
    clusterheatmap(cijs, matrix, border=0; overlay=true, kwargs...)

Create a heatmap plot of the region of `matrix` that spans `cijs`.  The region
plotted may be extended by `border` (see [`clusterrange`](@ref)).  If `overlay`
is true, the points in `cijs` will be highlighted using `scatter!`; if `overlay`
is `false` or `nothing`, no points will be highlighted; otherwise, `overlay` is
treated as a list of points that will be highlighted using `scatter!`.  When
points are highlighted, `kwargs...` will get passed to `scatter!`.

`cijs` should be given as a list of `CartesianIndex` values or as a
`CartesianIndices` region, but in the latter case `overlay` is ignored.
"""
function clusterheatmap(cijs, matrix,
    border::CartesianIndex{2}=CartesianIndex((0,0)); overlay=true, kwargs...
)
    isempty(cijs) && error("no points to plot")
    crange = clusterrange(cijs, matrix, border)
    xx, yy = crange.indices

    p = heatmap(xx, yy, (@view matrix[crange])'; cbar=get(kwargs, :cbar, true))

    if overlay !== nothing && overlay !== false
        (overlay === true) && (overlay = cijs)
        scatter!(p, Tuple.(overlay);
            ms=1, msw=0, widen=false, legend=false,
            alpha=0.5, color=:green,
            kwargs...
        )
    end
    p
end

# clusterheatmap (border converters)

function clusterheatmap(cijs, matrix, border; overlay=true, kwargs...)
    clusterheatmap(cijs, matrix, CartesianIndex(border); overlay, kwargs...)
end

function clusterheatmap(cijs, matrix, border::Int; overlay=true, kwargs...)
    clusterheatmap(cijs, matrix, CartesianIndex((border, border));
                   overlay, kwargs...)
end

# clusterheatmap CartesianIndices region

function clusterheatmap(region::CartesianIndices, matrix,
    border::CartesianIndex{2}=CartesianIndex((0,0)); overlay=false, kwargs...
)
    kwargs = (; kwargs..., overlay=false)
    clusterheatmap(vec(region), matrix, border; kwargs...)
end

# clusterheatmap CartesianIndices region (border converters)

function clusterheatmap(region::CartesianIndices, matrix, border;
    overlay=false, kwargs...
)
    clusterheatmap(region, matrix, CartesianIndex(border); kwargs...)
end

function clusterheatmap(region::CartesianIndices, matrix, border::Int;
    overlay=false, kwargs...
)
    clusterheatmap(region, matrix, CartesianIndex((border, border)); kwargs...)
end

"""
    waterfall(ftmatrix, chan, rate, dfdt=1; nchans=0, kwargs...)

Make a heatmap plot of a portion of `ftmatrix` and overlay a diagonal line
starting at `chan` with a "slope" of `rate`.  `ftmatrix` is assumed to be a
frequency-time *spectrogram* with the first dimension spanning frequency
channels and the second dimension spanning time samples.  The heatmap plot will
have a horizontal frequency axis and a vertical (increasing downward!) time
axis.

The `ftmatrix` channel specified by `chan` will be at the center of the
region plotted.  The slope of the overlay line in units of frequency channels
per timestep is `rate/dfdt`.  If `rate` is in `Hz/s`, `dfdt` should also be in
`Hz/s` (e.g. `channel_width_hz/timestep_sec`).  If `rate` is given in units of
frequency channels per timestemp, then `dfdt` should be given as 1, which is its
default value if not given.

The number of channels plotted is given by `nchans`.  If it is less than or
equal to 0 (the default), the number of channels plotted will be determines such
that the overlay line ends up as the first or last channel plotted, depending on
its sign, or `2*ntime+1` if `rate≈0` where `ntime=size(ftmatrix,2)`.

The `kwargs` are all passed on to `heatmap` except for `la`, 'lc', `ls`, 'lw',
which are passed on to `plot!` when plotting the diagonal overlay line.  The
long forms of the 4 kwargs passed to `plot!` are **not** similarly handled and
will be passed to `heatmap`.

- `la`: Line Alpha - 0 (transparent) to 1 (opaque)
- `lc`: Line Color - standard Plots.jl color
- `ls`: Line Style - standard Plots.jl line style options plus `:none`
- `lw`: Line Width - pixels

Passing `ls=:none` (not a valid Plots.jl option) will prevent the overlay line
from being plotted.
"""
function waterfall(ftmatrix, chan, rate, dfdt=1; nchans=0,
                   lw=default(:lw), lc=:red, ls=default(:ls), la=default(:la),
                   kwargs...)
    if nchans <= 0
        ntime = size(ftmatrix, 2)
        if rate ≈ 0
            nchans = 2 * ntime + 1
            chans = range(chan-nchans÷2, length=nchans)
        else
            dchan = Int(ceil((ntime-1) * rate / dfdt))
            dchans = extrema((-dchan, dchan)) #.+ (-growf, growf)
            #dchans = (-150, 150) # should be +/- max drift rate * total time
            chans = range((chan.+dchans)...)
        end
    else
        chans = range(chan-nchans÷2, length=nchans)
    end
    times = axes(ftmatrix, 2)
    p = heatmap(chans, times, (@view ftmatrix[chans, :])';
        xlabel="Fine Channel",
        ylabel="Time Step",
        yflip=true, kwargs...
    )
    if ls != :none
        plot!(p, evalpoly.(times.-1, Ref((chan, rate/dfdt))), times; lw, ls, la,
            lc, legend=false, widen=false, yflip=true, xlims=extrema(chans)
        )
    end
    p
end

end # module PlotsDopplerDriftSearchToolsExt

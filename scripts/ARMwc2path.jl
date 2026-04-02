using DrWatson
@quickactivate "MigratoryConvection"

using Dates, Statistics
using ARMLive
using Trapz

ads = ARMDataset(
    stream = "sgpmicrobasepi2C1.c1",
    start = Date(1996), stop = Date(2010,12,31), path = datadir()
)

nz = 512
nt = 8640

tz    = zeros(Float32,nz+1); iz = @views tz[2:end]
tt    = range(0, 86400, length=nt+1); tt = tt[1:(end-1)]

vname = "ice_water"

dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
attribs = Vector{Dict}(undef,2)

wpath = zeros(nt,ndt)

for idt in 1 : ndt

    ids = read(ads,"$(vname)_content",dtvec[idt],throw=false)
    if !isnothing(ids)
        attribs[1] = Dict(ids.attrib)
        attribs[2] = Dict(ids["$(vname)_content"].attrib)

        NCDatasets.load!(ids["height"].var,iz,:)
        tdata = nomissing(ids["$(vname)_content"][:,:],0)
        inum  = .!isnan.(nomissing(ids["$(vname)_content"][:,:],NaN))

        for it = 1 : nt

            wpath[it, idt] = trapz(tz, vcat(0,view(tdata, :, it)))

        end

        close(ids)
        
    end

end

fnc = joinpath(ads.path,"$(ads.stream)-$(vname)_path-$(ads.start)-$(ads.stop).nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c",attrib=attribs[1])

defDim(ds,"time",  nt*ndt)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "hours since $(ads.start) 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncwc = defVar(ds,"$(vname)_path",Float64,("time",),attrib=attribs[2])

nct[:] = collect(0 : 86400/nt : (86400*ndt))[1:(end-1)]
ncwc[:] = wpath[:]

close(ds)
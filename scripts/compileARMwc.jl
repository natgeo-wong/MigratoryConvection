using DrWatson
@quickactivate "MigratoryConvection"

using Dates, Statistics
using ARMLive

ads = ARMDataset(
    stream = "sgpmicrobasekaplusC1.c1",
    start = Date(2011), stop = Date(2021,12,31), path = datadir()
)

data = zeros(596,21600,12)
inum = zeros(596,21600,12)
z    = zeros(Float32,596)

vname = "liquid_water_content"

dtvec = Date(2011) : Day(1) : Date(2021,12,31); ndt = length(dtvec)
attribs = Vector{Dict}(undef,4)

for idt in dtvec

    imo = month(idt)
    ids = read(ads,vname,idt,throw=false)
    if !isnothing(ids)
        attribs[1] = Dict(ids.attrib)
        attribs[2] = Dict(ids["height"].attrib)
        attribs[3] = Dict(ids["time"].attrib)
        attribs[4] = Dict(ids[vname].attrib)
        z[:]           =                  ids["height"][:]
        data[:,:,imo] +=        nomissing(ids[vname][:,:],0)
        inum[:,:,imo] += isnan.(nomissing(ids[vname][:,:],NaN))
        close(ids)
    end

end

data ./= inum
ydata  = dropdims(mean(data,dims=3),dims=3)
data = cat(data,ydata,dims=3)

fnc = joinpath(ads.path,"compiled-$(Dates.format(dtvec[1],dateformat"yyyymmdd"))_$(Dates.format(dtvec[end],dateformat"yyyymmdd")).nc")
ds = NCDataset(fnc,"w",attrib=attribs[1])

defDim(ds,"height",596)
defDim(ds,"time",  21600)
defDim(ds,"month", 13)

ncz  = defVar(ds,"height",Float32,("height",),attrib=attribs[2])
nct  = defVar(ds,"time",Int32,("time",),attrib=attribs[3])
ncwc = defVar(ds,vname,Float64,("height","time","month"),attrib=attribs[4])

ncz[:] = z
nct[:] = collect(0 : 4 : 86400)[1:(end-1)]
ncwc[:,:,:] = data

close(ds)
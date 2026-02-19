using DrWatson
@quickactivate "MigratoryConvection"

using Dates, Statistics
using ARMLive

ads = ARMDataset(
    stream = "sgpmicrobasekaplusC1.c1",
    start = Date(2011), stop = Date(2021,12,31), path = datadir()
)

nz = 596
nt = 21600

data = zeros(nz,nt,12)
inum = zeros(Int32,nz,nt,12)
z    = zeros(Float32,nz)

vname = "liquid_water_content"

dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
attribs = Vector{Dict}(undef,4)

for idt in dtvec

    imo = month(idt)
    ids = read(ads,vname,idt,throw=false)
    if !isnothing(ids)
        attribs[1] = Dict(ids.attrib)
        attribs[2] = Dict(ids["height"].attrib)
        attribs[3] = Dict(ids["time"].attrib)
        attribs[4] = Dict(ids[vname].attrib)
        z[:]           =                    ids["height"][:]
        data[:,:,imo] +=          nomissing(ids[vname][:,:],0)
        inum[:,:,imo] += .!isnan.(nomissing(ids[vname][:,:],NaN))
        close(ids)
    end

end

data ./= inum
ydata  = dropdims(mean(data,dims=3),dims=3)
data = cat(data,ydata,dims=3)

fnc = joinpath(ads.path,"diurnal-$(vname)-$(Dates.format(dtvec[1],dateformat"yyyymmdd"))_$(Dates.format(dtvec[end],dateformat"yyyymmdd")).nc")
ds = NCDataset(fnc,"c",attrib=attribs[1])

defDim(ds,"height",nz)
defDim(ds,"time",  nt)
defDim(ds,"month", 13)

ncz  = defVar(ds,"height",Float32,("height",),attrib=attribs[2])
nct  = defVar(ds,"time",Int32,("time",),attrib=attribs[3])
ncwc = defVar(ds,vname,Float64,("height","time","month"),attrib=attribs[4])
ncin = defVar(ds,"number",Int32,("height","time","month"))

ncz[:] = z
nct[:] = collect(0 : Int(86400/nt) : 86400)[1:(end-1)]
ncwc[:,:,:] = data
ncin[:,:,:] = cat(inum,sum(inum,dims=3),dims=3)

close(ds)
using DrWatson
@quickactivate "MigratoryConvection"

using Dates, Statistics
using ARMLive

function loadstandardized!(data,inum,ads,vname)
    dtvec = ads.start : Day(1) : ads.stop
    for idt in dtvec

        dtstr = Dates.format(idt,dateformat"yyyymmdd")
        fnc = joinpath(ads.path,dtstr[1:4],dtstr[5:6],"$(dtstr)000000-$vname-standardized.nc")
        if isfile(fnc)
            ids = NCDataset(fnc)
            imo = month(idt)
            data[:,:,imo] +=          nomissing(ids[vname][:,:],0)
            inum[:,:,imo] += .!isnan.(nomissing(ids[vname][:,:],NaN))
            close(ids)
        end

    end
end

z = collect(0 : 100 : 20e3); nz = length(z) - 1
t = collect(0 : 60 : 86400); nt = length(t) - 1
data = zeros(nz,nt,13)
inum = zeros(nz,nt,13)

vname = "liquid_water_content"

ads = ARMDataset(
    stream = "sgpmicrobasepi2C1.c1",
    start = Date(1997), stop = Date(2010,12,31), path = datadir()
)
loadstandardized!(data,inum,ads,vname)

ads = ARMDataset(
    stream = "sgpmicrobasekaplusC1.c1",
    start = Date(2011), stop = Date(2021,12,31), path = datadir()
)
loadstandardized!(data,inum,ads,vname)

data ./= inum
ydata  = dropdims(mean(data,dims=3),dims=3)
data = cat(data,ydata,dims=3)

fnc = datadir("ARM","sgpmicrobase-diurnal-$(vname).nc")
ds = NCDataset(fnc,"c")

defDim(ds,"height",nz)
defDim(ds,"time",  nt)
defDim(ds,"height_bounds",nz+1)
defDim(ds,"time_bounds",  nt+1)
defDim(ds,"month", 13)

ncz  = defVar(ds,"height_bounds",Float32,("height_bounds",))
nct  = defVar(ds,"time_bounds",Int32,("time_bounds",))
ncwc = defVar(ds,vname,Float64,("height","time","month"))
ncin = defVar(ds,"number",Int32,("height","time","month"))

ncz[:] = collect(z)
nct[:] = collect(t)
ncwc[:,:,:] = data
ncin[:,:,:] = cat(inum,sum(inum,dims=3),dims=3)

close(ds)
using DrWatson
@quickactivate "MovingConvection"

using NCDatasets
using Dates
using DelimitedFiles
using Printf

stn = "SGP"
ds  = NCDataset(datadir("MCStracks","DCStimeseries_20140101_20201231_$(stn).nc"))
dtv = ds["time"][:]
DCS = ds["DCS_number"][:]
Tb  = ds["Tb"][:]
close(ds)

IDvec = unique(DCS)[2:end]; nID = sum(IDvec)

sdt   = zeros(Int,nID,2400)
slon  = zeros(nID,2400)
slat  = zeros(nID,2400)
ssize = zeros(nID,2400)

lon = collect(-127 : 0.04 : -65); nlon = length(lon)
lat = collect(50 : -0.04 : 24);   nlat = length(lat)
lon = repeat(lon',nlat,1)
lat = repeat(lat,1,nlon)

for (iID,ID) in enumerate(IDvec)

    @info "Retrieving evolutionary statistics for MCS that occurred over the $name ARM site for $dt"; flush(stderr)
    dt1 = Date(dtv[findfirst(IDvec.==ID)]) - Day(10)
    dt2 = Date(dtv[findlast(IDvec.==ID)]) + Day(10)

    ii = 0

    for (ii,dt) in dt1 : Day(1) : dt2

        dtstr = Dates.format(dt,dateformat"yyyymmdd")
        ds = NCDataset(datadir("MCStracks","gpm_mapTb_US","$(dtstr)_TbExpand_US.nc"))

        for it = 1 : 48

            idcs = ds["DCS_number"][:,:,it]
            if !iszero(sum(idcs.==ID))
                ii += 1
                sdt[iID,ii]   = Dates.value(Minute(DateTime(dt) + Minute(30*(it-1)) - DateTime(2014,1,1)))
                slon[iID,ii]  = mean(lon[idcs.==ID])
                slat[iID,ii]  = mean(lat[idcs.==ID])
                ssize[iID,ii] = sum(sind.(lat[idcs.==ID])) * (2pi*6371 * 0.04/360)^2
            end

        end

        close(ds)

    end

end

nt = findlast(.!iszero.(sum(ssize,dims=1)))

nfnc = datadir("MCStracks","MCSstats-$(Dates.format(dtvec[1],dateformat"yyyymmdd"))_$(Dates.format(dtvec[end],dateformat"yyyymmdd"))-$(stn).nc")
isfile(nfnc) ? rm(nfnc,force=true) : nothing

ds = NCDataset(nfnc,"c")

ds.attrib["title"] = "Statistics for MCS that pass over $(name) ($stn)"
ds.attrib["site_name"] = name
ds.attrib["site_id"] = stn
ds.attrib["site_lon"] = slon
ds.attrib["site_lat"] = slat
ds.attrib["source"] = "TOOCAN MCS tracking (Greg Elsaesser)"
ds.attrib["created"] = string(now())

defDim(ds,"system",nID)
defDim(ds,"time",nt)

nctime = defVar(ds,"time",Int,("system","time",),attrib=Dict(
    "units"     => "minutes since 2014-01-01 00:00:00",
    "calendar"  => "standard",
    "long_name" => "Time"
))

nclon = defVar(ds,"centroid_longitude",Float64,("system","time",),attrib=Dict(
    "long_name" => "Centroid Longitude of System",
    "units"     => "degrees_east",
))

nclat = defVar(ds,"centroid_latitude",Float64,("system","time",),attrib=Dict(
    "long_name" => "Centroid Latitude of System",
    "units"     => "degrees_north",
))

ncsize = defVar(ds,"size",Float64,("system","time",),attrib=Dict(
    "long_name" => "Approximate Size of System",
    "units"     => "km**2",
))

nctime.var[:,:] = sdt[:,1:nt]
nclon.var[:,:]  = slon[:,1:nt]
nclat.var[:,:]  = slat[:,1:nt]
ncsize.var[:,:] = ssize[:,1:nt]

close(ds)
using DrWatson
@quickactivate "MigratoryConvection"

using Dates
using DelimitedFiles
using Logging
using Printf
using NCDatasets

stn = "SGP"
name,slon,slat = readdlm(datadir("ARMstations_$(stn).csv"),',',skipstart=1)[1,[2,5,6]]
tlon = -180 : 0.04 : 180; pop!(tlon)
tlat = 40 : -0.04 : -40
ilon = argmin(abs.(tlon.-slon))
ilat = argmin(abs.(tlat.-slat))

dtvec = Date(2014) : Day(1) : Date(2020,12,31); ndt = length(dtvec)
idvec = zeros(Int,48,ndt)
Tbvec = zeros(Float32,48,ndt)

for (idt,dt) in enumerate(dtvec)

    dtstr = Dates.format(dt,dateformat"yyyymmdd")
    fnc = datadir("MCStracks","gpm_mapTb","$(dtstr)_TbExpand.nc")
    if isfile(fnc)
        @info "Retrieving Tb and DCS ID over the $name ARM site for $dt"; flush(stderr)
        ids = NCDataset(fnc)
        idvec[:,idt] .= nomissing(ids["DCS_number"][ilon,ilat,:],0)
        Tbvec[:,idt] .= nomissing(ids["Tb"][ilon,ilat,:],NaN)
        close(ids)
    end

end

idvec = idvec[:]
Tbvec = Tbvec[:]

nfnc = datadir("MCStracks","DCStimeseries_$(Dates.format(dtvec[1],dateformat"yyyymmdd"))_$(Dates.format(dtvec[end],dateformat"yyyymmdd"))_$(stn).nc")
isfile(nfnc) ? rm(nfnc,force=true) : nothing

ds = NCDataset(nfnc,"c")

ds.attrib["title"] = "MCS timeseries at $(name) ($stn)"
ds.attrib["site_name"] = name
ds.attrib["site_id"] = stn
ds.attrib["site_lon"] = slon
ds.attrib["site_lat"] = slat
ds.attrib["grid_lon"] = tlon[ilon]
ds.attrib["grid_lat"] = tlat[ilat]
ds.attrib["source"] = "TOOCAN MCS tracking (Greg Elsaesser)"
ds.attrib["created"] = string(now())

defDim(ds,"time",ndt*48)

nctime = defVar(ds,"time",Int,("time",),attrib=Dict(
    "units"     => "minutes since 2014-01-01 00:00:00",
    "calendar"  => "standard",
    "long_name" => "Time"
))

ncdcs = defVar(ds,"DCS_number",Int,("time",),attrib=Dict(
    "long_name" => "TOOCAN Deep Convective System number",
))

ncTb = defVar(ds,"Tb",Float32,("time",),attrib=Dict(
    "long_name" => "Brightness Temperature",
    "units"     => "K",
))

nctime.var[:] = (collect(1:(ndt*48)) .- 1) * 30
ncdcs.var[:]  = idvec
ncTb.var[:]   = Tbvec

close(ds)
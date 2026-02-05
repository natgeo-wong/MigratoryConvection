using DrWatson
@quickactivate "MigratoryConvection"

using Dates
using Logging
using Printf
using GeoRegions
using RegionGrids
using NCDatasets

function saveDCS(
    ggrd :: RegionGrid,
    dt   :: Date,
    DCS  :: AbstractArray{<:Real,3},
    Tb   :: AbstractArray{<:Real,3},
    attr :: Vector{Dict}
)

    dtstr = Dates.format(dt,dateformat"yyyymmdd")
    fnc = datadir("MCStracks","gpm_mapTb","$(dtstr)_TbExpand_US.nc")
    isfile(fnc) ? rm(fnc,force=true) : nothing
    ds = NCDataset(fnc,"c",attrib=attr[1])

    ds.attrib["created"] = string(now())

    defDim(ds,"longitude",length(ggrd.lon))
    defDim(ds,"latitude",length(ggrd.lat))
    defDim(ds,"time",48)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib=Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude"
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib=Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude"
    ))

    nctime = defVar(ds,"time",Int32,("time",),attrib=Dict(
        "units"     => "minutes since $(dt) 00:00:00",
        "calendar"  => "standard",
        "long_name" => "time"
    ))

    ncDCS = defVar(ds,"DCS_number",Int32,("longitude","latitude","time"),chunksizes=(517, 401, 1),shuffle=true,deflatelevel=4,attrib=attr[2])
    ncTb  = defVar(ds,"Tb",Float32,("longitude","latitude","time"),chunksizes=(517, 401, 1),shuffle=true,deflatelevel=4,attrib=attr[3])

    nclon[:]  = ggrd.lon
    nclat[:]  = ggrd.lat
    nctime[:] = collect(0 : 47) * 30
    ncDCS[:,:,:] = DCS
    ncTb[:,:,:]  = Tb

    close(ds)

end

geo  = GeoRegion([-127,-127,-65,-65,-127],[24,50,50,24,24])
tlon = collect(-180 : 0.04 : 180); pop!(tlon); nlon = length(tlon)
tlat = collect(40 : -0.04 : -40);              nlat = length(tlat)
ggrd = RegionGrid(geo,tlon,tlat)
nnlon = length(ggrd.lon)
nnlat = length(ggrd.lat)

oDCS = zeros(Int32,nlon,nlat,48)
oTb  = zeros(Float32,nlon,nlat,48)

nDCS = zeros(Int32,nnlon,nnlat,48)
nTb  = zeros(Float32,nnlon,nnlat,48)
attr = Vector{Dict}(undef,3)

for (idt,dt) in enumerate(Date(2014) : Day(1) : Date(2020,12,31))

    dtstr = Dates.format(dt,dateformat"yyyymmdd")
    fnc = datadir("MCStracks","gpm_mapTb","$(dtstr)_TbExpand.nc")
    if isfile(fnc)
        @info "Extracting Tb and DCS ID over the US for $dt"; flush(stderr)
        ids = NCDataset(fnc)
        NCDatasets.load!(ids["DCS_number"].var,oDCS,:,:,:)
        NCDatasets.load!(ids["Tb"].var,oTb,:,:,:)

        attr[1] = Dict(ids.attrib)
        attr[2] = Dict(ids["DCS_number"].attrib)
        attr[3] = Dict(ids["Tb"].attrib)
        close(ids)

        extract!(nDCS,oDCS,ggrd)
        extract!(nTb, oTb, ggrd)

        saveDCS(ggrd,dt,nDCS,nTb,attr)
    end

end
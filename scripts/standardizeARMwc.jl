using DrWatson
@quickactivate "MigratoryConvection"

using Dates, Statistics
using ARMLive

ads = ARMDataset(
    stream = "sgpmicrobasepi2C1.c1",
    start = Date(1996), stop = Date(2010,12,31), path = datadir()
)

nz = 512
nt = 8640

tz    = zeros(Float32,nz)
tt    = range(0, 86400, length=nt+1); tt = tt[1:(end-1)]

z = 0 : 100 : 20e3; nnz = length(z) - 1
t = 0 : 60 : 86400; nnt = length(t) - 1
data = zeros(nnz,nnt)

vname = "ice_water_content"

dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
attribs = Vector{Dict}(undef,4)

for idt in dtvec

    dtstr = Dates.format(idt,dateformat"yyyymmdd")
    imo = month(idt)
    ids = read(ads,vname,idt,throw=false)
    if !isnothing(ids)
        attribs[1] = Dict(ids.attrib)
        attribs[2] = Dict(ids["height"].attrib)
        attribs[3] = Dict(ids["time"].attrib)
        attribs[4] = Dict(ids[vname].attrib)

        NCDatasets.load!(ids["height"].var,tz,:)
        tdata = nomissing(ids[vname][:,:],0)
        inum  = .!isnan.(nomissing(ids[vname][:,:],NaN))

        for it = 1 : nnt, iz = 1 : nnz

            tb = t[it]; te = t[it+1]
            zb = z[iz]; ze = z[iz+1]

            iit = (tt .>= tb) .& (tt .<= te)
            iiz = (tz .>= zb) .& (tz .<= ze)

            if !iszero(sum(iit)) && !iszero(sum(iiz))
                iit = findfirst(iit) : findlast(iit)
                iiz = findfirst(iiz) : findlast(iiz)
                data[iz,it] = sum(view(tdata,iiz,iit)) ./ sum(view(inum,iiz,iit))
            else
                data[iz,it] = NaN
            end

        end

        close(ids)

        fnc = joinpath(ads.path,dtstr[1:4],dtstr[5:6],"$(dtstr)000000-$vname-standardized.nc")
        ds = NCDataset(fnc,"c",attrib=attribs[1])

        defDim(ds,"height",nnz)
        defDim(ds,"time",  nnt)
        defDim(ds,"height_bounds",nnz+1)
        defDim(ds,"time_bounds",  nnt+1)

        ncz  = defVar(ds,"height_bounds",Float32,("height_bounds",),attrib=attribs[2])
        nct  = defVar(ds,"time_bounds",Int32,("time_bounds",),attrib=attribs[3])
        ncwc = defVar(ds,vname,Float64,("height","time"),attrib=attribs[4])

        ncz[:] = collect(z)
        nct[:] = collect(t)
        ncwc[:,:] = data

        close(ds)
    end

end
using Dates
using ERA5Reanalysis
using NCDatasets
using Printf

## DateString Aliasing
yrmo2dir(date::TimeType) = Dates.format(date,dateformat"yyyy/mm")
yrmo2str(date::TimeType) = Dates.format(date,dateformat"yyyymm")
yr2str(date::TimeType)   = Dates.format(date,dateformat"yyyy")
ymd2str(date::TimeType)  = Dates.format(date,dateformat"yyyymmdd")

function read_climatology(
    armID :: String,
    e5ds  :: ERA5Hourly,
    evar  :: ERA5Variable;
    days  :: Int = 0
)

    if iszero(days)
        return NCDataset(joinpath(e5ds.path,"climatology",
            armID * "-" * evar.ID * "-" * 
            ymd2str(e5ds.start) * "-" * ymd2str(e5ds.stop) * ".nc"
        ))
    else
        return NCDataset(joinpath(e5ds.path,"climatology",
            armID * "-" * evar.ID * "-" * 
            ymd2str(e5ds.start) * "-" * ymd2str(e5ds.stop) * "-" *
            "smooth$(@sprintf("%02d",days))days.nc"
        ))
    end

end
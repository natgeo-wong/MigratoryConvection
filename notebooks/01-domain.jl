### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ 16c7e940-f1b5-11ef-027b-ffed5bebb310
begin
    using Pkg; Pkg.activate()
    using DrWatson
end

# ╔═╡ 2dd9c606-8ab2-484e-8155-f2c908418fe0
begin
    @quickactivate "MigratoryConvection"
	using PlutoUI
    using Dates, DelimitedFiles
    using ETOPO
    using GeoJSON
    using CairoMakie, LaTeXStrings
    set_theme!(theme_latexfonts())
    md"Activating Project Environment for S2DExploration ..."
end

# ╔═╡ 2f6fac9c-a075-403b-a696-1fcb095f72d8
md"
# 01. Spatial Distribution of ARM Stations
"

# ╔═╡ a6877704-98ed-44fd-9ef7-55ec19202079
TableOfContents()

# ╔═╡ 13c98981-24fe-454b-8f46-28a243525cd9
md"
### A. Loading ARM Station and Plotting Data
"

# ╔═╡ 74a03763-63d0-4a16-9586-f55a5a3aed6f
geo_plot = GeoRegion([-110,-75,-75,-110,-110],[25,25,45,45,25])

# ╔═╡ 7038130a-cfcc-4e3b-a7e7-64157f0ab69b
begin    
    sgp_info = readdlm(datadir("ARMstations_SGP.csv"),',',skipstart=1)[:,1:6]
    bnf_info = readdlm(datadir("ARMstations_BNF.csv"),',',skipstart=1)[:,1:6]
    sgp_info = sgp_info[.!isnan.(sgp_info[:,5]),:]
    bnf_info = bnf_info[.!isnan.(bnf_info[:,5]),:]
    
    sgp_info[sgp_info[:,4].=="N/A",4] .= "$(Date(now()))"
    sgp_info[:,3]  = Date.(sgp_info[:,3])
    sgp_info[:,4]  = Date.(sgp_info[:,4])

    nsgp = size(sgp_info,1)
    nbnf = size(bnf_info,1)
    md"Loading ARM station coordinates in the Southern Great Plains"
end

# ╔═╡ d3245994-1745-4f50-9512-14db7ad76527
begin
    states = GeoJSON.read(read(datadir("us-states.json"), String))
    md"Loading boundary data for states ..."
end

# ╔═╡ cd72582b-11cf-4697-887c-0b76fd88fe86
etpd = ETOPODataset(path=datadir())

# ╔═╡ 9e7eb0df-58b6-4bad-9e85-709647576360
lsd = getLandSea(etpd,geo_plot,save=false)

# ╔═╡ c8524322-c53d-485e-bd68-e154add31d3b
begin
    coast = readdlm(datadir("coast.cst"),comments=true)
    xc = coast[:,1]
    yc = coast[:,2]
    md"Loading Coastline Data ..."
end

# ╔═╡ 9ec24adf-9adf-4f31-99b9-f7a13e1efa2d
md"
### B. Spatial Distribution of ARM Stations
"

# ╔═╡ b33690e2-9200-4a00-b010-ca0fe45bfd49
begin
    fig = Figure()
    
    axs = Axis(
        fig[1,1],width=500,height=300,limits=(-100,-85,29,38),
		xticks=-100:5:-70,xminorticks=-100:70,xminorticksvisible=true,
		yticks=25:5:40,yminorticks=29:40,yminorticksvisible=true,
        xlabel=L"Longitude / $\degree$",ylabel=L"Latitude / $\degree$"
    )
    c = heatmap!(axs,
		lsd.lon[1:2:end],lsd.lat[1:2:end],lsd.z[1:2:end,1:2:end] ./1e3,
		colorrange=(-.5,.5),colormap=:topo
	)
    scatter!(axs,sgp_info[1,5],sgp_info[1,6],color=:red,markersize=15)
    scatter!(axs,bnf_info[1,5],bnf_info[1,6],color=:red,markersize=15)

    for state in states
	    poly!(axs,state.geometry;color=:transparent,strokecolor=:black,strokewidth=1)
	end

    Colorbar(fig[1,2], c, label="Topographic Height / km")
    resize_to_layout!(fig)
    fig
end

# ╔═╡ 3b93f80c-ddab-4c6c-ad79-feb894d9e6a0
CairoMakie.save(plotsdir("01-domainofinterest.png"),fig)

# ╔═╡ Cell order:
# ╟─2f6fac9c-a075-403b-a696-1fcb095f72d8
# ╟─16c7e940-f1b5-11ef-027b-ffed5bebb310
# ╟─2dd9c606-8ab2-484e-8155-f2c908418fe0
# ╟─a6877704-98ed-44fd-9ef7-55ec19202079
# ╟─13c98981-24fe-454b-8f46-28a243525cd9
# ╠═74a03763-63d0-4a16-9586-f55a5a3aed6f
# ╟─7038130a-cfcc-4e3b-a7e7-64157f0ab69b
# ╟─d3245994-1745-4f50-9512-14db7ad76527
# ╟─cd72582b-11cf-4697-887c-0b76fd88fe86
# ╟─9e7eb0df-58b6-4bad-9e85-709647576360
# ╟─c8524322-c53d-485e-bd68-e154add31d3b
# ╟─9ec24adf-9adf-4f31-99b9-f7a13e1efa2d
# ╠═b33690e2-9200-4a00-b010-ca0fe45bfd49
# ╟─3b93f80c-ddab-4c6c-ad79-feb894d9e6a0

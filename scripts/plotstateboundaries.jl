using GeoJSON
using CairoMakie

fc = GeoJSON.read(read("us-states.json", String))
fig = Figure()
axs = Axis(fig[1,1]; aspect = DataAspect())

for feature in fc
    poly!(axs, feature.geometry; color = :transparent, strokecolor = :black, strokewidth = 0.5)
end
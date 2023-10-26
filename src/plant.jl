include("world.jl");

mutable struct Plant{P<:PlantSpecies} <: Agent{P}
    const id::Int
    size::Int
    const max_size::Int
end

# constructor for all Plant{<:PlantSpecies} callable as PlantSpecies(...)
(A::Type{<:PlantSpecies})(id, s, m) = Plant{A}(id,s,m)
(A::Type{<:PlantSpecies})(id, m) = (A::Type{<:PlantSpecies})(id,rand(1:m),m)

# default specific for Grass
# Grass(id, m=10) = Grass(id, rand(1:m), 10)
Grass(id; max_size=10) = Grass(id, rand(1:max_size), max_size)

# \:herb:<tab>
# Base.show(io::IO, g::Grass) = print(io, "🌿Grass #$(g.id) $(round(Int, g.size / g.max_size * 100))% grown")
function Base.show(io::IO, p::Plant{P}) where P
    x = p.size/p.max_size * 100
    print(io,"$P  #$(p.id) $(round(Int,x))% grown")
end

Base.show(io::IO, ::Type{Grass}) = print(io,"🌿")

agent_count(agents::Vector{<:Agent}) = sum(agent_count, agents)

function agent_step!(p::Plant, w::World)
    if p.size < p.max_size # for this to work as expected, max_size must be a decimal number
        p.size += 1
    end
end
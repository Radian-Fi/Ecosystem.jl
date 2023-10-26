abstract type Species end
abstract type Agent{S<:Species} end

abstract type PlantSpecies <: Species end
abstract type Grass <: PlantSpecies end

abstract type AnimalSpecies <: Species end
abstract type Sheep <: AnimalSpecies end
abstract type Wolf <: AnimalSpecies end

mutable struct World{A<:Agent}
    agents::Dict{Int,A}
    max_id::Int
end

World(agents::Vector{<:Agent}) = World(Dict(a.id=>a for a in agents), maximum(a.id for a in agents))

# optional: overload Base.show ... copied from the lab2 solution field
function Base.show(io::IO, w::World)
    println(io, typeof(w))
    for (_,a) in w.agents
        println(io,"  $a")
    end
end

function kill_agent!(a::Agent, w::World)
    delete!(w.agents, a.id)
    #w.max_id = maximum(a.id for a in w.agents)
end

eats(::Agent, ::Agent) = false

mates(::Agent, ::Agent) = false

agent_count(agents::Vector{<:Agent}) = sum(agent_count, agents)

function agent_count(w::World)
    dict = Dict{Symbol,Real}()
    for (id, agent) in w.agents
        #key = nameof(typeof(agent))
        function op(a::Agent{S}) where S<:Species
            return nameof(S)
        end
        key = op(agent)
        if key in keys(dict)
            dict[key] += agent_count(agent)
        else
            dict[key] = agent_count(agent)
        end
    end
    return dict
end

function every_nth(f::Function, n::Int)
    i = 1
    function callback(args...)
        if i == n
            f(args...)
            i = 1
        else
            i += 1
        end
        # return i
    end
    # return callback
end

function world_step!(w::World)
    ids = copy(keys(w.agents))

    for id in ids
        #!haskey(world.agents,id) && continue
        if !haskey(w.agents, id); continue end

        agent = w.agents[id]
        agent_step!(agent, w)
    end
end
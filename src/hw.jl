abstract type Species end
abstract type Agent{S<:Species} end

abstract type PlantSpecies <: Species end
abstract type Grass <: PlantSpecies end

abstract type AnimalSpecies <: Species end
abstract type Sheep <: AnimalSpecies end
abstract type Wolf <: AnimalSpecies end


# instead of Symbols we can use an Enum for the sex field
# using an Enum here makes things easier to extend in case you
# need more than just binary sexes and is also more explicit than
# just a boolean
@enum Sex female male

# Animals

#=
mutable struct Sheep <: Animal
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
end

Sheep(id, e=4.0, Δe=0.2, pr=0.8, pf=0.6) = Sheep(id, e, Δe, pr, pf)

Base.show(io::IO, s::Sheep) = print(io, "🐑Sheep #$(s.id) E=$(s.energy) ΔE=$(s.Δenergy) pr=$(s.reprprob) pf=$(s.foodprob)")

mutable struct Wolf <: Animal
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
end

Wolf(id, e=10.0, Δe=8.0, pr=0.1, pf=0.2) = Wolf(id, e, Δe, pr, pf)

Base.show(io::IO, w::Wolf) = print(io, "🐺Wolf #$(w.id) E=$(w.energy) ΔE=$(w.Δenergy) pr=$(w.reprprob) pf=$(w.foodprob)")

function Base.show(io::IO, a::Animal{A}) where {A<:AnimalSpecies}
    e = a.energy
    d = a.Δenergy
    pr = a.reprprob
    pf = a.foodprob
    s = a.sex == female ? "♀" : "♂"
    print(io, "$A$s #$(a.id) E=$e ΔE=$d pr=$pr pf=$pf")
end

# note that for new species/sexes we will only have to overload `show` on the
# abstract species types like below!
Base.show(io::IO, ::Type{Sheep}) = print(io,"🐑")
Base.show(io::IO, ::Type{Wolf}) = print(io,"🐺")
=#

mutable struct Animal{A<:AnimalSpecies} <: Agent{A}
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
    const sex::Sex
end

function Base.show(io::IO, a::Animal{A}) where {A<:AnimalSpecies}
    e = a.energy
    d = a.Δenergy
    pr = a.reprprob
    pf = a.foodprob
    s = a.sex == female ? "♀" : "♂"
    print(io, "$A$s #$(a.id) E=$e ΔE=$d pr=$pr pf=$pf")
end

# note that for new species/sexes we will only have to overload `show` on the
# abstract species types like below!
Base.show(io::IO, ::Type{Sheep}) = print(io,"🐑")
Base.show(io::IO, ::Type{Wolf}) = print(io,"🐺")

function (A::Type{<:AnimalSpecies})(id::Int,E::T,ΔE::T,pr::T,pf::T,s::Sex) where T
    Animal{A}(id,E,ΔE,pr,pf,s)
end

# get the per species defaults back
randsex() = rand(instances(Sex))
Sheep(id; E=4.0, ΔE=0.2, pr=0.8, pf=0.6, s=randsex()) = Sheep(id, E, ΔE, pr, pf, s)
Wolf(id; E=10.0, ΔE=8.0, pr=0.1, pf=0.2, s=randsex()) = Wolf(id, E, ΔE, pr, pf, s)

# Plants

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

function eat!(sheep::Animal{Sheep}, grass::Plant{Grass}, w::World)
    sheep.energy += sheep.Δenergy * grass.size
    grass.size = 0
end

function eat!(wolf::Animal{Wolf}, sheep::Animal{Sheep}, w::World)
    wolf.energy += wolf.Δenergy * sheep.energy
    kill_agent!(sheep, w)
end

function kill_agent!(a::Agent, w::World)
    delete!(w.agents, a.id)
    #w.max_id = maximum(a.id for a in w.agents)
end

eats(::Animal{Sheep}, g::Plant{Grass}) = g.size > 0
eats(::Animal{Wolf}, ::Animal{Sheep}) = true
eats(::Agent, ::Agent) = false

#=
function reproduce!(animal::A, w::World) where A <: Animal 
    animal.energy /= 2
    new_id = w.max_id + 1
    properties = [getproperty(animal,n) for n in fieldnames(A) if n!=:id]
    new_animal = A(new_id, properties...)
    w.max_id = new_id
    w.agents[new_animal.id] = new_animal
end
=#

mates(a::Animal{A}, b::Animal{A}) where A<:AnimalSpecies = a.sex != b.sex
mates(::Agent, ::Agent) = false

function find_mate(a::Animal, w::World)
    ms = filter(x->mates(x,a), w.agents |> values |> collect)
    isempty(ms) ? nothing : rand(ms)
end

function reproduce!(a::Animal{A}, w::World) where {A}
    m = find_mate(a,w)
    if !isnothing(m)
        a.energy = a.energy / 2
        vals = [getproperty(a,n) for n in fieldnames(Animal) if n ∉ [:id, :sex]]
        new_id = w.max_id + 1
        ŝ = Animal{A}(new_id, vals..., randsex())
        w.agents[ŝ.id] = ŝ
        w.max_id = new_id
    end
end

agent_count(animal::Animal) = 1

agent_count(plant::Plant) = plant.size / plant.max_size

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

#=
struct ⚥Sheep <: Animal
    sheep::Sheep
    sex::Symbol
end
⚥Sheep(id, e=4.0, Δe=0.2, pr=0.8, pf=0.6, sex=rand(Bool) ? :female : :male) = ⚥Sheep(Sheep(id,e,Δe,pr,pf),sex)

function Base.getproperty(s::⚥Sheep, name::Symbol)
    if name in fieldnames(Sheep)
        getfield(s.sheep, name)
    else
        getfield(s, name)
    end
end

function Base.setproperty!(s::⚥Sheep, name::Symbol, x)
    if name in fieldnames(Sheep)
        setfield!(s.sheep, name, x)
    else
        setfield!(s, name, x)
    end
end

eat!(s::⚥Sheep, food, world) = eat!(s.sheep, food, world)
=#

function find_food(a::Animal, w::World)
    food_set = filter(x->eats(a,x), w.agents |> values |> collect)
    isempty(food_set) ? nothing : rand(food_set)
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

function agent_step!(a::Animal, w::World)
    a.energy -= 1.0;
    if a.foodprob >= rand()
        food = find_food(a, w)
        eat!(a, food, w)
    end
    if a.energy < 0
        kill_agent!(a, w)
        return
    end
    if a.reprprob >= rand()
        reproduce!(a, w)
    end
end

function agent_step!(p::Plant, w::World)
    if p.size < p.max_size # for this to work as expected, max_size must be a decimal number
        p.size += 1
    end
end

eat!(::Animal, ::Nothing, ::World) = nothing

function world_step!(w::World)
    ids = copy(keys(w.agents))

    for id in ids
        #!haskey(world.agents,id) && continue
        if !haskey(w.agents, id); continue end

        agent = w.agents[id]
        agent_step!(agent, w)
    end
end;
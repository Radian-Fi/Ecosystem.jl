include("world.jl");
include("plant.jl");

# instead of Symbols we can use an Enum for the sex field
# using an Enum here makes things easier to extend in case you
# need more than just binary sexes and is also more explicit than
# just a boolean
@enum Sex female male

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

function eat!(sheep::Animal{Sheep}, grass::Plant{Grass}, w::World)
    sheep.energy += sheep.Δenergy * grass.size
    grass.size = 0
end

function eat!(wolf::Animal{Wolf}, sheep::Animal{Sheep}, w::World)
    wolf.energy += wolf.Δenergy * sheep.energy
    kill_agent!(sheep, w)
end

eat!(::Animal, ::Nothing, ::World) = nothing

eats(::Animal{Sheep}, g::Plant{Grass}) = g.size > 0
eats(::Animal{Wolf}, ::Animal{Sheep}) = true

mates(a::Animal{A}, b::Animal{A}) where A<:AnimalSpecies = a.sex != b.sex

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

function find_food(a::Animal, w::World)
    food_set = filter(x->eats(a,x), w.agents |> values |> collect)
    isempty(food_set) ? nothing : rand(food_set)
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

#=
function Base.getproperty(s::Sheep, name::Symbol)
    if name in fieldnames(Sheep)
        getfield(s.sheep,name)
    else
        getfield(s,name)
    end
end

function Base.setproperty!(s::Sheep, name::Symbol, x)
    if name in fieldnames(Sheep)
        setfield!(s.sheep,name,x)
    else
        setfield!(s,name,x)
    end
end
=#
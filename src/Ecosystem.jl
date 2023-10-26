module Ecosystem

using StatsBase

#include("hw.jl");
#include("world.jl");
#include("plant.jl");
include("animal.jl");

export World
export Species, PlantSpecies, AnimalSpecies, Grass, Sheep, Wolf
export Agent, Plant, Animal
export agent_step!, eat!, eats, find_food, reproduce!, world_step!, agent_count
export Sex, female, male

end

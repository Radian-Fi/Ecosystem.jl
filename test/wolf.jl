using Ecosystem
using Test

@testset "Base.show" begin
    wolf = Wolf(1, pf=1.0)
    sheep = Sheep(2)
    w = World([wolf, sheep])
    eat!(wolf, sheep, w)
    @test length(w.agents) == 1
end
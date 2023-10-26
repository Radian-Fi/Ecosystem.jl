using Ecosystem
using Test

@testset "Base.show" begin
    s = Sheep(1, pf=1.0)
    g = Grass(2, 1, 1)
    w = World([s, g])
    eat!(s, g, w)
    @test g.size == 0
end

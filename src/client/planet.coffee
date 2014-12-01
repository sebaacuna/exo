mksG = 6.67384e-11 #(m3 kg-1 s-2)

class Planet extends THREE.Object3D
    constructor: (name, radius)->
        super
        mesh = THREEx.Planets["create#{name}"](radius)
        mesh.castShadow = true
        @radius = radius
        @mu = mksG*mesh.mksMass
        @LO = mesh.LO
        @planetId = mesh.planetId
        @add mesh

    orbitalState: (altitude)->
        R = @radius + altitude
        V = Math.sqrt(@mu/R)
        return {
            r: Y.clone().normalize().multiplyScalar(-R).toArray()
            v: X.clone().multiplyScalar(V).toArray()
            mu: @mu
            }

window.Planet = Planet

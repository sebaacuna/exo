mksG = 6.67384e-11 #(m3 kg-1 s-2)

class Planet extends THREE.Object3D
    constructor: (name, radius)->
        super
        mesh = THREEx.Planets["create#{name}"](radius)
        cloudMesh = THREEx.Planets.createEarthCloud(radius+KM(10))
        mesh.geometry.applyMatrix y2z
        cloudMesh.applyMatrix y2z
        @up = mesh.up = Z
        mesh.castShadow = true

        @radius = radius
        @mu = mksG*mesh.mksMass
        @LO = mesh.LO
        @planetId = mesh.planetId
        @add mesh
        @add cloudMesh
        setInterval (()-> cloudMesh.rotation.y += 0.0001), 100

    orbitalState: (altitude)->
        R = @radius + altitude*(1+2*Math.random())
        V = Math.sqrt(@mu/R)*(1+0.2*Math.random())
        return {
            r: Y.clone().normalize().multiplyScalar(-R).toArray()
            v: X.clone().multiplyScalar(V).toArray()
            mu: @mu
            }

window.Planet = Planet

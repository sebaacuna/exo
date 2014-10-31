G = 6.67384e-5 #En TON^-1

Planet = 
    create: (name, radius)->
        mesh = THREEx.Planets["create#{name}"]()
        mesh.radius = radius
        canonicalSize = 0.5
        ratio = radius/canonicalSize
        matrix = new THREE.Matrix4().makeScale ratio, ratio, ratio
        mesh.applyMatrix matrix
        return mesh

class Ship extends THREE.Mesh
    constructor: ()->
        super
        size = KM(0.01)
        @geometry = new THREE.BoxGeometry(size, size, size)
        @material = new THREE.MeshBasicMaterial color: 0x006600
        @mass = TON(1)
        @mu = G*@mass
        @orbitCenter = new THREE.Object3D()

    orbit: (planet, altitude)->
        @position.x = planet.radius + altitude
        @velocity = Math.sqrt G*@mass/@position.x
        @orbitCenter.position = planet.position
        @orbitCenter.add @
        planet.parent.add @orbitCenter

    simulate: (dt)->
        [@position, @velocity] = []

    control: (keyboard)->
        @orbitCenter.rotation.y += 0.001
        if keyboard.pressed("w")
            @rotation.y -= 0.1
        if keyboard.pressed("s")
            @rotation.y += 0.1
        if keyboard.pressed("d")
            @rotation.wez += 0.1
        if keyboard.pressed("a")
            @rotation.z -= 0.1

window.Planet = Planet
window.Ship = Ship
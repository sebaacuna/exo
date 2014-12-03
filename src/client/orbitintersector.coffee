TIMESTEP = 1

class OrbitIntersector
    constructor: (@world, @A, @B)->
        @a = new THREE.Mesh(
            new THREE.BoxGeometry KM(500), KM(500), KM(500)
            new THREE.MeshBasicMaterial color: "red"
            )

        @b = new THREE.Mesh(
            new THREE.BoxGeometry KM(500), KM(500), KM(500)
            new THREE.MeshBasicMaterial color: "green"
            )

        @distance = new THREE.Vector3

        @dt = 0

        @world.scene.add @a
        @world.scene.add @b

    solve: ()->
        @dt = 0
        distance = new THREE.Vector3
        decreasing = false
        while @dt < 3600
            @dt += TIMESTEP
            @a.position.copy @A.pointAtTime @dt
            @b.position.copy @B.pointAtTime @dt
            @distance.subVectors @a.position, @b.position
            l = @distance.length()
            if decreasing and l > L
                # Stopped decreasing, stop searching
                return
            decreasing = l < L
            L = l

    remove: ()->
        @world.scene.remove @a
        @world.scene.remove @b

window.OrbitIntersector = OrbitIntersector

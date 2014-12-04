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

        @t = 0
        @world.scene.add @a
        @world.scene.add @b
        @instruments = []

    solve: ()->
        console.log "solve"
        t1 = 0
        t2 = 3600
        dt = 3600
        d1 = @solutionAt(t1)
        d2 = @solutionAt(t2)
        while dt > 10
            dt = dt/2
            d = @solutionAt(t1+dt)
            if d1 < d
                t1 = dt
            else if d2 < d
                t2 = dt
            else
                t1 = t1+dt/2
                t2 = t2-dt/2
            console.log t1, t2, dt, d1, d2 ,d

        @t = dt
        @updateInstruments()
        @solve = ()->

    solutionAt: (t)->
        @a.position.copy @A.pointAtTime t
        @b.position.copy @B.pointAtTime t
        @a.position.distanceTo @b.position

    remove: ()->
        @world.scene.remove @a
        @world.scene.remove @b

    updateInstruments: ()->
        dot = @A.normal.dot @B.normal
        dot = Math.floor(dot*1e8)*1e-8
        inclination = Math.acos dot
        inclination = Math.floor(inclination*1e4)*1e-4
        @instruments = [
            {label: 'inclination', value: angle(inclination)},
            {label: 'eta', value: time(@t)},
            {label: 'intercept', value: distance(@a.position.distanceTo @b.position)}
        ]
        

window.OrbitIntersector = OrbitIntersector

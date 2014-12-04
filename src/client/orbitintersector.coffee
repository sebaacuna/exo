TIMESTEP = 1

class OrbitIntersector
    constructor: (@world, @A, @B)->
        @intersectMesh = new THREE.Mesh(
            new THREE.SphereGeometry KM(50)
            new THREE.MeshBasicMaterial color: COLOR.important
            )
        @a = new THREE.Vector3
        @b = new THREE.Vector3
        @intersect = new THREE.Line(
            new THREE.Geometry
            new THREE.LineBasicMaterial color: COLOR.important
            )
        @intersect.geometry.vertices.push @a, @b
        @t = 0
        @world.scene.add @intersect
        @world.scene.add @intersectMesh
        @instruments = []

    solve: ()->
        t1 = 1
        t2 = @A.period
        dt = t2- t1
        d1 = @solutionAt(t1)
        d2 = @solutionAt(t2)
        while dt > 1
            dt = dt/2
            d = @solutionAt(t1+dt)
            if d1 < d
                t2 = t1 + dt
                d2 = d
            else if d2 < d
                t1 = dt
                d1 = d
            else
                t1 = t1+dt/2
                t2 = t2-dt/2
                d1 = @solutionAt(t1)
                d2 = @solutionAt(t2)

        @t = t1+dt
        @updateInstruments()

    solutionAt: (t)->
        @a.copy @A.pointAtTime t
        @b.copy @B.pointAtTime t
        @a.distanceTo @b

    remove: ()->
        @world.scene.remove @intersect

    updateInstruments: ()->
        dot = @A.normal.dot @B.normal
        dot = Math.floor(dot*1e8)*1e-8
        inclination = Math.acos dot
        inclination = Math.floor(inclination*1e4)*1e-4

        @intersect.geometry.verticesNeedUpdate = true
        @intersectMesh.position.copy @a

        @instruments = [
            {label: 'inclination', value: angle(inclination)},
            {label: 'eta', value: time(@t)},
            {label: 'intercept', value: distance(@a.distanceTo @b)}
        ]
        

window.OrbitIntersector = OrbitIntersector

uiCage = (size, color)->
    mesh = new THREE.Mesh
    mesh.geometry = new THREE.BoxGeometry KM(100), KM(100), KM(100)
    mesh.material = new THREE.MeshBasicMaterial color: color, wireframe: true, depthTest: true
    return mesh

ELLIPSE_POINTS = 2000

class OrbitCurve extends THREE.Curve
    constructor: (@mu)->
        @e = new THREE.Vector3  # Ecc vector, ellipse's X-vector
        @eY = new THREE.Vector3  # Ecc "Y"-vector
        @eZ = new THREE.Vector3  # Ecc "Z"-vector

        @q1 = new THREE.Quaternion
        @q2 = new THREE.Quaternion
        @rotation = new THREE.Matrix4

    update: (r,v,h)->
        @r = r.clone().normalize()
        @e.crossVectors(v,h.clone().normalize()).multiplyScalar h.length()/@mu
        @e.sub @r

        @ecc = @e.length()
        if @ecc < 1e-10
            @e.copy X
        @P = h.lengthSq()/@mu

        # Ellipse vectors and quaternions
        @e.normalize()
        @eZ = h.clone().normalize()
        @eY.crossVectors @eZ, @e

        @semiMajorAxis = @P/(1-@ecc*@ecc)

        @q1.setFromUnitVectors Z, @eZ
        x = X.clone().applyQuaternion @q1
        y = Y.clone().applyQuaternion @q1
        
        zAngle = Math.acos @e.dot x
        if @e.dot(y) < 0
            zAngle = TwoPI - zAngle

        @q2.setFromAxisAngle Z, zAngle
        @q1.multiply @q2

        # Angle of craft on ellipse (phase)
        @f = Math.acos @r.dot(@e)
        if @r.dot(@eY) < 0
            @f = TwoPI - @f

        @rotation.makeRotationFromQuaternion @q1

    getPoint: (t)->
        @getPointAtTrueAnomaly(@f + t*TwoPI)

    getPointAtTrueAnomaly: (E)->
        cosE = Math.cos(E)
        sinE = Math.sin(E)
        length = @P/(1+@ecc*cosE)
        X = length*cosE
        Y = length*sinE
        new THREE.Vector3 X, Y, 0

class Orbit extends THREE.Object3D
    constructor: (@planet, @craft)->
        super
        @periapsis = new THREE.Vector3
        @apoapsis = new THREE.Vector3

        @periapsisCage = uiCage(KM(10), 0x00ff00)
        @add @periapsisCage
        
        @apoapsisCage = uiCage(KM(10), 0x0000ff)
        @add @apoapsisCage

        material = new THREE.LineBasicMaterial linewidth:1, color: 0x00ffff
        geometry = new THREE.Geometry
        geometry.dynamic = true
        for i in [0..ELLIPSE_POINTS]
            geometry.vertices.push new THREE.Vector3
        @line = new THREE.Line geometry, material
        @line.matrixAutoUpdate = false
        
        @add @line
        @planet.add @

        @curve = new OrbitCurve @planet.mu
        @out = new THREE.Vector3
        @north = new THREE.Vector3
        @west = new THREE.Vector3
        @normal = new THREE.Vector3

        @normalHelper = new THREE.ArrowHelper X, ORIGIN, KM(100000)
        @add @normalHelper

    update: ()->
        @curve.update @craft.mksPosition, @craft.mksVelocity, @craft.mksH
        path = new THREE.CurvePath 
        path.add @curve
        
        @line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices
        @line.geometry.verticesNeedUpdate = true
        @line.matrix = @curve.rotation

        @meanMotion = Math.sqrt @planet.mu/Math.pow(@curve.semiMajorAxis,3)

        # Apoapsis and periapsis
        @periapsis.copy(@curve.e).multiplyScalar(@curve.P/(1+@curve.ecc))
        @apoapsis.copy(@curve.e).multiplyScalar(-@curve.P/(1-@curve.ecc))

        # Orbital coordinates
        @out.copy @craft.mksPosition.clone().normalize()
        @west.crossVectors(@out, Z).normalize() #TODO: Generalize on planet's up
        @north.crossVectors @west, @out

        @normal.copy(@craft.mksH).normalize()

        @periapsisCage.position.copy @periapsis
        @apoapsisCage.position.copy @apoapsis
        @normalHelper.setDirection @normal

    pointAtTime: (t)->
        # Starting mean anomaly
        cosT0 = Math.cos @curve.f
        E0 = Math.acos (@curve.ecc + cosT0)/(1 + @curve.ecc*cosT0)
        if @curve.f > Math.PI
            E0 = TwoPI - E0
        M0 = E0 - @curve.ecc*Math.sin E0

        # Eccentric anomaly
        E = @eccentricFromMeanAnomaly(M0+@meanMotion*t)

        # True anomaly
        arg = Math.sqrt((1+@curve.ecc)/(1-@curve.ecc))
        arg *= Math.tan(E/2)
        T = 2*Math.atan arg

        return @curve.getPointAtTrueAnomaly(T).applyMatrix4(@curve.rotation)

    # Using Newton-Raphson
    eccentricFromMeanAnomaly: (M)->
        E = Math.PI
        count = 0
        D = 1
        while Math.abs(D) > 1e-3
            Y = M + @curve.ecc*Math.sin(E) - E
            YY = 1 - @curve.ecc*Math.cos(E)
            D = Y/YY
            E += D
            count++
        return E

window.Orbit = Orbit
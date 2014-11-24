uiCage = (size, color)->
    mesh = new THREE.Mesh
    mesh.geometry = new THREE.BoxGeometry KM(100), KM(100), KM(100)
    mesh.material = new THREE.MeshBasicMaterial color: color, wireframe: true, depthTest: true
    return mesh

ELLIPSE_POINTS = 2000
TwoPI = Math.PI*2

class OrbitCurve extends THREE.Curve
    constructor: (@mu)->
        @h = new THREE.Vector3  # Ang Mom
        @e = new THREE.Vector3  # Ecc vector, ellipse's X-vector
        @eY = new THREE.Vector3  # Ecc "Y"-vector
        @eZ = new THREE.Vector3  # Ecc "Z"-vector
        @q1 = new THREE.Quaternion
        @q2 = new THREE.Quaternion
        @q3 = new THREE.Quaternion
        @rotation = new THREE.Matrix4

    update: (r,v)->
        @r = r.clone().normalize()
        @h.crossVectors r, v
        @e.crossVectors(v,@h.clone().normalize()).multiplyScalar @h.length()/@mu
        @e.sub @r

        @ecc = @e.length()
        if @ecc < 1e-10
            @e.copy X
        @P = @h.lengthSq()/@mu

        # Distance from center to focus
        @c = @P/(1+@ecc)

        # Ellipse vectors and quaternions
        @e.normalize()
        @eZ = @h.clone().normalize()
        @eY.crossVectors @eZ, @e

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

        @e.multiplyScalar @c
        @rotation.makeRotationFromQuaternion @q1

    getPoint: (t)->
        angle = @f + t*TwoPI
        cosT = Math.cos(angle)
        sinT = Math.sin(angle)
        length = @P/(1+@ecc*cosT)
        X = length*cosT
        Y = length*sinT
        point = new THREE.Vector3 X, Y, 0
        return point

class Orbit extends THREE.Object3D
    constructor: (@planet)->
        super        
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

        # @line.add new THREE.AxisHelper KM(8000)
        @curve = new OrbitCurve @planet.mu

    update: (r,v)->
        @curve.update r, v
        path = new THREE.CurvePath 
        path.add @curve
        
        @line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices
        @line.geometry.verticesNeedUpdate = true
        @line.matrix = @curve.rotation

        # Update visual cues
        @periapsisCage.position.copy @curve.e


window.Orbit = Orbit
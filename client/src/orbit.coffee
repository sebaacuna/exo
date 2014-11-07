uiCage = (size, color)->
    mesh = new THREE.Mesh
    mesh.geometry = new THREE.BoxGeometry KM(100), KM(100), KM(100)
    mesh.material = new THREE.MeshBasicMaterial color: color, wireframe: true, depthTest: true
    return mesh

ELLIPSE_POINTS = 500
_inclineAxis = new THREE.Vector3

class Orbit extends THREE.Object3D
    constructor: (@planet)->
        super
        @ev = new THREE.Vector3 #Eccentricity vector
        @h = new THREE.Vector3 #Specific andular momentum
        
        @craftCage = uiCage(KM(10), 0xff0000)
        @add @craftCage
        
        @periapsisCage = uiCage(KM(10), 0x00ff00)
        @add @periapsisCage
        
        @apoapsisCage = uiCage(KM(10), 0x0000ff)
        @add @apoapsisCage

        material = new THREE.LineBasicMaterial linewidth:1, color: 0x00ffff, depthTest: true
        geometry = new THREE.Geometry
        geometry.dynamic = true
        for i in [0..ELLIPSE_POINTS]
            geometry.vertices.push new THREE.Vector3
        @line = new THREE.Line geometry, material
        
        @add @line
        @planet.add @

    update: (r,v)->
        @h.crossVectors r, v
        @ev.crossVectors(v,@h).multiplyScalar 1/@planet.mu
        @ev.sub r.clone().normalize()

        ecc = @ev.length()
        ecc2 = @ev.lengthSq()
        @ev.normalize()

        P = @h.lengthSq()/@planet.mu

        semiMajor = P/(1-ecc2)
        semiMinor = semiMajor*Math.sqrt (1-ecc2)


        ellipse = new THREE.EllipseCurve semiMajor*ecc, 0, semiMajor, semiMinor, 0, 2*Math.PI, false
        path = new THREE.CurvePath 
        path.add ellipse
        # for v, i in geometry.vertices
        #     @line.geometry.vertices[i].x = v.x
        #     @line.geometry.vertices[i].y = v.y
        
        # Put on plane normal to ang mom
        @line.lookAt @h
        # Now ellipse's X is on plane with ev
        # Align ellipse with direction of eccentricity
        lineX = X.clone()
        @line.rotateOnAxis Z, 2*Math.PI - lineX.angleTo(@ev)
        
        @line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices
        @line.geometry.verticesNeedUpdate = true

        # normal = @line.localToWorld Z.clone()
        # inclineAngle = normal.angleTo h
        # if inclineAngle != 0
        #     _inclineAxis.crossVectors normal, h.clone().normalize()
        #     _inclineAxis.normalize()
        #     @line.rotateOnAxis _inclineAxis, inclineAngle



        # @line.rotateOnAxis Z, @line.up.angleTo @line.worldToLocal(@ev)

        # Update visual cues
        @craftCage.position.copy r
        @apoapsisCage.position.copy(@ev.clone().multiplyScalar -P/(1-ecc))
        @periapsisCage.position.copy(@ev.multiplyScalar P/(1+ecc))

window.Orbit = Orbit
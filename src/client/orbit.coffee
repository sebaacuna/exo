uiCage = (size, color)->
    mesh = new THREE.Mesh
    mesh.geometry = new THREE.BoxGeometry KM(100), KM(100), KM(100)
    mesh.material = new THREE.MeshBasicMaterial color: color, wireframe: true, depthTest: true
    return mesh

ELLIPSE_POINTS = 2000

class Orbit extends THREE.Object3D
    constructor: (@planet)->
        super
        @ev = new THREE.Vector3 #Eccentricity vector
        @h = new THREE.Vector3 #Specific andular momentum
        
        @craftCage = uiCage(KM(10), 0xff0000)
        @add @craftCage
        @craftCage.visible = false
        
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
        
        @add @line
        @planet.add @

        @line.add new THREE.AxisHelper KM(8000)

    update: (r,v)->
        @h.crossVectors r, v
        @ev.crossVectors(v,@h.clone().normalize()).multiplyScalar @h.length()/@planet.mu
        @ev.sub r.clone().normalize()

        ecc = @ev.length()
        ecc2 = @ev.lengthSq()
        @ev.normalize()

        P = @h.lengthSq()/@planet.mu

        semiMajor = P/(1-ecc2)
        semiMinor = semiMajor*Math.sqrt (1-ecc2)


        # Put on plane normal to ang mom
        @line.lookAt @h
        # Now ellipse's X is on plane with ev
        # Align ellipse with direction of eccentricity
        lineX = X.clone()

        @line.rotateOnAxis Z, 2*Math.PI - lineX.angleTo(@ev)
        ellipse = new THREE.EllipseCurve semiMajor*ecc, 0, semiMajor, semiMinor, 0, 2*Math.PI, false
        path = new THREE.CurvePath 
        path.add ellipse
        
        @line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices
        @line.geometry.verticesNeedUpdate = true

        # Update visual cues
        @craftCage.position.copy r
        @apoapsisCage.position.copy(@ev.clone().multiplyScalar -P/(1-ecc))
        @periapsisCage.position.copy(@ev.multiplyScalar P/(1+ecc))

window.Orbit = Orbit
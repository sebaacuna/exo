mksG = 6.67384e-11 #(m3 kg-1 s-2)
NULLVECTOR = new THREE.Vector3
X = new THREE.Vector3 1, 0, 0
Y = new THREE.Vector3 0, 1, 0
Z = new THREE.Vector3 0, 0, 1

Planet = 
    create: (name, radius)->
        mesh = THREEx.Planets["create#{name}"](radius)
        mesh.radius = radius
        mesh.mu = mksG*mesh.mksMass
        return mesh

class Ship extends THREE.Object3D
    constructor: (size)->
        super
        @mesh = new THREE.Mesh
        @mesh.geometry = new THREE.CylinderGeometry size*0.25, size*0.5, size
        @mesh.material = new THREE.MeshBasicMaterial color: 0x006600
        @mesh.matrixAutoUpdate = true
        @add @mesh

        @mesh.rollAxis = @mesh.up
        @mesh.yawAxis = new THREE.Vector3 1,0,0
        if 0== @mesh.yawAxis.angleTo @mesh.rollAxis
            @mesh.yawAxis = new THREE.Vector3 0,0,1
        @mesh.pitchAxis = (new THREE.Vector3).crossVectors @mesh.yawAxis, @mesh.rollAxis

        @cameraTarget = new THREE.Object3D
        @add @cameraTarget
        
        @velArrow = @arrow new THREE.Vector3(KM(1),0,0)
        @add @velArrow

        @accelArrow = @arrow X
        @add @accelArrow

        @thrustArrow = @arrow @mesh.rollAxis, 0xffffff
        @add @thrustArrow
        @thrust = 0

        @navCage = new THREE.Mesh
        @navCage.geometry = new THREE.BoxGeometry KM(10), KM(10), KM(10)
        @navCage.material = new THREE.MeshBasicMaterial color:0xff0000, wireframe: true
        @add @navCage

        @consoleElems = {}

    console: (key, value)->
        if not @consoleElems[key]
            @consoleElems[key] = document.getElementById("console-#{key}") or -1
        if @consoleElems[key] != -1
            @consoleElems[key].innerHTML = value

    orbit: (@boi, gameAltitude)->
        @mksMass = 1000
        @position.x = @boi.radius + gameAltitude
        mksDistance = mksVector(@position).length()
        mksOrbitalSpeed = Math.sqrt(@boi.mu/mksDistance)
        @mksVelocity = new THREE.Vector3 0,0, mksOrbitalSpeed
        @mksPosition = mksVector(@position)
        @mksAngMom = new THREE.Vector3
        @referencePosition = @position.clone()
        
        alignAxis = new THREE.Vector3
        alignAxis.crossVectors(@mesh.up, @mksVelocity)
        alignAxis.normalize()
        @mesh.rotateOnAxis alignAxis, @mesh.up.angleTo(@mksVelocity)

    updateEllipse: ()->
        ecc2 = 1.0 + 2*@orbitalEnergy*@mksAngMom.lengthSq()/(@boi.mu*@boi.mu)
        semiMajor = 0.5*@boi.mu/@orbitalEnergy
        semiMinor = semiMajor*Math.sqrt(1.0 - ecc2)
        @console 'eccentricity', "#{ecc2} #{semiMajor} #{semiMinor}"

        ellipse = new THREE.EllipseCurve 0, 0, semiMajor, semiMinor, 0, 2*Math.PI, false
        path = new THREE.CurvePath 
        path.add ellipse
        geometry = path.createPointsGeometry 2000
        if not @orbitLine
            @orbitLine = new THREE.Line geometry, new THREE.LineBasicMaterial linewidth:2, color: 0x0000ff, depthTest: true
            geometry.dynamic = true
            @parent.add @orbitLine
        else
            @orbitLine.material = new THREE.LineBasicMaterial color: 0x00ff00
            for v, i in geometry.vertices
                @orbitLine.geometry.vertices[i].x = v.x
                @orbitLine.geometry.vertices[i].y = v.y
            @orbitLine.geometry.verticesNeedUpdate = true
        
        normal = @orbitLine.localToWorld Z.clone()
        orbitRotateAngle = normal.angleTo @mksAngMom
        if orbitRotateAngle >0
            orbitRotateAxis = normal.cross(@mksAngMom).normalize()
            @orbitLine.rotateOnAxis orbitRotateAxis, orbitRotateAngle

    captureCamera: (@camera)->
        @cameraTarget.add camera
        camera.position.z = KM(0.1)
        camera.target = @cameraTarget
        camera.control = (keyboard, renderer)->
            ()=>
                if keyboard.pressed "shift"
                    if keyboard.pressed "shift+up"
                        @position.z = Math.max(@position.z/2.0, M(10))
                    if keyboard.pressed "shift+down"
                        @position.z = Math.min(@position.z*2, KM(100000))
                else
                    if keyboard.pressed "left"
                        @target.rotation.y -= 0.05
                    if keyboard.pressed "right"
                        @target.rotation.y += 0.05
                    if keyboard.pressed "up"
                        @target.rotation.x -= 0.05
                    if keyboard.pressed "down"
                        @target.rotation.x += 0.05

    simulate: ()->
        clock = new THREE.Clock
        clock.start()
        ()=>
            if not @a
                @a = (x,v, dt)=> #gravitation
                    r = x.clone().normalize().negate()
                    magnitude = mksG*@boi.mksMass/(x.length()*x.length())
                    r.multiplyScalar magnitude
                    return r.add @thrustCalc(x,v,dt)

            count = 0
            oldPosition = @mksPosition.clone()
            oldVel = @mksVelocity.clone()
            dt = 0.00001
            simulateSeconds = clock.getDelta()
            simulateSteps = Math.floor simulateSeconds/dt
            while count < simulateSteps
                THREEx.rk4 @mksPosition, @mksVelocity, @a, dt
                ++count
            
            @mksPosition.setGameVector @position
            oldVel.sub(@mksVelocity)

            @velArrow?.setDirection @mksVelocity.clone().normalize()
            
            
            @console 'velocity',  Math.floor(@mksVelocity.length())
            @console 'acceleration',  Math.floor(oldVel.length()*1000)/10.0
            
            @accelArrow?.setLength oldVel.length()*100
            @accelArrow?.setDirection oldVel.negate().normalize()

            @mksAngMom.crossVectors @mksPosition, @mksVelocity
            @orbitalEnergy = 0.5*@mksVelocity.lengthSq()
            @orbitalEnergy -= @boi.mu/@mksPosition.length()
            @console 'orbital-energy', Math.floor(@orbitalEnergy)

    control: (keyboard)->
        ()=>
            if keyboard.pressed("w")
                @mesh.rotateOnAxis @mesh.pitchAxis, -0.05
            if keyboard.pressed("s")
                @mesh.rotateOnAxis @mesh.pitchAxis, 0.05
            if keyboard.pressed("d")
                @mesh.rotateOnAxis @mesh.yawAxis, -0.05
            if keyboard.pressed("a")
                @mesh.rotateOnAxis @mesh.yawAxis, 0.05
            if keyboard.pressed("q")
                @mesh.rotateOnAxis @mesh.rollAxis, 0.05
            if keyboard.pressed("e")
                @mesh.rotateOnAxis @mesh.rollAxis, -0.05
            if keyboard.pressed "space"
                @thrust = 1
                @thrustArrow.visible = true
            else
                @thrust = 0
                @thrustArrow.visible = false

    track: (camera)->
        ()=>
            localPos = camera.position.clone()
            camera.localToWorld(localPos)
            far = (localPos.distanceTo(@position) > KM(10))
            @orbitLine?.visible = far
            @navCage.visible = far
            @updateEllipse()
            if far
                @velArrow.setLength @mksVelocity.length()
            else
                @velArrow.setLength @mksVelocity.length()

    arrow: (vector, color=0xff0000)->
        direction = vector.clone().normalize()
        new THREE.ArrowHelper direction, @position, vector.length(), color
        
    thrustCalc: (x,v,dt)->
        if @thrust
            F = 200000 #Thrust [N]
            thrustVector = @mesh.rollAxis.clone()
            thrustVector.normalize()
            thrustVector.applyMatrix4 @mesh.matrix

            @thrustArrow.setDirection thrustVector
            @thrustArrow.setLength KM(1)

            thrustVector.multiplyScalar F/@mksMass
            return thrustVector
        else
            return NULLVECTOR

window.Planet = Planet
window.Ship = Ship
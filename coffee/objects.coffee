mksG = 6.67384e-11 #(m3 kg-1 s-2)

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
        @add @mesh

        @cameraTarget = new THREE.Object3D
        @add @cameraTarget
        
        @velArrow = @arrow new THREE.Vector3(KM(1),0,0)
        @add @velArrow

    orbit: (@boi, gameAltitude)->
        @mksMass = 1000
        @position.y = @boi.radius + gameAltitude
        mksDistance = mksVector(@position).length()
        mksOrbitalSpeed = Math.sqrt(@boi.mu/mksDistance)
        @mksVelocity = new THREE.Vector3 mksOrbitalSpeed, 0, 0
        @mksPosition = mksVector(@position)
        @mksAngMom = new THREE.Vector3
        @referencePosition = @position.clone()

    updateEllipse: ()->
        @mksAngMom.crossVectors @mksPosition, @mksVelocity
        # orbitalEnergy = 0.5*@mksVelocity.lengthSq()
        # orbitalEnergy -= @boi.mu/@mksPosition.length()
        # console.log "E=#{orbitalEnergy}"
        # ecc2 = 1.0 + 2*orbitalEnergy*@mksAngMom.lengthSq()/(@boi.mu*@boi.mu)
        # semiMajor = 0.5*@boi.mu/orbitalEnergy
        # semiMinor = @mksAngMom.length()*Math.sqrt(0.5/orbitalEnergy)
        # @orbitEllipse = new THREE.EllipseCurve 0, 0, semiMajor, semiMinor
        @orbitEllipse = new THREE.EllipseCurve 0, 0, @position.length(), @position.length(), 0, 2*Math.PI, false
        path = new THREE.CurvePath 
        path.add @orbitEllipse
        # path.ellipse 0, 0, @position.length(), @position.length(), 0, 2*Math.PI, false
        @orbitLine = new THREE.Line(path.createPointsGeometry(20000), new THREE.LineBasicMaterial depthTest:true, color: 0x0000ff, linewidth: 2, fog: true)
        orbitRotateAngle = new THREE.Vector3(0, 0, 1).angleTo @mksAngMom
        @orbitLine.rotateOnAxis @mksVelocity.clone().normalize(), orbitRotateAngle 
        @parent.add @orbitLine
        console.log @orbitLine

    captureCamera: (@camera)->
        @cameraTarget.add camera
        camera.position.z = KM(1)
        camera.target = @cameraTarget
        camera.control = (keyboard, renderer)->
            ()=>
                if keyboard.pressed "shift"
                    if keyboard.pressed "shift+up"
                        @position.z = Math.max(@position.z/2.0, M(10))
                    if keyboard.pressed "shift+down"
                        @position.z = Math.min(@position.z*2, KM(10000))
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
            if not @g
                @g = (x,v, dt)=>
                    r = x.clone().normalize().negate()
                    magnitude = mksG*@boi.mksMass/(x.length()*x.length())
                    r.multiplyScalar magnitude
                    return r
            
            count = 0
            oldPosition = @mksPosition.clone()
            dt = 0.00001
            simulateSeconds = clock.getDelta()
            simulateSteps = Math.floor simulateSeconds/dt
            while count < simulateSteps
                THREEx.rk4 @mksPosition, @mksVelocity, @g, dt
                ++count
            @mksPosition.setGameVector @position
            @velArrow?.setDirection @mksVelocity.clone().normalize()

            # console.log @position.angleTo(@referencePosition)/clock.elapsedTime
            # if @mksPosition.length() - oldPosition.length() > 0.1
            # console.log Math.floor(@mksPosition.length()*10)/10.0

    control: (keyboard)->
        ()=>
            if keyboard.pressed("w")
                @mesh.rotation.y -= 0.05
            if keyboard.pressed("s")
                @mesh.rotation.y += 0.05
            if keyboard.pressed("d")
                @mesh.rotation.z += 0.05
            if keyboard.pressed("a")
                @mesh.rotation.z -= 0.05

    arrow: (vector, color=0xff0000)->
        direction = vector.clone().normalize()
        new THREE.ArrowHelper direction, @position, vector.length(), color
        
        
        

window.Planet = Planet
window.Ship = Ship
$acceleration = new THREE.Vector3

class Craft extends THREE.Object3D
    constructor: (data, @planet)->
        super
        @name = data.name
        @craftId = data.craftId
        @channel = "craft-#{@craftId}"
        size = M(30)

        @instruments = []
        @mksMass = 1000

        @mesh = new THREE.Mesh
        @mesh.geometry = new THREE.CylinderGeometry size*0.25, size*0.5, size
        @mesh.material = new THREE.MeshPhongMaterial color: 0xefefef
        @mesh.matrixAutoUpdate = true
        @mesh.receiveShadow = true
        @add @mesh

        @mksPosition = new THREE.Vector3
        @mksVelocity = new THREE.Vector3
        @mksH = new THREE.Vector3           # Specific Ang Mom

        @mesh.rollAxis = @mesh.up
        @mesh.yawAxis = X
        if 0== @mesh.yawAxis.angleTo @mesh.rollAxis
            @mesh.yawAxis = Y
        @mesh.pitchAxis = (new THREE.Vector3).crossVectors @mesh.yawAxis, @mesh.rollAxis
        
        @velArrow = new THREE.ArrowHelper X, ORIGIN, KM(1000), 0x00ff00
        @add @velArrow

        @accelArrow = new THREE.ArrowHelper X, ORIGIN, KM(1000), 0xff0000
        @add @accelArrow

        @thrustArrow = new THREE.ArrowHelper @mesh.rollAxis, ORIGIN, 0, 0xffffff
        @mesh.add @thrustArrow
        @throttle = 0

        @mesh.add new THREE.AxisHelper KM(1000)

        @consoleElems = {}
        
        @orbit = new Orbit @planet, @
        @orbit.visible = false
        @updateState data
        @mesh.lookAt @mksVelocity


    updateState: (state)->
        oldV = @mksVelocity.clone()
        @mksPosition.copy state.r
        @mksVelocity.copy state.v
        @mksH.crossVectors @mksPosition, @mksVelocity

        if @orbit.visible
            @orbit.update()
        
        setGameVector @mksPosition, @position
        @updateInstruments()
        $acceleration.subVectors oldV, @mksVelocity
        
        @velArrow?.setDirection @mksVelocity.clone().normalize()
        @accelArrow?.setLength $acceleration.length()
        @accelArrow?.setDirection $acceleration.normalize()


    updateInstruments: ()->
        @instruments = [
            { label: 'eccentricity', value: Math.floor(@orbit.curve.ecc*100)/100 },
            { label: 'apoapsis',     value: distance(@orbit.apoapsis.length()) },
            { label: 'periapsis',    value: distance(@orbit.periapsis.length()) },
        ]


    controller: (game)->
        kb = game.keyboard
        game.socket.emit "control", @craftId
        
        sendThrust = ()=>
            game.socket.emit "#{@channel}-thrust", @thrustVector().toArray()
        thrustStart = (event)=>
            if event.keyCode == 32 #space
                setThrust 1.0
        thrustEnd = (event)=>
            if event.keyCode == 32 #space
                setThrust 0.0
        setThrust = (throttle)=>
            if throttle != @throttle
                @throttle = throttle
                sendThrust()

        ()=>
            if kb.pressed("shift")
                ROTATION = 0.001
            else
                ROTATION = 0.01

            if kb.pressed("w")
                @mesh.rotateOnAxis @mesh.pitchAxis, ROTATION
            if kb.pressed("s")
                @mesh.rotateOnAxis @mesh.pitchAxis, -ROTATION
            if kb.pressed("d")
                @mesh.rotateOnAxis @mesh.yawAxis, -ROTATION
            if kb.pressed("a")
                @mesh.rotateOnAxis @mesh.yawAxis, ROTATION
            if kb.pressed("q")
                @mesh.rotateOnAxis @mesh.rollAxis, -ROTATION
            if kb.pressed("e")
                @mesh.rotateOnAxis @mesh.rollAxis, ROTATION

            if kb.pressed("space")
                setThrust 1.0
            else
                setThrust 0.0


    thrustVector: ()->
        if @throttle == 0
            @thrustArrow.setLength 0
            return ORIGIN
        else
            F = 10000 #Thrust [N]
            vector = @mesh.rollAxis.clone()

            @thrustArrow.setDirection vector
            @thrustArrow.setLength KM(1000)*@throttle
            
            vector.applyMatrix4 @mesh.matrix
            vector.multiplyScalar F/@mksMass
            return vector

window.Craft = Craft
$acceleration = new THREE.Vector3

class Craft extends THREE.Object3D
    constructor: (data, @planet)->
        super
        @name = data.name
        @craftId = data.craftId
        @channel = "craft-#{@craftId}"
        size = M(30)

        @mksMass = 1000

        @mesh = new THREE.Mesh
        @mesh.geometry = new THREE.CylinderGeometry size*0.25, size*0.5, size
        @mesh.material = new THREE.MeshPhongMaterial 
            color: 0xefefef
        @mesh.matrixAutoUpdate = true
        @mesh.receiveShadow = true
        @add @mesh

        @mksPosition = new THREE.Vector3
        @mksVelocity = new THREE.Vector3

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
        
        @orbit = new Orbit @planet
        @orbit.visible = false
        @updateState data


    updateState: (state)->
        oldV = @mksVelocity.clone()
        @mksPosition.copy state.r
        @mksVelocity.copy state.v
        @orbit.update @mksPosition, @mksVelocity
        
        setGameVector @mksPosition, @position
        $acceleration.subVectors oldV, @mksVelocity
        
        @velArrow?.setDirection @mksVelocity.normalize()
        @accelArrow?.setLength $acceleration.length()
        @accelArrow?.setDirection $acceleration.normalize()

    controller: (keyboard, socket)->
        socket.emit "control", @craftId
        thrustStart = (event)=>
            if event.keyCode == 32 #space
                setThrust 1.0
        thrustEnd = (event)=>
            if event.keyCode == 32 #space
                setThrust 0.0
        
        setThrust = (throttle)=>
            if throttle != @throttle
                @throttle = throttle
                v = @thrustVector()
                console.log "Throttle", throttle, v
                socket.emit "#{@channel}-thrust", v.toArray()

        document.addEventListener("keydown", thrustStart, false)
        document.addEventListener("keyup", thrustEnd, false)

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

    thrustVector: ()->
        if @throttle == 0
            @thrustArrow.setLength 0
            return ORIGIN
        else
            F = 2000 #Thrust [N]
            vector = @mesh.rollAxis.clone()

            @thrustArrow.setDirection vector
            @thrustArrow.setLength KM(1000)*@throttle
            
            vector.applyMatrix4 @mesh.matrix
            vector.multiplyScalar F/@mksMass
            return vector

window.Craft = Craft
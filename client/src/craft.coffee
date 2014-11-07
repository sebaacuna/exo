$acceleration = new THREE.Vector3

class Craft extends THREE.Object3D
    constructor: (data, @planet)->
        super
        @craftId = data.craftId
        size = M(30)

        @mksMass = 1000

        @mesh = new THREE.Mesh
        @mesh.geometry = new THREE.CylinderGeometry size*0.25, size*0.5, size
        @mesh.material = new THREE.MeshBasicMaterial color: 0x006600
        @mesh.matrixAutoUpdate = true
        @mesh.up = X.clone()
        @add @mesh

        @mksPosition = new THREE.Vector3
        @mksVelocity = new THREE.Vector3
        
        # alignAxis = new THREE.Vector3
        # alignAxis.crossVectors(@mesh.up, @mksVelocity)
        # alignAxis.normalize()
        # @mesh.rotateOnAxis alignAxis, @mesh.up.angleTo(@mksVelocity)

        @mesh.rollAxis = @mesh.up
        @mesh.yawAxis = new THREE.Vector3 1,0,0
        if 0== @mesh.yawAxis.angleTo @mesh.rollAxis
            @mesh.yawAxis = new THREE.Vector3 0,0,1
        @mesh.pitchAxis = (new THREE.Vector3).crossVectors @mesh.yawAxis, @mesh.rollAxis
        
        @velArrow = @arrow new THREE.Vector3(KM(1000),0,0)
        @add @velArrow

        @accelArrow = @arrow X
        @add @accelArrow

        @thrustArrow = @arrow @mesh.rollAxis, 0xffffff
        @add @thrustArrow
        @thrust = 0

        @mesh.add new THREE.AxisHelper KM(1000)

        @consoleElems = {}
        
        @orbit = new Orbit @planet
        @updateState data

        window.orbit = @orbit

    # console: (key, value)->
    #     if not @consoleElems[key]
    #         @consoleElems[key] = document.getElementById("console-#{key}") or -1
    #     if @consoleElems[key] != -1
    #         @consoleElems[key].innerHTML = value
    
    updateState: (state)->
        oldV = @mksVelocity.clone()
        @mksPosition.copy state.r
        @mksVelocity.copy state.v
        @orbit.update @mksPosition, @mksVelocity
        
        setGameVector @mksPosition, @position
        $acceleration.subVectors oldV, @mksVelocity

        # @console 'velocity',  Math.floor(@mksVelocity.length())
        # @console 'acceleration',  Math.floor($acceleration.length()*1000)/10.0
        
        @velArrow?.setDirection @mksVelocity.normalize()
        @accelArrow?.setLength $acceleration.length()
        @accelArrow?.setDirection $acceleration.normalize()

        # Feedback
        # @console 'orbital-energy', Math.floor(@orbitalEnergy*10000)/10000
        # @console 'angular-moment', Math.floor(@mksAngMom.length()*10000)/10000
        # @console 'r', @mksPosition.length()

        # localPos = camera.position.clone()
        # camera.localToWorld(localPos)
        # far = (localPos.distanceTo(@position) > KM(10))
        # @orbit?.visible = far
        # if far
        #     @velArrow.setLength @mksVelocity.length()
        # else
        #     @velArrow.setLength @mksVelocity.length()

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
            return ORIGIN

window.Craft = Craft
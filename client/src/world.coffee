class World
    constructor:(@viewport, @socket)->
        @crafts = {}
        @gameLoop = []
        @boi = new Planet('Earth', KM(6378))
        
        @createScene()
        @createRenderer()
        @createCamera()
      
        @keyboard = new THREEx.KeyboardState

        # Takes control of the craft
        @craftController = ()-> #No-op by default
        @gameLoop.push ()=> @craftController()

        # Photography
        @cameraController = ()-> #No-op as default
        @gameLoop.push ()=>@cameraController()

        @focusObject @boi

    createScene: ()->
        @scene = new THREE.Scene()
        @scene.add new THREE.AmbientLight 0x888888
        @scene.add new THREE.AxisHelper KM(10000)
        @scene.add @boi

    createRenderer: ()->
        @renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
        @renderer.setSize @viewport.width(), @viewport.height()
        @renderer.shadowMapEnabled   = true
        @viewport.append @renderer.domElement

    createCamera: ()->
        @camera = new THREE.PerspectiveCamera 90, @viewport.width()/@viewport.height(), M(1), KM(10000000)
        @camera.target = new THREE.Object3D
        $viewport = @viewport
        @camera.setFrame = (frameSize)->
            ratio = $viewport.width()/$viewport.height()
            @left = -frameSize*ratio
            @right = frameSize*ratio
            @top = frameSize*ratio
            @bottom = -frameSize*ratio
            @updateProjectionMatrix()

    updateCrafts: (craftStates)->
        for id, state of craftStates
            @crafts[id]?.updateState state

    start: ()->
        @tick = ()=>
            @renderer.render @scene, @camera
            for f in @gameLoop
                f()
            requestAnimationFrame @tick
        @tick()

    # Creates a craft on the server and adds it to the world
    createCraft: (callback)->
        state = @boi.orbitalState @boi.LO*(1+10*Math.random())
        $.ajax
            type: "PUT"
            url:  "/crafts"
            data: JSON.stringify(state)
            processData: false
            contentType: 'application/json; charset=utf-8'
            success: (data, textStatus, $xhr)=>
                craft = new Craft(data, @boi)
                @addCraft craft
                callback(craft)

    # Gets existing crafts from server and adds them to the world
    getCrafts: (callback)->
        $.get "/crafts", (crafts, textStatus, $xhr)=>
            for craftId, craftData of crafts
                @addCraft new Craft(craftData, @boi)
            callback crafts

    controlCraft: (craft)->
        @craftController = craft.control @keyboard, @socket
        @focusObject craft

    # Adds a craft to the client's world
    addCraft: (craft)->
        @crafts[craft.craftId] = craft
        @scene.add craft

    focusObject: (object)->
        C = @camera
        # Anchor camera to object's camera target
        # Reposition camera relative to object
        object.add C.target
        C.target.rotation.x = Math.PI/2
        C.target.add C
        C.position.z = KM(10000)

        $pitchAxis = new THREE.Vector3
        $yawAxis = new THREE.Vector3
        $yawAxis.copy(object.up).normalize()

        @cameraController = ()=>
            K = @keyboard
            if K.pressed "shift"
                if K.pressed "shift+up"
                    C.position.z = Math.max(C.position.z/2.0, M(10))
                if K.pressed "shift+down"
                    C.position.z = Math.min(C.position.z*2, KM(100000))
                if C.setFrame
                    C.setFrame(C.position.z)
            else
                $pitchAxis.crossVectors object.up, C.position
                $pitchAxis.normalize()
                
                if K.pressed "left"
                    C.target.rotateOnAxis $yawAxis, -0.05
                if K.pressed "right"
                    C.target.rotateOnAxis $yawAxis, +0.05
                if K.pressed "up"
                    C.target.rotateOnAxis $pitchAxis, -0.05
                if K.pressed "down"
                    C.target.rotateOnAxis $pitchAxis, +0.05
window.World = World
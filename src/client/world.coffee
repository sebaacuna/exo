class World
    constructor:(@viewport, @socket)->
        @crafts = {}
        @gameLoop = []
        @boi = new Planet('Earth', KM(6378))
        
        @createScene()
        @createCamera()
        @createRenderer()

        @keyboard = new THREEx.KeyboardState

        # Takes control of the craft
        @craftController = ()-> #No-op by default
        @gameLoop.push ()=> @craftController()

        # Photography
        @cameraController = ()-> #No-op as default
        @gameLoop.push ()=>@cameraController()

        @focusObject @boi

        @scene.add @boi
        # @scene.add new THREE.AxisHelper KM(10000)

    createScene: ()->
        @scene = new THREE.Scene()
        @scene.add new THREE.AmbientLight 0x333333
        
        dLight = new THREE.DirectionalLight 0xcccccc, 1
        # dLight.shadowBias = 5
        dLight.castShadow = true
        # dLight.shadowCameraVisible = true
        dLight.shadowCameraRight = dLight.shadowCameraTop = KM(20000)
        dLight.shadowCameraLeft = dLight.shadowCameraBottom = -KM(20000)
        dLight.shadowCameraNear = 0
        dLight.shadowCameraFar = KM(40000)
        dLight.shadowDarkness = 1
        dLight.position.set KM(20000), 0, 0

        @scene.add dLight


    createRenderer: ()->
        @renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
        @renderer.setSize @viewport.width(), @viewport.height()
        @renderer.shadowMapEnabled   = true
        @renderer.shadowMapSoft = false
        @viewport.append @renderer.domElement

    render: ()->
        @renderer.render @scene, @camera

    createCamera: ()->
        @camera = new THREE.PerspectiveCamera 90, @viewport.width()/@viewport.height(), M(1), KM(100000)
        @camera.up.copy Z
        @camera.position.z = KM(10000)
        # @camera = new THREE.OrthographicCamera -KM(8000),KM(8000),KM(8000),-KM(8000), KM(1000), KM(10000)
        @cameraControls = new THREE.OrbitControls @camera
        @cameraControls.zoomSpeed = 2
        @cameraControls.addEventListener 'change', ()=>@render()
        # @camera.target = new THREE.Object3D
        $viewport = @viewport
        # @scene.add @camera
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
            @render()
            for f in @gameLoop
                f()
            requestAnimationFrame @tick
        @tick()

    # Creates a craft on the server and adds it to the world
    createCraft: (state, callback)->
         #*(1+10*Math.random())
        state.name = prompt "Craft name"
        $.ajax
            type: "PUT"
            url:  "/crafts"
            data: JSON.stringify(state)
            processData: false
            contentType: 'application/json; charset=utf-8'
            statusCode: 
                201: (data)=>
                    craft = new Craft(data, @boi)
                    @addCraft craft
                    callback(craft)
                403: (data)->
                    alert(data)

    createOrbitingCraft: (callback)->
        @createCraft @boi.orbitalState(@boi.LO), callback

    # Gets existing crafts from server and adds them to the world
    getCrafts: (callback)->
        $.get "/crafts", (crafts, textStatus, $xhr)=>
            for craftId, craftData of crafts
                @addCraft new Craft(craftData, @boi)
            callback @crafts

    controlCraft: (craft)->
        @craftController = craft.controller @keyboard, @socket
        @focusObject craft
        craft.orbit.visible = true

    # Adds a craft to the client's world
    addCraft: (craft)->
        @crafts[craft.craftId] = craft
        @scene.add craft

    focusObject: (object)->
        object.add @camera
        @cameraControls.target.copy ORIGIN
        @cameraControls.update()
        return
        C = @camera
        # Anchor camera to object's camera target
        # Reposition camera relative to object
        # object.add C.target
        # C.target.rotation.x = Math.PI/2
        # C.target.add C
        
        object.add C
        return
        $pitchAxis = X.clone() #new THREE.Vector3
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
                # $pitchAxis.crossVectors object.up, C.position
                # $pitchAxis.normalize()
                
                if K.pressed "left"
                    C.target.rotateOnAxis $yawAxis, -0.05
                if K.pressed "right"
                    C.target.rotateOnAxis $yawAxis, +0.05
                if K.pressed "up"
                    C.target.rotateOnAxis $pitchAxis, -0.05
                if K.pressed "down"
                    C.target.rotateOnAxis $pitchAxis, +0.05
window.World = World
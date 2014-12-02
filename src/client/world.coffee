class World
    constructor:(@viewport, @socket)->
        @crafts = {}
        @boi = new Planet('Earth', KM(6378))
        
        @createScene()
        @createCamera()
        @createRenderer()
        
        @focusObject @boi
        @scene.add @boi

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
        @renderer.autoClear = false
        @viewport.append @renderer.domElement

    render: ()->
        @renderer.clear()
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

    # Adds a craft to the client's world
    addCraft: (craft)->
        @crafts[craft.craftId] = craft
        align = new THREE.Matrix4
        align.lookAt craft.mesh.rollAxis, craft.mksVelocity.clone().normalize(), craft.mesh.yawAxis
        craft.mesh.applyMatrix align
        @scene.add craft

    focusObject: (object)->
        object.add @camera
        @cameraControls.target.copy ORIGIN
        @cameraControls.update()
        
window.World = World
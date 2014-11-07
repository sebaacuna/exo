SCALE = 1

window.KM = (kms) -> M(kms)*1000
window.M = (mts) -> mts*SCALE

window.mksVector = (gameVector) -> gameVector.clone().multiplyScalar(1.0/SCALE)
window.setGameVector = (mksV, gV)-> gV.copy(mksV).multiplyScalar(SCALE)

# Helpful base vectors
window.ORIGIN = new THREE.Vector3
window.X = new THREE.Vector3 1, 0, 0
window.Y = new THREE.Vector3 0, 1, 0
window.Z = new THREE.Vector3 0, 0, 1

# Base global objects
window.scene = new THREE.Scene()
window.camera = new THREE.PerspectiveCamera 90, window.innerWidth/window.innerHeight, M(1), KM(10000000)
# window.camera = new THREE.OrthographicCamera -10,10,10,-10, M(1), KM(10000000)
# camera.up = Z
# cameraControls = new THREE.OrbitControls camera
camera.setFrame = (frameSize)->
    ratio = window.innerWidth/window.innerHeight
    @left = -frameSize*ratio
    @right = frameSize*ratio
    @top = frameSize*ratio
    @bottom = -frameSize*ratio
    @updateProjectionMatrix()

camera.target = new THREE.Object3D
renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
renderer.setSize window.innerWidth, window.innerHeight
renderer.shadowMapEnabled   = true
keyboard = new THREEx.KeyboardState
scene.add new THREE.AmbientLight 0x888888
gameLoop = []

scene.add new THREE.AxisHelper KM(10000)


window.createWorld = ()->
    window.planet = new Planet('Earth', KM(6378))
    window.crafts = {}
    window.controlledCraft = null
    scene.add planet
    socket.on "planet-#{planet.planetId}-crafts", (craftStates)->
        for id, state of craftStates
            crafts[id]?.updateState state
    focusObject planet

# Creates a craft on the server
createCraft = ()->
    state = planet.orbitalState planet.LO
    $.ajax
        type: "PUT"
        url:  "/craft"
        data: JSON.stringify(state)
        processData: false
        contentType: 'application/json; charset=utf-8'
        success: (data, textStatus, $xhr)->
            craft = new Craft(data, planet)
            addCraft craft
            controlCraft craft
            focusObject craft

# Returns existing craft
getCraft = ()->
    foundCraft = null
    $.ajax
        type: "GET"    
        url: "/craft"
        async: false
        success: (data, textStatus, $xhr)->
            craft = new Craft(data, planet)
            addCraft craft
            controlCraft craft
            focusObject craft
            foundCraft = craft
    return foundCraft

# Adds a craft to the client's world
addCraft = (craft)->
    crafts[craft.craftId] = craft
    scene.add craft
    socket.on 'craft-#{craft.id}-state', (state)->
        crafts[craft.craftId].updateState state
    socket.on "craft-#{craft.id}-destroy", ()->
        socket.off 'craft-#{craft.id}-state'
        delete crafts[craft.craftId]


# Takes control of the craft
craftController = ()-> #No-op by default
gameLoop.push ()-> craftController()

controlCraft = (craft)->
    controlledCraft = craft
    craftController = craft.control(keyboard, socket)


# Photography
cameraController = ()-> #No-op as default
gameLoop.push ()->cameraController()

focusObject = (object)->
    # Anchor camera to object's camera target
    # Reposition camera relative to object
    object.add camera.target
    camera.target.rotation.x = Math.PI/2
    camera.target.add camera
    camera.position.z = KM(10000)

    $pitchAxis = new THREE.Vector3
    $yawAxis = new THREE.Vector3
    $yawAxis.copy(object.up).normalize()

    cameraController = ()=>
        if keyboard.pressed "shift"
            if keyboard.pressed "shift+up"
                camera.position.z = Math.max(camera.position.z/2.0, M(10))
            if keyboard.pressed "shift+down"
                camera.position.z = Math.min(camera.position.z*2, KM(100000))
            if camera.setFrame
                camera.setFrame(camera.position.z)
        else
            $pitchAxis.crossVectors object.up, camera.position
            $pitchAxis.normalize()
            

            if keyboard.pressed "left"
                camera.target.rotateOnAxis $yawAxis, -0.05
            if keyboard.pressed "right"
                camera.target.rotateOnAxis $yawAxis, +0.05
            if keyboard.pressed "up"
                camera.target.rotateOnAxis $pitchAxis, -0.05
            if keyboard.pressed "down"
                camera.target.rotateOnAxis $pitchAxis, +0.05


animate = ()->
    renderer.render scene, camera
    for f in gameLoop
        f()
    requestAnimationFrame animate


window.start = ()-> 
    window.socket = io('http://localhost:8001')
    createWorld()
    animate()
    socket.on 'ready', ()->
        if not getCraft()
            createCraft()


document.body.appendChild renderer.domElement
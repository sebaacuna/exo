SCALE = 1

window.KM = (kms) -> M(kms)*1000
window.M = (mts) -> mts*SCALE

window.mksVector = (gameVector) -> gameVector.clone().multiplyScalar(1.0/SCALE)
window.setGameVector = (mksV, gV)-> gV.copy(mksV).multiplyScalar(SCALE)


$viewport = $(".viewport")

# Helpful base vectors
window.ORIGIN = new THREE.Vector3
window.X = new THREE.Vector3 1, 0, 0
window.Y = new THREE.Vector3 0, 1, 0
window.Z = new THREE.Vector3 0, 0, 1

# Base global objects
window.scene = new THREE.Scene()
window.camera = new THREE.PerspectiveCamera 90, $viewport.width()/$viewport.height(), M(1), KM(10000000)
window.keyboard = new THREEx.KeyboardState
# window.camera = new THREE.OrthographicCamera -10,10,10,-10, M(1), KM(10000000)
# camera.up = Z
# cameraControls = new THREE.OrbitControls camera
camera.setFrame = (frameSize)->
    ratio = $viewport.width()/$viewport.height()
    @left = -frameSize*ratio
    @right = frameSize*ratio
    @top = frameSize*ratio
    @bottom = -frameSize*ratio
    @updateProjectionMatrix()

camera.target = new THREE.Object3D
renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
renderer.setSize $viewport.width(), $viewport.height()
renderer.shadowMapEnabled   = true
scene.add new THREE.AmbientLight 0x888888
gameLoop = []

scene.add new THREE.AxisHelper KM(10000)


# Takes control of the craft
window.craftController = ()-> #No-op by default
gameLoop.push ()-> window.craftController()


# Photography
cameraController = ()-> #No-op as default
gameLoop.push ()->cameraController()

window.focusObject = (object)->
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
    window.world = new World(window)
    animate()
    $.get "/signin", (data)-> 
        console.log "Session ID:", data
        window.sessionID = data
        socket.emit "identify", sessionID
        socket.on 'ready', (sessionID)->
            console.log "ready", sessionID
            # if not getCraft()
            #     createCraft()


$viewport.append renderer.domElement
SCALE = 1

window.KM = (kms) -> M(kms)*1000
window.M = (mts) -> mts*SCALE

window.mksVector = (gameVector) -> gameVector.clone().multiplyScalar(1.0/SCALE)
window.setGameVector = (mksV, gV)-> gV.copy(mksV).multiplyScalar(SCALE)

window.LEO = KM(160)

# Basics
window.scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera 90, window.innerWidth/window.innerHeight, M(1), KM(10000000)
renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
renderer.setSize window.innerWidth, window.innerHeight
renderer.shadowMapEnabled   = true
# cameraControls = new THREE.OrbitControls camera
keyboard = new THREEx.KeyboardState
clock = new THREE.Clock false
scene.add new THREE.AmbientLight 0x888888
gameLoop = []

window.NULLVECTOR = new THREE.Vector3
window.X = new THREE.Vector3 1, 0, 0
window.Y = new THREE.Vector3 0, 1, 0
window.Z = new THREE.Vector3 0, 0, 1

# Prepare scene
window.setup = ()->
    planet = Planet.create('Earth', KM(6378))
    scene.add planet

    ship = new Ship M(10)
    scene.add ship
    ship.orbit planet, 4*LEO
    ship.captureCamera camera
    gameLoop.push ship.control(keyboard)
    # gameLoop.push ship.simulate()
    gameLoop.push ship.track(camera)
    gameLoop.push camera.control(keyboard, renderer)
    
    scene.add new THREE.ArrowHelper Z, NULLVECTOR, KM(100000), 0xffffff
    # refShip = new Ship M(80)
    # scene.add refShip
    # refShip.orbit planet, LEO+KM(10)

    # gameLoop.push refShip.simulate()
    # gameLoop.push refShip.track(camera)
    
    window.ship = ship


animate = ()->
    renderer.render scene, camera
    for f in gameLoop
        f()
    requestAnimationFrame animate

window.start = ()->
    setup()
    incomingPos = new THREE.Vector3
    incomingVel = new THREE.Vector3
    window.socket = io('http://localhost:8002')
    socket.on 'comm', (data)->
        console.log data
        socket.emit 'comm', 'ACK'
    socket.on 'simulation', (data)->
        for uuid, shipState of data
            if uuid == ship.uuid
                ship.updateState shipState.r, shipState.v

    socket.on 'connect', ()->
        socket.emit 'phasein',
            uuid: ship.uuid
            r: ship.mksPosition.toArray()
            v: ship.mksVelocity.toArray()
            mu: ship.boi.mu

    animate()

document.body.appendChild renderer.domElement
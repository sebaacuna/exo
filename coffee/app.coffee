SCALE = 1

window.KM = (kms) -> M(kms)*1000
window.M = (mts) -> mts*SCALE

window.mksVector = (gameVector) -> 
    vector = gameVector.clone().multiplyScalar(1.0/SCALE)
    vector.setGameVector = (v)->
        v.copy(@).multiplyScalar(SCALE)
    return vector

window.LEO = KM(160)

# Basics
window.scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera 90, window.innerWidth/window.innerHeight, M(0.001), KM(100000)
renderer = new THREE.WebGLRenderer antialias: true, logarithmicDepthBuffer: true
renderer.setSize window.innerWidth, window.innerHeight
renderer.shadowMapEnabled   = true
# cameraControls = new THREE.OrbitControls camera
keyboard = new THREEx.KeyboardState
clock = new THREE.Clock false
scene.add new THREE.AmbientLight 0x888888
gameLoop = []


# Prepare scene
window.setup = ()->
    planet = Planet.create('Earth', KM(6378))
    scene.add planet

    ship = new Ship M(10)
    scene.add ship
    ship.orbit planet, LEO
    ship.captureCamera camera
    ship.updateEllipse()

    # refShip = new Ship M(0.080)
    # scene.add refShip
    # refShip.orbit planet, LEO+KM(0.1)

    gameLoop.push ship.control(keyboard)
    # gameLoop.push ship.simulate()
    gameLoop.push camera.control(keyboard, renderer)
    # gameLoop.push refShip.simulate()
    
    window.ship = ship

window.run = ()->
    render()
    animate()

render = ()->    
    renderer.render scene, camera

animate = ()->
    # cameraControls.update();
    for f in gameLoop
        f()
    requestAnimationFrame run


document.body.appendChild renderer.domElement
# cameraControls.addEventListener 'change', render


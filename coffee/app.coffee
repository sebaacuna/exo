window.KM = (kms) -> kms/10.0
window.TON = (t)-> t
window.LEO = KM(160)

# Basics
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera 45, window.innerWidth/window.innerHeight, KM(0.0001), KM(100000)
renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize window.innerWidth, window.innerHeight
renderer.shadowMapEnabled   = true
keyboard = new THREEx.KeyboardState()

renderStack = []

# Prepare scene
window.setup = ()->
    planet = Planet.create('Earth', KM(6371))
    ship = new Ship()
    # refShip = new Ship()
    scene.add planet
    # scene.add refShip
    # refShip.orbit planet, LEO+KM(0.100), KM()
    ship.orbit planet, LEO
    ship.add camera
    camera.position.z = KM(0.1)
    scene.add new THREE.AmbientLight( 0x888888 )
    renderStack.push ship


window.render = ()->
    for f in renderStack
        if f.control
            f.control(keyboard)
        else
            f()

    if keyboard.pressed "left"
        camera.rotation.y += 0.1
    if keyboard.pressed "right"
        camera.rotation.y -= 0.1
    if keyboard.pressed "up"
        camera.position.z /= 2.0
    if keyboard.pressed "down"
        camera.position.z *= 2.0

    requestAnimationFrame render
    renderer.render scene, camera

document.body.appendChild renderer.domElement


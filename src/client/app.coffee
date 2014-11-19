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

window.start = ()->     
    socket = io('http://localhost:8001')
    window.world = new World $(".viewport"), socket
    socket.on "boi-#{@world.boi.planetId}-crafts", (craftStates)=> world.updateCrafts craftStates
    $.get "/signin", (data)-> 
        console.log "Session ID:", data
        window.sessionID = data
        socket.emit "identify", sessionID
        socket.on 'ready', (sessionID)->
            console.log "ready", sessionID
            world.start()

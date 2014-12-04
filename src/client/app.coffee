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

window.y2z = new THREE.Matrix4().makeRotationX(Math.PI/2)

window.TwoPI = Math.PI*2
window.distance = (value)->
    Math.floor(value/100)/10 + " km"

window.angle = (radians)->
    Math.floor(radians*180/Math.PI*100)/100 + " º"

window.time = (seconds)->
    return seconds + " s"
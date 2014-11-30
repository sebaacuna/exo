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
THREE = require 'three'
sim = require './sim'

class Craft
  constructor: (@craftId, state)->
    @mu = state.mu
    @r = new THREE.Vector3().fromArray state.r
    @v = new THREE.Vector3().fromArray state.v
    @thrustVector = new THREE.Vector3()

  listen: (socket)->
    console.log "listening #{@craftId}"
    socket.on "craft-#{@craftId}-thrust", (thrustVector)=>
      console.log "thrusting"
      @thrustVector.fromArray thrustVector

  energy: ()->
    0.5*@v.lengthSq()-@mu/@r.length()

  state: ()->
    craftId: @craftId
    r: @r
    v: @v
    mu: @mu

  a: ()->
    (r)=>
      #Gravity
      r2 = r.lengthSq()
      a = r.clone().normalize()
      magnitude = @mu/r2
      a.multiplyScalar -magnitude
      a.add @thrustVector

  simulate: (dt)->
    sim.rk4 @r, @v, @a(), dt
    e = @energy()
    @de = e - @e
    @e = e
      
module.exports.Craft = Craft
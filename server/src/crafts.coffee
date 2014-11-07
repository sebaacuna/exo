THREE = require 'three'
sim = require './sim'

class Craft
  constructor: (@craftId, state)->
    @mu = state.mu
    @r = new THREE.Vector3().fromArray state.r
    @v = new THREE.Vector3().fromArray state.v

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

  simulate: (dt)->
    sim.rk4 @r, @v, @a(), dt
    @e = @energy()
      
module.exports.Craft = Craft
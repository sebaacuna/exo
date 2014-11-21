THREE = require 'three'
sim = require './sim'

class Craft
  constructor: (@craftId, data)->
    @key = "craft:#{@craftId}"
    @name = data.name
    @mu = data.mu
    @r = new THREE.Vector3()
    @v = new THREE.Vector3()
    if data.r
      @r.fromArray data.r
    if data.v
      @v.fromArray data.v
    @thrustVector = new THREE.Vector3()

  store: (store)->
    store.hmset @key, {craftId: @craftId, name: @name, mu: @mu}
    store.hmset "#{@key}:r", @r 
    store.hmset "#{@key}:v", @v

  listen: (socket)->
    console.log "listening #{@craftId}"
    socket.on "craft-#{@craftId}-thrust", (thrustVector)=>
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

  report: ()->
    "#{@name} #{@de} #{@thrustVector.toArray()}"

xyzToArray = (v)-> [parseFloat(v.x), parseFloat(v.y), parseFloat(v.z)]

Craft.load = (store, key, done)->
  console.log "Loading #{key}"
  store.hgetall "#{key}:r", (err, r)->
    r = xyzToArray(r)
    store.hgetall "#{key}:v", (err, v)->
      v = xyzToArray(v)
      store.hgetall key, (err, data)->
        data.r = r
        data.v = v
        console.log "loaded #{data.craftId}"
        done new Craft(data.craftId, data)

module.exports.Craft = Craft
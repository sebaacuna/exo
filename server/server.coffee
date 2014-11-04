THREE = require 'three'
rk4 = require './rk4'
app = require('http').createServer (req, res)->
  res.writeHead(200)
  res.end('EXO')

TIMESCALE = 10

io = require('socket.io')(app)
io.on 'connection', (socket)->
  socket.emit 'comm', 'WELCOME'
  socket.on 'comm', (data)-> console.log data
  socket.on 'phasein', (data)->
    craft = new Craft data.r, data.v, data.mu
    simulation.crafts[data.uuid] = craft
    console.log "Phased in", data
    socket.on 'disconnect', ()->
      console.log "Disconnected #{data.uuid}"
      delete simulation.crafts[data.uuid]
    

class Simulation
  constructor: ()->
    @crafts = {}
    @clock = new THREE.Clock

  run: ()->
    console.log 'Simulation running'
    dt = 0.00001*TIMESCALE
    runLoop = ()=>
      simulateSeconds = @clock.getDelta()
      simulateSteps = TIMESCALE*Math.floor simulateSeconds/dt
      count = 0
      while count < simulateSteps
        for uuid, craft of @crafts
          craft.simulate dt
        ++count
      io.emit 'simulation', simulation.crafts
    @clock.start()
    setInterval runLoop, 1000/60.0
    setInterval (()->console.log simulation.crafts), 2000

# ######
class Craft
  constructor: (r,v,mu)->
    @r = new THREE.Vector3().fromArray r
    @v = new THREE.Vector3().fromArray v
    @mu = mu

  a: ()->
    (x,v,dt)=>
      #Gravity
      R2 = @r.lengthSq()
      a = @r.clone().normalize()
      magnitude = @mu/R2
      a.multiplyScalar -magnitude
      # return r.add @thrustCalc(x,v,dt)

  simulate: (dt)->
      rk4.rk4 @r, @v, @a(), dt

simulation = new Simulation
simulation.run()
console.log "Start listening"
app.listen 8002

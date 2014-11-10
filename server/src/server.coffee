express = require('express')
app = express()
crafts = require './crafts'
sim = require './sim'
server = require('http').Server app
io = require('socket.io')(server)
bodyParser = require "body-parser"
cookieParser = require "cookie-parser"
session = require "express-session"

craftRegistry = {}

app.use bodyParser.json()
app.use cookieParser()
app.use session( store: new session.MemoryStore, secret: 'BLA BLA' )
app.use '/', express.static 'www'
app.use '/js', express.static "#{__dirname}/../../client/build/"
app.use (req,res,next)->
  if not req.session.crafts
    req.session.crafts = {}
  if not craftRegistry[req.sessionID]
    craftRegistry[req.sessionID] = req.session.crafts
  next()

app.get "/signin", (req,res)->
  console.log "Signing in", req.sessionID
  res.send(req.sessionID).end()

router = express.Router()
craft_route = router.route("/crafts")
craft_route.get (req, res, next)->
  res.status(200).json(req.session.crafts).end()

craft_route.put (req, res, next)->
  n = Object.keys(req.session.crafts).length
  craft = new crafts.Craft "#{req.sessionID}-#{n}", req.body
  req.session.crafts[craft.craftId] = craft
  simulation.crafts[craft.craftId] = craft
  res.status(201).json(craft).end()
  console.log "Craft created", craft.craftId

app.use router

simulation = new sim.Simulation()    
simulation.run()
server.listen 8001
console.log "Start listening"

io.on 'connection', (socket)->
  socket.on "control", (craftId)->
    console.log craftId, "under control"
    simulation.crafts[craftId].listen socket

  socket.on "identify", (sessionID)->
    console.log "Identifying", sessionID
    socket.sessionID = sessionID
    socket.emit "ready", socket.sessionID

broadcast = ()-> io.emit 'planet-earth-crafts', simulation.crafts
setInterval broadcast, 1000/60.0
report = ()->
  for craftId, craft of simulation.crafts
    console.log craftId, ":", craft.de
setInterval report, 5000
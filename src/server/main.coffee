uuid = require "node-uuid"
express = require 'express'
app = express()
crafts = require './crafts'
sim = require './sim'
server = require('http').Server app
io = require('socket.io')(server)
bodyParser = require "body-parser"
cookieParser = require "cookie-parser"
session = require "express-session"
RedisStore = require("connect-redis")(session)
redisUrl = require("url").parse process.env.REDIS_URL
redisClient = require("redis").createClient parseInt(redisUrl.port), redisUrl.hostname

if redisUrl.auth
  redisClient.auth redisUrl.auth.split(":")[0], redisUrl.auth.split(":")[1]

craftRegistry = {}

app.use bodyParser.json()
app.use cookieParser()
app.use session 
  store: new RedisStore client:redisClient
  secret: process.env.SECRET

app.use '/', express.static 'www'
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
  res.status(200).json(simulation.crafts).end()

craft_route.put (req, res, next)->
  n = Object.keys(req.session.crafts).length
  craft = new crafts.Craft req.body.name, req.body
  if not simulation.addCraft craft
    res.status(403).send("Craft already exists").end()
    return
  res.status(201).json(craft).end()
  console.log "Craft created", craft.craftId

app.use router

simulation = new sim.Simulation redisClient
simulation.loadCrafts ()->simulation.run()
server.listen process.env.PORT
console.log "Start listening"

io.on 'connection', (socket)->
  socket.on "control", (craftId)->
    console.log craftId, "under control"
    simulation.crafts[craftId]?.listen socket

  socket.on "identify", (sessionID)->
    console.log "Identifying", sessionID
    socket.sessionID = sessionID
    socket.emit "ready", socket.sessionID

broadcast = ()-> io.emit 'boi-earth-crafts', simulation.crafts
setInterval broadcast, 1000/60.0
report = ()->
  console.log "------"
  for craftId, craft of simulation.crafts
    console.log craft.report()
setInterval report, 2000
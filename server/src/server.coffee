express = require('express')
app = express()
crafts = require './crafts'
sim = require './sim'
server = require('http').Server app
io = require('socket.io')(server)
bodyParser = require "body-parser"
cookieParser = require "cookie-parser"
session = require "express-session"

router = express.Router()
craft_route = router.route("/craft")
craft_route.get (req, res, next)->
  if req.session.craft
    res.status(200).json(req.session.craft).end()
    console.log "Found craft", req.session.craft
  else
    res.status(404).end()
    console.log "Craft not found"

craft_route.put (req, res, next)->
  craft = new crafts.Craft req.sessionID, req.body
  req.session.craft = craft
  simulation.crafts = {} #TEMP
  simulation.crafts[req.sessionID] = craft
  res.status(201).json(craft).end()
  req.session.destroy() #TEMP
  console.log "Craft created"
  console.log craft

app.use bodyParser.json()
app.use cookieParser()
app.use session( store: new session.MemoryStore, secret: 'BLA BLA' )
app.use router
app.use '/', express.static 'www'
app.use '/js', express.static "#{__dirname}/../../client/build/"


simulation = new sim.Simulation()    
simulation.run()
server.listen 8001
console.log "Start listening"
broadcast = ()-> io.emit 'planet-earth-crafts', simulation.crafts
setInterval broadcast, 1000/60.0
report = ()-> console.log simulation.crafts
setInterval report, 1000
app = require('http').createServer (req, res)->
    res.writeHead(200)
    res.end('EXO')
    
io = require('socket.io')(app)
fs = require('fs')
io.on 'connection', (socket)->
    socket.emit 'comm', {hello: 'world'}
    socket.on 'comm', (data)->
        console.log data

app.listen 8002
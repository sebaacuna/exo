class Game
    constructor: ()->
        @socket = io('http://localhost:8001')
        @world = new World $(".viewport"), @socket
        @hud = new HUD @world.renderer
        
        @loop = []
        @loop.push ()=> @world.craftController()
        @loop.push ()=> @world.cameraController()
        
        @socket.on "boi-#{@world.boi.planetId}-crafts", (craftStates)=> 
            @world.updateCrafts craftStates
        
    start: ()->     
        $.get "/signin", (sessionID)=> 
            @socket.emit "identify", sessionID
            @socket.on 'ready', (sessionID)=>
                @run()

    run: ()->
        tick = ()=>
            @world.render()
            @hud.render()
            for f in @loop
                f()
            requestAnimationFrame tick
        tick()

window.Game = Game
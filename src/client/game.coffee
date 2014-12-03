class Game
    constructor: ()->
        @socket = io('http://localhost:8001')
        @world = new World $(".viewport"), @socket
        @hud = new HUD @world.renderer
        
        @loop = []
        @socket.on "boi-#{@world.boi.planetId}-crafts", (craftStates)=> 
            @world.updateCrafts craftStates

        @keyboard = new THREEx.KeyboardState
        
    start: ()->     
        $.get "/signin", (sessionID)=> 
            @socket.emit "identify", sessionID
            @socket.on 'ready', (sessionID)=>
                @run()

    run: ()->
        counter = 0
        tick = ()=>
            @world.render()
            @hud.render()
            for f,i in @loop
                f(counter)
            ++counter
            requestAnimationFrame tick
        tick()

window.Game = Game
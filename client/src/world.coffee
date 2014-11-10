class World
    constructor:(@game)->
        @planet = new Planet('Earth', KM(6378))
        @crafts = {}
        @game.scene.add @planet
        @game.socket.on "planet-#{@planet.planetId}-crafts", (craftStates)=>
            for id, state of craftStates
                @crafts[id]?.updateState state
        @game.focusObject @planet


    # Creates a craft on the server and adds it to the world
    createCraft: (callback)->
        state = @planet.orbitalState @planet.LO*(1+10*Math.random())
        $.ajax
            type: "PUT"
            url:  "/crafts"
            data: JSON.stringify(state)
            processData: false
            contentType: 'application/json; charset=utf-8'
            success: (data, textStatus, $xhr)=>
                craft = new Craft(data, @planet)
                @addCraft craft
                # @controlCraft craft
                # @focusObject craft
                callback(craft)

    # Gets existing crafts from server and adds them to the world
    getCrafts: (callback)->
        $.get "/crafts", (crafts, textStatus, $xhr)=>
            for craftId, craftData of crafts
                @addCraft new Craft(craftData, @planet)
            callback crafts

    controlCraft: (craft)->
        @game.craftController = craft.control(@game.keyboard, @game.socket)
        @game.focusObject craft

    # Adds a craft to the client's world
    addCraft: (craft)->
        @crafts[craft.craftId] = craft
        @game.scene.add craft

window.World = World
class MainController
    constructor: ($scope)->
        world = window.game.world
        window.game.loop.push (counter)-> $scope.$apply()
        window.game.loop.push (counter)=> @craftControl()
        window.game.loop.push (counter)->
            if $scope.target and counter%10 == 0
                $scope.orbitIntersector.solve()
                return true

        $scope.createOrbitingCraft = ()=> 
            world.createOrbitingCraft (craft)-> 
                $scope.$apply()
        
        $scope.controlCraft = (craft)=>
            @releaseControl()
            craft.orbit.line.material.color.setHex 0x00A1CB
            $scope.controlledCraft = craft
            @craftControl = craft.controller(window.game)
            world.focusObject craft
            craft.orbit.visible = true
            window.game.hud.setCraft craft

        $scope.targetCraft = (craft)=>
            @releaseTarget()
            craft.orbit.line.material.color.setHex 0x61AE24
            craft.orbit.visible = true
            $scope.target = craft
            $scope.orbitIntersector = new OrbitIntersector(
                world
                $scope.controlledCraft.orbit
                $scope.target.orbit
                )

        $scope.releaseControl = ()=>
            @releaseControl()

        $scope.releaseTarget = ()=>
            @releaseTarget()

        world.getCrafts (crafts)=>
            $scope.$apply()

        @world = $scope.world = world
        @scope = $scope

    craftControl: ()->

    releaseTarget: ()->
        @scope.orbitIntersector?.remove()
        @scope.target?.orbit.visible = false
        @scope.target = null

    releaseControl: ()->
        @craftControl = ()->
        @scope.orbitIntersector?.remove()
        @scope.controlledCraft?.orbit.visible = false
        @scope.controlledCraft = null
        @releaseTarget()
        @world.focusObject @world.boi

class InstrumentsController
    constructor: ($scope)->
        $scope.instrumentData = (c)-> c.instruments

class TargetMetricsController
    constructor: ($scope)->
        $scope.instrumentData = ()-> $scope.orbitIntersector.instruments


window.exoApp = angular.module "exo", []
exoApp.controller "MainController", MainController
exoApp.controller "InstrumentsController", InstrumentsController
exoApp.controller "TargetMetricsController", TargetMetricsController
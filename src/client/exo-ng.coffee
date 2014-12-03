class AdminController
    constructor: ($scope)->
        world = window.game.world
        window.game.loop.push (counter)-> $scope.$digest()
        window.game.loop.push (counter)=> @craftControl()
        window.game.loop.push (counter)->
            if $scope.target and counter%10 == 0
                $scope.orbitIntersector.solve()
                return true

        $scope.createOrbitingCraft = ()-> 
            world.createOrbitingCraft (craft)-> 
                $scope.$digest()
        
        $scope.controlCraft = (craft)=>
            $scope.orbitIntersector?.remove()
            $scope.controlledCraft?.orbit.visible = false
            craft.orbit.line.material.color.setHex 0x0000ff
            $scope.controlledCraft = craft
            if $scope.target == craft
                $scope.target = null
            @craftControl = craft.controller(window.game)
            world.focusObject craft
            craft.orbit.visible = true
            window.game.hud.setCraft craft
            $scope.$digest()

        $scope.targetCraft = (craft)->
            $scope.orbitIntersector?.remove()
            craft.orbit.line.material.color.setHex 0x00ff00
            craft.orbit.visible = true
            $scope.target = craft
            $scope.orbitIntersector = new OrbitIntersector(
                world
                $scope.controlledCraft.orbit
                $scope.target.orbit
                )
            $scope.$digest()

        $scope.eccentricity = ()->
            Math.floor($scope.controlledCraft?.orbit.curve.ecc*100)/100

        world.getCrafts (crafts)->
            $scope.$digest()

        $scope.world = world

    craftControl: ()->


class TargetController
    constructor: ($scope)->
        $scope.inclination = ()-> 
            dot = $scope.controlledCraft.orbit.north.dot $scope.target.orbit.north
            dot = Math.floor(dot*1e8)*1e-8
            angle = Math.acos dot
            angle = Math.floor(angle*1e4)*1e-4
            angle*180/Math.PI

window.exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
exoApp.controller "TargetController", TargetController
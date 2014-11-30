class AdminController
    constructor: ($scope, $http)->
        world = window.game.world
        window.game.loop.push ()-> $scope.$digest()

        $scope.createOrbitingCraft = ()-> 
            world.createOrbitingCraft (craft)-> 
                $scope.$digest()
        
        $scope.controlCraft = (craft)->
            $scope.controlledCraft?.orbit.visible = false
            craft.orbit.line.material.color.setHex 0x0000ff
            craft.orbit.visible = true
            $scope.controlledCraft = craft
            if $scope.target == craft
                $scope.target = null
            world.controlCraft craft
            $scope.$digest()

        $scope.targetCraft = (craft)->
            craft.orbit.line.material.color.setHex 0x00ff00
            craft.orbit.visible = true
            $scope.target = craft
            $scope.$digest()

        $scope.eccentricity = ()->
            Math.floor(world.controlledCraft?.orbit.curve.ecc*100)/100

        world.getCrafts (crafts)->
            $scope.$digest()

        $scope.world = world


window.exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
class AdminController
    constructor: ($scope, $http)->
        $scope.world = window.world
        $scope.createCraft = ()-> 
            world.createCraft (craft)-> 
                $scope.$digest()
        
        $scope.controlCraft = (craft)->
            world.controlCraft craft
            $scope.$digest()

        $scope.eccentricity = ()->
            Math.floor(world.controlledCraft?.orbit.curve.ecc*100)/100

        world.getCrafts (crafts)->
            $scope.$digest()

        setInterval(
            ()->
                $scope.$digest()
            1000
            )


exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
class AdminController
    constructor: ($scope, $http)->
        $scope.world = window.world
        $scope.createCraft = ()-> 
            world.createCraft (craft)-> 
                $scope.$digest()
        
        $scope.controlCraft = (craft)->
            world.controlCraft craft
            $scope.digest()


        world.getCrafts (crafts)->
            $scope.$digest()


exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
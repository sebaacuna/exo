class AdminController
    constructor: ($scope, $http)->
        $scope.crafts = []
        $scope.createCraft = ()-> 
            world.createCraft (craft)-> 
                $scope.crafts.push craft
                $scope.$digest()
        
        $scope.controlCraft = (craft)->
            world.controlCraft craft


        world.getCrafts (crafts)->
            $scope.crafts = []
            for craftId, craft of crafts
                $scope.crafts.push craft
            $scope.$digest()
            console.log $scope.crafts


exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
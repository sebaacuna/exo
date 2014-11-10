class AdminController
    constructor: ($scope, $http)->
        $scope.crafts = []
        $scope.createCraft = ()-> 
            world.createCraft (craft)-> 
                $scope.crafts.push craft
                $scope.$digest()
        
        $scope.controlCraft = (craft)->
            world.controlCraft 


        world.getCrafts (crafts)->
            $scope.crafts = []
            for craftId, craft of crafts
                $scope.crafts.push craft
            $scope.$digest()


exoApp = angular.module "exo", []
exoApp.controller "AdminController", AdminController
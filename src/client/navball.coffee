MARKER_SIZE = 0.1
MARKER_THICKNESS = 0.02

proGeometry = new THREE.CylinderGeometry MARKER_SIZE, MARKER_SIZE, MARKER_THICKNESS, 16
proGeometry.applyMatrix y2z

retroGeometry = new THREE.TorusGeometry MARKER_SIZE*0.7, MARKER_THICKNESS, 6, 36


class Marker extends THREE.Mesh
    constructor: (color, geometry)->
        super
        @geometry = geometry
        @material = new THREE.MeshLambertMaterial 
            color:color
            emissive: color
        @material.emissive.offsetHSL 0, -0.25, 0

    update: (vector)->
        @position.copy(vector).normalize()
        @lookAt ORIGIN


class Navball extends THREE.Object3D
    constructor: (@size)->
        super
        @visible = false
        @useQuaternion = true
        @up.copy Z
        @Q = new THREE.Quaternion


        @ball = new THREE.Mesh(
            new THREE.SphereGeometry @size, 24, 24
            new THREE.MeshPhongMaterial
                map : THREE.ImageUtils.loadTexture('images/navball.png')
                bumpMap : THREE.ImageUtils.loadTexture('images/navball.png')
                bumpScale: 0.01
        )

        @ball.geometry.applyMatrix y2z
        @ball.up.copy Z
        @ball.useQuaternion= true

        @heading = new THREE.Mesh(
            new THREE.TorusGeometry MARKER_SIZE, MARKER_SIZE/5, 6, 36
            new THREE.MeshLambertMaterial 
                color: 'yellow'
        )
        @heading.up.copy Z

        # Markers
        @markers = []
        @addMarker color:'green', vector:()=> @craft.mksVelocity
        @addMarker color:'cyan', vector:()=> @craft.mksPosition
        @addMarker color:'magenta', vector:()=> @craft.mksH

        @add @heading
        @add @ball
        @ballMatrix = new THREE.Matrix4

    addMarker: (params)->
        if params.retro is false
            pro = new Marker params.color, proGeometry
            @markers.push ()=> pro.update params.vector()
            @add pro
        else
            pro = new Marker params.color, proGeometry
            retro = new Marker params.color, retroGeometry
            @add pro
            @add retro
            @markers.push ()=>
                v = params.vector().clone()
                pro.update v
                retro.update v.negate()

    setCraft: (@craft)->
        @visible = true

    update: ()->
        if not @craft
            return

        for m in @markers
            m()

        # Orient ball to point Z towards outward direction
        @ball.quaternion.setFromUnitVectors @craft.orbit.out, Z.clone().negate()
        x = X.clone().applyQuaternion @ball.quaternion
        y = Y.clone().applyQuaternion @ball.quaternion

        # Orient ball to point X towards north direction
        angle = Math.acos x.dot(@craft.orbit.north)
        if x.dot(@craft.orbit.west) < 0
            angle = TwoPI - angle
        @Q.setFromAxisAngle Z, -angle
        @ball.quaternion.multiply @Q

        rollAxis = @craft.mesh.rollAxis.clone().applyEuler @craft.mesh.rotation
        yawAxis = @craft.mesh.yawAxis.clone().applyEuler @craft.mesh.rotation
        pitchAxis = @craft.mesh.pitchAxis.clone().applyEuler @craft.mesh.rotation

        # Look at ball straight on through rollAxis
        @quaternion.setFromUnitVectors rollAxis, @up
        yawAxis.applyQuaternion @quaternion
        pitchAxis.applyQuaternion @quaternion

        # Look at ball so that yaw axis points upwards on screen
        screenUp = Y
        angle = Math.acos screenUp.dot(yawAxis)
        if screenUp.dot(pitchAxis) < 0
            angle = TwoPI - angle
        @Q.setFromAxisAngle rollAxis, -angle
        
        @quaternion.multiply @Q
        rollAxis.applyQuaternion @Q
        
        # Update heading marker
        @heading.position.copy rollAxis
        @heading.lookAt ORIGIN



window.Navball = Navball

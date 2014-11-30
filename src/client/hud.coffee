class HUD
  constructor: (@renderer)->
    @height = $(@renderer.domElement).height()
    @width = $(@renderer.domElement).width()
    @far = 400
    @createScene()
    @setup()
    @createCamera()

  createScene: ()->
    @scene = new THREE.Scene()
    # @scene.add new THREE.AmbientLight 0x333333
    @scene.add new THREE.AxisHelper 10

  setup: ()->
    @navball = new THREE.Mesh(
        new THREE.SphereGeometry 50, 10, 10
        new THREE.MeshBasicMaterial color: 0x8888ff, wireframe: true
      )
    @navball.position.x = 55
    @navball.position.y = 55
    @scene.add @navball

  createCamera: ()->
    @camera = new THREE.OrthographicCamera -@width/2, @width/2, @height/2, -@height/2, 1, @far
    @camera.position.x = @width/2
    @camera.position.y = @height/2
    @camera.position.z = -@far/2
    focus = @camera.position.clone()
    focus.z = 0
    @camera.lookAt focus

  render: ()->
    @renderer.clearDepth()
    @renderer.render @scene, @camera

  update: ()->


window.HUD = HUD
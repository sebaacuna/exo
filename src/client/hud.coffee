class HUD
  scale: 80
  constructor: (@renderer)->
    @height = $(@renderer.domElement).height()/@scale
    @width = $(@renderer.domElement).width()/@scale
    @createScene()
    @setup()
    @createCamera()

  createScene: ()->
    @scene = new THREE.Scene()
    @scene.add new THREE.AmbientLight 0x666666
    dLight = new THREE.DirectionalLight 0xffffff, 0.75
    dLight.position.copy Y.clone() #.negate()
    @scene.add dLight

  setup: ()->
    @navball = new Navball(1)
    @scene.add @navball

  createCamera: ()->
    @camera = new THREE.OrthographicCamera -@width/2, @width/2, @height/2, -@height/2, 0.05, 100
    @camera.position.copy @navball.up
    @camera.position.multiplyScalar 100
    @camera.position.y = @height/2 - (@scale+5)/@scale
    focus = @camera.position.clone()
    focus.z = 0
    @camera.lookAt focus

  render: ()->
    @navball.update()
    @renderer.clearDepth()
    @renderer.render @scene, @camera

  setCraft: (@craft)->
    @navball.setCraft @craft

window.HUD = HUD

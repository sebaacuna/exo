(function() {
  var camera, keyboard, renderStack, renderer, scene;

  window.KM = function(kms) {
    return kms / 10.0;
  };

  window.TON = function(t) {
    return t;
  };

  window.LEO = KM(160);

  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, KM(0.0001), KM(100000));

  renderer = new THREE.WebGLRenderer({
    antialias: true
  });

  renderer.setSize(window.innerWidth, window.innerHeight);

  renderer.shadowMapEnabled = true;

  keyboard = new THREEx.KeyboardState();

  renderStack = [];

  window.setup = function() {
    var planet, ship;
    planet = Planet.create('Earth', KM(6371));
    ship = new Ship();
    scene.add(planet);
    ship.orbit(planet, LEO);
    ship.add(camera);
    camera.position.z = KM(0.1);
    scene.add(new THREE.AmbientLight(0x888888));
    return renderStack.push(ship);
  };

  window.render = function() {
    var f, _i, _len;
    for (_i = 0, _len = renderStack.length; _i < _len; _i++) {
      f = renderStack[_i];
      if (f.control) {
        f.control(keyboard);
      } else {
        f();
      }
    }
    if (keyboard.pressed("left")) {
      camera.rotation.y += 0.1;
    }
    if (keyboard.pressed("right")) {
      camera.rotation.y -= 0.1;
    }
    if (keyboard.pressed("up")) {
      camera.position.z /= 2.0;
    }
    if (keyboard.pressed("down")) {
      camera.position.z *= 2.0;
    }
    requestAnimationFrame(render);
    return renderer.render(scene, camera);
  };

  document.body.appendChild(renderer.domElement);

}).call(this);

(function() {
  var G, Planet, Ship,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  G = 6.67384e-5;

  Planet = {
    create: function(name, radius) {
      var canonicalSize, matrix, mesh, ratio;
      mesh = THREEx.Planets["create" + name]();
      mesh.radius = radius;
      canonicalSize = 0.5;
      ratio = radius / canonicalSize;
      matrix = new THREE.Matrix4().makeScale(ratio, ratio, ratio);
      mesh.applyMatrix(matrix);
      return mesh;
    }
  };

  Ship = (function(_super) {
    __extends(Ship, _super);

    function Ship() {
      var size;
      Ship.__super__.constructor.apply(this, arguments);
      size = KM(0.01);
      this.geometry = new THREE.BoxGeometry(size, size, size);
      this.material = new THREE.MeshBasicMaterial({
        color: 0x006600
      });
      this.mass = TON(1);
      this.mu = G * this.mass;
      this.orbitCenter = new THREE.Object3D();
    }

    Ship.prototype.orbit = function(planet, altitude) {
      this.position.x = planet.radius + altitude;
      this.velocity = Math.sqrt(G * this.mass / this.position.x);
      this.orbitCenter.position = planet.position;
      this.orbitCenter.add(this);
      return planet.parent.add(this.orbitCenter);
    };

    Ship.prototype.simulate = function(dt) {
      var _ref;
      return _ref = [], this.position = _ref[0], this.velocity = _ref[1], _ref;
    };

    Ship.prototype.control = function(keyboard) {
      this.orbitCenter.rotation.y += 0.001;
      if (keyboard.pressed("w")) {
        this.rotation.y -= 0.1;
      }
      if (keyboard.pressed("s")) {
        this.rotation.y += 0.1;
      }
      if (keyboard.pressed("d")) {
        this.rotation.wez += 0.1;
      }
      if (keyboard.pressed("a")) {
        return this.rotation.z -= 0.1;
      }
    };

    return Ship;

  })(THREE.Mesh);

  window.Planet = Planet;

  window.Ship = Ship;

}).call(this);

(function() {
  window.THREEx = window.THREEx || {};

  window.THREEx.rk4 = function(x, v, a, dt) {
    var a1, a2, a3, a4, v1, v2, v3, v4, vf, x1, x2, x3, x4, xf;
    x1 = x;
    v1 = v;
    a1 = a(x1, v1, 0);
    x2 = x + 0.5 * v1 * dt;
    v2 = v + 0.5 * a1 * dt;
    a2 = a(x2, v2, dt / 2);
    x3 = x + 0.5 * v2 * dt;
    v3 = v + 0.5 * a2 * dt;
    a3 = a(x3, v3, dt / 2);
    x4 = x + v3 * dt;
    v4 = v + a3 * dt;
    a4 = a(x4, v4, dt);
    xf = x + (dt / 6) * (v1 + 2 * v2 + 2 * v3 + v4);
    vf = v + (dt / 6) * (a1 + 2 * a2 + 2 * a3 + a4);
    return [xf, vf];
  };

}).call(this);

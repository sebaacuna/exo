(function() {
  var SCALE, addCraft, animate, cameraController, controlCraft, craftController, createCraft, focusObject, gameLoop, getCraft, keyboard, renderer;

  SCALE = 1;

  window.KM = function(kms) {
    return M(kms) * 1000;
  };

  window.M = function(mts) {
    return mts * SCALE;
  };

  window.mksVector = function(gameVector) {
    return gameVector.clone().multiplyScalar(1.0 / SCALE);
  };

  window.setGameVector = function(mksV, gV) {
    return gV.copy(mksV).multiplyScalar(SCALE);
  };

  window.ORIGIN = new THREE.Vector3;

  window.X = new THREE.Vector3(1, 0, 0);

  window.Y = new THREE.Vector3(0, 1, 0);

  window.Z = new THREE.Vector3(0, 0, 1);

  window.scene = new THREE.Scene();

  window.camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, M(1), KM(10000000));

  camera.setFrame = function(frameSize) {
    var ratio;
    ratio = window.innerWidth / window.innerHeight;
    this.left = -frameSize * ratio;
    this.right = frameSize * ratio;
    this.top = frameSize * ratio;
    this.bottom = -frameSize * ratio;
    return this.updateProjectionMatrix();
  };

  camera.target = new THREE.Object3D;

  renderer = new THREE.WebGLRenderer({
    antialias: true,
    logarithmicDepthBuffer: true
  });

  renderer.setSize(window.innerWidth, window.innerHeight);

  renderer.shadowMapEnabled = true;

  keyboard = new THREEx.KeyboardState;

  scene.add(new THREE.AmbientLight(0x888888));

  gameLoop = [];

  scene.add(new THREE.AxisHelper(KM(10000)));

  window.createWorld = function() {
    window.planet = new Planet('Earth', KM(6378));
    window.crafts = {};
    window.controlledCraft = null;
    scene.add(planet);
    socket.on("planet-" + planet.planetId + "-crafts", function(craftStates) {
      var id, state, _ref, _results;
      _results = [];
      for (id in craftStates) {
        state = craftStates[id];
        _results.push((_ref = crafts[id]) != null ? _ref.updateState(state) : void 0);
      }
      return _results;
    });
    return focusObject(planet);
  };

  createCraft = function() {
    var state;
    state = planet.orbitalState(planet.LO);
    return $.ajax({
      type: "PUT",
      url: "/craft",
      data: JSON.stringify(state),
      processData: false,
      contentType: 'application/json; charset=utf-8',
      success: function(data, textStatus, $xhr) {
        var craft;
        craft = new Craft(data, planet);
        addCraft(craft);
        controlCraft(craft);
        return focusObject(craft);
      }
    });
  };

  getCraft = function() {
    var foundCraft;
    foundCraft = null;
    $.ajax({
      type: "GET",
      url: "/craft",
      async: false,
      success: function(data, textStatus, $xhr) {
        var craft;
        craft = new Craft(data, planet);
        addCraft(craft);
        controlCraft(craft);
        focusObject(craft);
        return foundCraft = craft;
      }
    });
    return foundCraft;
  };

  addCraft = function(craft) {
    crafts[craft.craftId] = craft;
    scene.add(craft);
    socket.on('craft-#{craft.id}-state', function(state) {
      return crafts[craft.craftId].updateState(state);
    });
    return socket.on("craft-" + craft.id + "-destroy", function() {
      socket.off('craft-#{craft.id}-state');
      return delete crafts[craft.craftId];
    });
  };

  craftController = function() {};

  gameLoop.push(function() {
    return craftController();
  });

  controlCraft = function(craft) {
    var controlledCraft;
    controlledCraft = craft;
    return craftController = craft.control(keyboard, socket);
  };

  cameraController = function() {};

  gameLoop.push(function() {
    return cameraController();
  });

  focusObject = function(object) {
    var $pitchAxis, $yawAxis;
    object.add(camera.target);
    camera.target.rotation.x = Math.PI / 2;
    camera.target.add(camera);
    camera.position.z = KM(10000);
    $pitchAxis = new THREE.Vector3;
    $yawAxis = new THREE.Vector3;
    $yawAxis.copy(object.up).normalize();
    return cameraController = (function(_this) {
      return function() {
        if (keyboard.pressed("shift")) {
          if (keyboard.pressed("shift+up")) {
            camera.position.z = Math.max(camera.position.z / 2.0, M(10));
          }
          if (keyboard.pressed("shift+down")) {
            camera.position.z = Math.min(camera.position.z * 2, KM(100000));
          }
          if (camera.setFrame) {
            return camera.setFrame(camera.position.z);
          }
        } else {
          $pitchAxis.crossVectors(object.up, camera.position);
          $pitchAxis.normalize();
          if (keyboard.pressed("left")) {
            camera.target.rotateOnAxis($yawAxis, -0.05);
          }
          if (keyboard.pressed("right")) {
            camera.target.rotateOnAxis($yawAxis, +0.05);
          }
          if (keyboard.pressed("up")) {
            camera.target.rotateOnAxis($pitchAxis, -0.05);
          }
          if (keyboard.pressed("down")) {
            return camera.target.rotateOnAxis($pitchAxis, +0.05);
          }
        }
      };
    })(this);
  };

  animate = function() {
    var f, _i, _len;
    renderer.render(scene, camera);
    for (_i = 0, _len = gameLoop.length; _i < _len; _i++) {
      f = gameLoop[_i];
      f();
    }
    return requestAnimationFrame(animate);
  };

  window.start = function() {
    window.socket = io('http://localhost:8001');
    createWorld();
    animate();
    return socket.on('ready', function() {
      if (!getCraft()) {
        return createCraft();
      }
    });
  };

  document.body.appendChild(renderer.domElement);

}).call(this);

(function() {
  var $acceleration, Craft,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $acceleration = new THREE.Vector3;

  Craft = (function(_super) {
    __extends(Craft, _super);

    function Craft(data, planet) {
      var size;
      this.planet = planet;
      Craft.__super__.constructor.apply(this, arguments);
      this.craftId = data.craftId;
      this.channel = "craft-" + this.craftId;
      size = M(30);
      this.mksMass = 1000;
      this.mesh = new THREE.Mesh;
      this.mesh.geometry = new THREE.CylinderGeometry(size * 0.25, size * 0.5, size);
      this.mesh.material = new THREE.MeshBasicMaterial({
        color: 0x006600
      });
      this.mesh.matrixAutoUpdate = true;
      this.add(this.mesh);
      this.mksPosition = new THREE.Vector3;
      this.mksVelocity = new THREE.Vector3;
      this.mesh.rollAxis = this.mesh.up;
      this.mesh.yawAxis = X;
      if (0 === this.mesh.yawAxis.angleTo(this.mesh.rollAxis)) {
        this.mesh.yawAxis = Y;
      }
      this.mesh.pitchAxis = (new THREE.Vector3).crossVectors(this.mesh.yawAxis, this.mesh.rollAxis);
      this.velArrow = new THREE.ArrowHelper(X, ORIGIN, KM(1000), 0x00ff00);
      this.add(this.velArrow);
      this.accelArrow = new THREE.ArrowHelper(X, ORIGIN, KM(1000), 0xff0000);
      this.add(this.accelArrow);
      this.thrustArrow = new THREE.ArrowHelper(this.mesh.rollAxis, ORIGIN, 0, 0xffffff);
      this.mesh.add(this.thrustArrow);
      this.throttle = 0;
      this.mesh.add(new THREE.AxisHelper(KM(1000)));
      this.consoleElems = {};
      this.orbit = new Orbit(this.planet);
      this.updateState(data);
      window.orbit = this.orbit;
    }

    Craft.prototype.updateState = function(state) {
      var oldV, _ref, _ref1, _ref2;
      oldV = this.mksVelocity.clone();
      this.mksPosition.copy(state.r);
      this.mksVelocity.copy(state.v);
      this.orbit.update(this.mksPosition, this.mksVelocity);
      setGameVector(this.mksPosition, this.position);
      $acceleration.subVectors(oldV, this.mksVelocity);
      if ((_ref = this.velArrow) != null) {
        _ref.setDirection(this.mksVelocity.normalize());
      }
      if ((_ref1 = this.accelArrow) != null) {
        _ref1.setLength($acceleration.length());
      }
      return (_ref2 = this.accelArrow) != null ? _ref2.setDirection($acceleration.normalize()) : void 0;
    };

    Craft.prototype.control = function(keyboard, socket) {
      var setThrust, thrustEnd, thrustStart;
      socket.emit("control", this.craftId);
      thrustStart = (function(_this) {
        return function(event) {
          if (event.keyCode === 32) {
            return setThrust(1.0);
          }
        };
      })(this);
      thrustEnd = (function(_this) {
        return function(event) {
          if (event.keyCode === 32) {
            return setThrust(0.0);
          }
        };
      })(this);
      setThrust = (function(_this) {
        return function(throttle) {
          var v;
          if (throttle !== _this.throttle) {
            _this.throttle = throttle;
            v = _this.thrustVector();
            console.log("Throttle", throttle, v);
            return socket.emit("" + _this.channel + "-thrust", v.toArray());
          }
        };
      })(this);
      document.addEventListener("keydown", thrustStart, false);
      document.addEventListener("keyup", thrustEnd, false);
      return (function(_this) {
        return function() {
          if (keyboard.pressed("w")) {
            _this.mesh.rotateOnAxis(_this.mesh.pitchAxis, -0.05);
          }
          if (keyboard.pressed("s")) {
            _this.mesh.rotateOnAxis(_this.mesh.pitchAxis, 0.05);
          }
          if (keyboard.pressed("d")) {
            _this.mesh.rotateOnAxis(_this.mesh.yawAxis, -0.05);
          }
          if (keyboard.pressed("a")) {
            _this.mesh.rotateOnAxis(_this.mesh.yawAxis, 0.05);
          }
          if (keyboard.pressed("q")) {
            _this.mesh.rotateOnAxis(_this.mesh.rollAxis, 0.05);
          }
          if (keyboard.pressed("e")) {
            return _this.mesh.rotateOnAxis(_this.mesh.rollAxis, -0.05);
          }
        };
      })(this);
    };

    Craft.prototype.thrustVector = function() {
      var F, vector;
      if (this.throttle === 0) {
        this.thrustArrow.setLength(0);
        return ORIGIN;
      } else {
        F = 200000;
        vector = this.mesh.rollAxis.clone();
        this.thrustArrow.setDirection(vector);
        this.thrustArrow.setLength(KM(1000) * this.throttle);
        vector.applyMatrix4(this.mesh.matrix);
        vector.multiplyScalar(F / this.mksMass);
        return vector;
      }
    };

    return Craft;

  })(THREE.Object3D);

  window.Craft = Craft;

}).call(this);

(function() {
  var ELLIPSE_POINTS, Orbit, uiCage, _inclineAxis,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  uiCage = function(size, color) {
    var mesh;
    mesh = new THREE.Mesh;
    mesh.geometry = new THREE.BoxGeometry(KM(100), KM(100), KM(100));
    mesh.material = new THREE.MeshBasicMaterial({
      color: color,
      wireframe: true,
      depthTest: true
    });
    return mesh;
  };

  ELLIPSE_POINTS = 500;

  _inclineAxis = new THREE.Vector3;

  Orbit = (function(_super) {
    __extends(Orbit, _super);

    function Orbit(planet) {
      var geometry, i, material, _i;
      this.planet = planet;
      Orbit.__super__.constructor.apply(this, arguments);
      this.ev = new THREE.Vector3;
      this.h = new THREE.Vector3;
      this.craftCage = uiCage(KM(10), 0xff0000);
      this.add(this.craftCage);
      this.periapsisCage = uiCage(KM(10), 0x00ff00);
      this.add(this.periapsisCage);
      this.apoapsisCage = uiCage(KM(10), 0x0000ff);
      this.add(this.apoapsisCage);
      material = new THREE.LineBasicMaterial({
        linewidth: 1,
        color: 0x00ffff,
        depthTest: true
      });
      geometry = new THREE.Geometry;
      geometry.dynamic = true;
      for (i = _i = 0; 0 <= ELLIPSE_POINTS ? _i <= ELLIPSE_POINTS : _i >= ELLIPSE_POINTS; i = 0 <= ELLIPSE_POINTS ? ++_i : --_i) {
        geometry.vertices.push(new THREE.Vector3);
      }
      this.line = new THREE.Line(geometry, material);
      this.add(this.line);
      this.planet.add(this);
    }

    Orbit.prototype.update = function(r, v) {
      var P, ecc, ecc2, ellipse, lineX, path, semiMajor, semiMinor;
      this.h.crossVectors(r, v);
      this.ev.crossVectors(v, this.h).multiplyScalar(1 / this.planet.mu);
      this.ev.sub(r.clone().normalize());
      ecc = this.ev.length();
      ecc2 = this.ev.lengthSq();
      this.ev.normalize();
      P = this.h.lengthSq() / this.planet.mu;
      semiMajor = P / (1 - ecc2);
      semiMinor = semiMajor * Math.sqrt(1 - ecc2);
      ellipse = new THREE.EllipseCurve(semiMajor * ecc, 0, semiMajor, semiMinor, 0, 2 * Math.PI, false);
      path = new THREE.CurvePath;
      path.add(ellipse);
      this.line.lookAt(this.h);
      lineX = X.clone();
      this.line.rotateOnAxis(Z, 2 * Math.PI - lineX.angleTo(this.ev));
      this.line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices;
      this.line.geometry.verticesNeedUpdate = true;
      this.craftCage.position.copy(r);
      this.apoapsisCage.position.copy(this.ev.clone().multiplyScalar(-P / (1 - ecc)));
      return this.periapsisCage.position.copy(this.ev.multiplyScalar(P / (1 + ecc)));
    };

    return Orbit;

  })(THREE.Object3D);

  window.Orbit = Orbit;

}).call(this);

(function() {
  var Planet, mksG,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  mksG = 6.67384e-11;

  Planet = (function(_super) {
    __extends(Planet, _super);

    function Planet(name, radius) {
      var mesh;
      Planet.__super__.constructor.apply(this, arguments);
      mesh = THREEx.Planets["create" + name](radius);
      this.radius = radius;
      this.mu = mksG * mesh.mksMass;
      this.LO = mesh.LO;
      this.planetId = mesh.planetId;
      this.add(mesh);
    }

    Planet.prototype.orbitalState = function(altitude) {
      var R, V;
      R = this.radius + altitude;
      V = Math.sqrt(this.mu / R) * 1.1;
      return {
        r: Y.clone().normalize().multiplyScalar(R).toArray(),
        v: X.clone().multiplyScalar(V).toArray(),
        mu: this.mu
      };
    };

    return Planet;

  })(THREE.Object3D);

  window.Planet = Planet;

}).call(this);

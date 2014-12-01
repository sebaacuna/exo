(function() {
  var SCALE;

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

  window.y2z = new THREE.Matrix4().makeRotationX(Math.PI / 2);

  window.TwoPI = Math.PI * 2;

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
      this.name = data.name;
      this.craftId = data.craftId;
      this.channel = "craft-" + this.craftId;
      size = M(30);
      this.mksMass = 1000;
      this.mesh = new THREE.Mesh;
      this.mesh.geometry = new THREE.CylinderGeometry(size * 0.25, size * 0.5, size);
      this.mesh.material = new THREE.MeshPhongMaterial({
        color: 0xefefef
      });
      this.mesh.matrixAutoUpdate = true;
      this.mesh.receiveShadow = true;
      this.add(this.mesh);
      this.mksPosition = new THREE.Vector3;
      this.mksVelocity = new THREE.Vector3;
      this.mksH = new THREE.Vector3;
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
      this.orbit.visible = false;
      this.updateState(data);
      this.mesh.lookAt(this.mksVelocity);
    }

    Craft.prototype.updateState = function(state) {
      var oldV, _ref, _ref1, _ref2;
      oldV = this.mksVelocity.clone();
      this.mksPosition.copy(state.r);
      this.mksVelocity.copy(state.v);
      this.mksH.crossVectors(this.mksPosition, this.mksVelocity);
      if (this.orbit.visible) {
        this.orbit.update(this.mksPosition, this.mksVelocity, this.mksH);
      }
      setGameVector(this.mksPosition, this.position);
      $acceleration.subVectors(oldV, this.mksVelocity);
      if ((_ref = this.velArrow) != null) {
        _ref.setDirection(this.mksVelocity.clone().normalize());
      }
      if ((_ref1 = this.accelArrow) != null) {
        _ref1.setLength($acceleration.length());
      }
      return (_ref2 = this.accelArrow) != null ? _ref2.setDirection($acceleration.normalize()) : void 0;
    };

    Craft.prototype.controller = function(keyboard, socket) {
      var sendThrust, setThrust, thrustEnd, thrustStart;
      socket.emit("control", this.craftId);
      sendThrust = (function(_this) {
        return function() {
          return socket.emit("" + _this.channel + "-thrust", _this.thrustVector().toArray());
        };
      })(this);
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
          if (throttle !== _this.throttle) {
            _this.throttle = throttle;
            return sendThrust();
          }
        };
      })(this);
      document.addEventListener("keydown", thrustStart, false);
      document.addEventListener("keyup", thrustEnd, false);
      return (function(_this) {
        return function() {
          var ROTATION;
          if (keyboard.pressed("shift")) {
            ROTATION = 0.001;
          } else {
            ROTATION = 0.01;
          }
          if (keyboard.pressed("w")) {
            _this.mesh.rotateOnAxis(_this.mesh.pitchAxis, ROTATION);
          }
          if (keyboard.pressed("s")) {
            _this.mesh.rotateOnAxis(_this.mesh.pitchAxis, -ROTATION);
          }
          if (keyboard.pressed("d")) {
            _this.mesh.rotateOnAxis(_this.mesh.yawAxis, -ROTATION);
          }
          if (keyboard.pressed("a")) {
            _this.mesh.rotateOnAxis(_this.mesh.yawAxis, ROTATION);
          }
          if (keyboard.pressed("q")) {
            _this.mesh.rotateOnAxis(_this.mesh.rollAxis, -ROTATION);
          }
          if (keyboard.pressed("e")) {
            return _this.mesh.rotateOnAxis(_this.mesh.rollAxis, ROTATION);
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
        F = 10000;
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
  var AdminController;

  AdminController = (function() {
    function AdminController($scope, $http) {
      var world;
      world = window.game.world;
      window.game.loop.push(function() {
        return $scope.$digest();
      });
      $scope.createOrbitingCraft = function() {
        return world.createOrbitingCraft(function(craft) {
          return $scope.$digest();
        });
      };
      $scope.controlCraft = function(craft) {
        var _ref;
        if ((_ref = $scope.controlledCraft) != null) {
          _ref.orbit.visible = false;
        }
        craft.orbit.line.material.color.setHex(0x0000ff);
        craft.orbit.visible = true;
        $scope.controlledCraft = craft;
        if ($scope.target === craft) {
          $scope.target = null;
        }
        world.controlCraft(craft);
        window.game.hud.setCraft(craft);
        return $scope.$digest();
      };
      $scope.targetCraft = function(craft) {
        craft.orbit.line.material.color.setHex(0x00ff00);
        craft.orbit.visible = true;
        $scope.target = craft;
        return $scope.$digest();
      };
      $scope.eccentricity = function() {
        var _ref;
        return Math.floor(((_ref = $scope.controlledCraft) != null ? _ref.orbit.curve.ecc : void 0) * 100) / 100;
      };
      world.getCrafts(function(crafts) {
        return $scope.$digest();
      });
      $scope.world = world;
    }

    return AdminController;

  })();

  window.exoApp = angular.module("exo", []);

  exoApp.controller("AdminController", AdminController);

}).call(this);

(function() {
  var Game;

  Game = (function() {
    function Game() {
      this.socket = io('http://localhost:8001');
      this.world = new World($(".viewport"), this.socket);
      this.hud = new HUD(this.world.renderer);
      this.loop = [];
      this.loop.push((function(_this) {
        return function() {
          return _this.world.craftController();
        };
      })(this));
      this.loop.push((function(_this) {
        return function() {
          return _this.world.cameraController();
        };
      })(this));
      this.socket.on("boi-" + this.world.boi.planetId + "-crafts", (function(_this) {
        return function(craftStates) {
          return _this.world.updateCrafts(craftStates);
        };
      })(this));
    }

    Game.prototype.start = function() {
      return $.get("/signin", (function(_this) {
        return function(sessionID) {
          _this.socket.emit("identify", sessionID);
          return _this.socket.on('ready', function(sessionID) {
            return _this.run();
          });
        };
      })(this));
    };

    Game.prototype.run = function() {
      var tick;
      tick = (function(_this) {
        return function() {
          var f, _i, _len, _ref;
          _this.world.render();
          _this.hud.render();
          _ref = _this.loop;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            f = _ref[_i];
            f();
          }
          return requestAnimationFrame(tick);
        };
      })(this);
      return tick();
    };

    return Game;

  })();

  window.Game = Game;

}).call(this);

(function() {
  var HUD;

  HUD = (function() {
    HUD.prototype.scale = 80;

    function HUD(renderer) {
      this.renderer = renderer;
      this.height = $(this.renderer.domElement).height() / this.scale;
      this.width = $(this.renderer.domElement).width() / this.scale;
      this.createScene();
      this.setup();
      this.createCamera();
    }

    HUD.prototype.createScene = function() {
      var dLight;
      this.scene = new THREE.Scene();
      this.scene.add(new THREE.AmbientLight(0x303030));
      dLight = new THREE.DirectionalLight(0xffffff, 0.5);
      dLight.position.copy(Y.clone());
      return this.scene.add(dLight);
    };

    HUD.prototype.setup = function() {
      this.navball = new Navball(1);
      return this.scene.add(this.navball);
    };

    HUD.prototype.createCamera = function() {
      var focus;
      this.camera = new THREE.OrthographicCamera(-this.width / 2, this.width / 2, this.height / 2, -this.height / 2, 0.05, 100);
      this.camera.position.copy(this.navball.up);
      this.camera.position.multiplyScalar(100);
      this.camera.position.y = this.height / 2 - (this.scale + 5) / this.scale;
      focus = this.camera.position.clone();
      focus.z = 0;
      return this.camera.lookAt(focus);
    };

    HUD.prototype.render = function() {
      this.navball.update();
      this.renderer.clearDepth();
      return this.renderer.render(this.scene, this.camera);
    };

    HUD.prototype.setCraft = function(craft) {
      this.craft = craft;
      return this.navball.setCraft(this.craft);
    };

    return HUD;

  })();

  window.HUD = HUD;

}).call(this);

(function() {
  var MARKER_SIZE, MARKER_THICKNESS, Marker, Navball, proGeometry, retroGeometry,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  MARKER_SIZE = 0.1;

  MARKER_THICKNESS = 0.02;

  proGeometry = new THREE.CylinderGeometry(MARKER_SIZE, MARKER_SIZE, MARKER_THICKNESS, 16);

  proGeometry.applyMatrix(y2z);

  retroGeometry = new THREE.TorusGeometry(MARKER_SIZE * 0.7, MARKER_THICKNESS, 6, 36);

  Marker = (function(_super) {
    __extends(Marker, _super);

    function Marker(color, geometry) {
      Marker.__super__.constructor.apply(this, arguments);
      this.geometry = geometry;
      this.material = new THREE.MeshLambertMaterial({
        color: color,
        emissive: color
      });
      this.material.emissive.offsetHSL(0, -0.25, 0);
    }

    Marker.prototype.update = function(vector) {
      this.position.copy(vector).normalize();
      return this.lookAt(ORIGIN);
    };

    return Marker;

  })(THREE.Mesh);

  Navball = (function(_super) {
    __extends(Navball, _super);

    function Navball(size) {
      this.size = size;
      Navball.__super__.constructor.apply(this, arguments);
      this.visible = false;
      this.useQuaternion = true;
      this.up.copy(Z);
      this.Q = new THREE.Quaternion;
      this.ball = new THREE.Mesh(new THREE.SphereGeometry(this.size, 24, 24), new THREE.MeshPhongMaterial({
        map: THREE.ImageUtils.loadTexture('images/navball.png'),
        bumpMap: THREE.ImageUtils.loadTexture('images/navball.png'),
        bumpScale: 0.01
      }));
      this.ball.geometry.applyMatrix(y2z);
      this.ball.up.copy(Z);
      this.ball.useQuaternion = true;
      this.heading = new THREE.Mesh(new THREE.TorusGeometry(MARKER_SIZE, MARKER_SIZE / 5, 6, 36), new THREE.MeshLambertMaterial({
        color: 'yellow'
      }));
      this.heading.up.copy(Z);
      this.markers = [];
      this.addMarker({
        color: 'green',
        vector: (function(_this) {
          return function() {
            return _this.craft.mksVelocity;
          };
        })(this)
      });
      this.addMarker({
        color: 'cyan',
        vector: (function(_this) {
          return function() {
            return _this.craft.mksPosition;
          };
        })(this)
      });
      this.addMarker({
        color: 'magenta',
        vector: (function(_this) {
          return function() {
            return _this.craft.mksH;
          };
        })(this)
      });
      this.add(this.heading);
      this.add(this.ball);
      this.ballMatrix = new THREE.Matrix4;
    }

    Navball.prototype.addMarker = function(params) {
      var pro, retro;
      if (params.retro === false) {
        pro = new Marker(params.color, proGeometry);
        this.markers.push((function(_this) {
          return function() {
            return pro.update(params.vector());
          };
        })(this));
        return this.add(pro);
      } else {
        pro = new Marker(params.color, proGeometry);
        retro = new Marker(params.color, retroGeometry);
        this.add(pro);
        this.add(retro);
        return this.markers.push((function(_this) {
          return function() {
            var v;
            v = params.vector().clone();
            pro.update(v);
            return retro.update(v.negate());
          };
        })(this));
      }
    };

    Navball.prototype.setCraft = function(craft) {
      this.craft = craft;
      return this.visible = true;
    };

    Navball.prototype.update = function() {
      var angle, m, pitchAxis, rollAxis, screenUp, x, y, yawAxis, _i, _len, _ref;
      if (!this.craft) {
        return;
      }
      _ref = this.markers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        m = _ref[_i];
        m();
      }
      this.ball.quaternion.setFromUnitVectors(this.craft.orbit.out, Z.clone().negate());
      x = X.clone().applyQuaternion(this.ball.quaternion);
      y = Y.clone().applyQuaternion(this.ball.quaternion);
      angle = Math.acos(x.dot(this.craft.orbit.north));
      if (x.dot(this.craft.orbit.west) < 0) {
        angle = TwoPI - angle;
      }
      this.Q.setFromAxisAngle(Z, -angle);
      this.ball.quaternion.multiply(this.Q);
      rollAxis = this.craft.mesh.rollAxis.clone().applyEuler(this.craft.mesh.rotation);
      yawAxis = this.craft.mesh.yawAxis.clone().applyEuler(this.craft.mesh.rotation);
      pitchAxis = this.craft.mesh.pitchAxis.clone().applyEuler(this.craft.mesh.rotation);
      this.quaternion.setFromUnitVectors(rollAxis, this.up);
      yawAxis.applyQuaternion(this.quaternion);
      pitchAxis.applyQuaternion(this.quaternion);
      screenUp = Y;
      angle = Math.acos(screenUp.dot(yawAxis));
      if (screenUp.dot(pitchAxis) < 0) {
        angle = TwoPI - angle;
      }
      this.Q.setFromAxisAngle(rollAxis, -angle);
      this.quaternion.multiply(this.Q);
      rollAxis.applyQuaternion(this.Q);
      this.heading.position.copy(rollAxis);
      return this.heading.lookAt(ORIGIN);
    };

    return Navball;

  })(THREE.Object3D);

  window.Navball = Navball;

}).call(this);

(function() {
  var ELLIPSE_POINTS, Orbit, OrbitCurve, uiCage,
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

  ELLIPSE_POINTS = 2000;

  OrbitCurve = (function(_super) {
    __extends(OrbitCurve, _super);

    function OrbitCurve(mu) {
      this.mu = mu;
      this.e = new THREE.Vector3;
      this.eY = new THREE.Vector3;
      this.eZ = new THREE.Vector3;
      this.q1 = new THREE.Quaternion;
      this.q2 = new THREE.Quaternion;
      this.q3 = new THREE.Quaternion;
      this.rotation = new THREE.Matrix4;
    }

    OrbitCurve.prototype.update = function(r, v, h) {
      var x, y, zAngle;
      this.r = r.clone().normalize();
      this.e.crossVectors(v, h.clone().normalize()).multiplyScalar(h.length() / this.mu);
      this.e.sub(this.r);
      this.ecc = this.e.length();
      if (this.ecc < 1e-10) {
        this.e.copy(X);
      }
      this.P = h.lengthSq() / this.mu;
      this.c = this.P / (1 + this.ecc);
      this.e.normalize();
      this.eZ = h.clone().normalize();
      this.eY.crossVectors(this.eZ, this.e);
      this.q1.setFromUnitVectors(Z, this.eZ);
      x = X.clone().applyQuaternion(this.q1);
      y = Y.clone().applyQuaternion(this.q1);
      zAngle = Math.acos(this.e.dot(x));
      if (this.e.dot(y) < 0) {
        zAngle = TwoPI - zAngle;
      }
      this.q2.setFromAxisAngle(Z, zAngle);
      this.q1.multiply(this.q2);
      this.f = Math.acos(this.r.dot(this.e));
      if (this.r.dot(this.eY) < 0) {
        this.f = TwoPI - this.f;
      }
      this.e.multiplyScalar(this.c);
      return this.rotation.makeRotationFromQuaternion(this.q1);
    };

    OrbitCurve.prototype.getPoint = function(t) {
      var X, Y, angle, cosT, length, point, sinT;
      angle = this.f + t * TwoPI;
      cosT = Math.cos(angle);
      sinT = Math.sin(angle);
      length = this.P / (1 + this.ecc * cosT);
      X = length * cosT;
      Y = length * sinT;
      point = new THREE.Vector3(X, Y, 0);
      return point;
    };

    return OrbitCurve;

  })(THREE.Curve);

  Orbit = (function(_super) {
    __extends(Orbit, _super);

    function Orbit(planet) {
      var geometry, i, material, _i;
      this.planet = planet;
      Orbit.__super__.constructor.apply(this, arguments);
      this.periapsisCage = uiCage(KM(10), 0x00ff00);
      this.add(this.periapsisCage);
      this.apoapsisCage = uiCage(KM(10), 0x0000ff);
      this.add(this.apoapsisCage);
      material = new THREE.LineBasicMaterial({
        linewidth: 1,
        color: 0x00ffff
      });
      geometry = new THREE.Geometry;
      geometry.dynamic = true;
      for (i = _i = 0; 0 <= ELLIPSE_POINTS ? _i <= ELLIPSE_POINTS : _i >= ELLIPSE_POINTS; i = 0 <= ELLIPSE_POINTS ? ++_i : --_i) {
        geometry.vertices.push(new THREE.Vector3);
      }
      this.line = new THREE.Line(geometry, material);
      this.line.matrixAutoUpdate = false;
      this.add(this.line);
      this.planet.add(this);
      this.curve = new OrbitCurve(this.planet.mu);
      this.out = new THREE.Vector3;
      this.north = new THREE.Vector3;
      this.west = new THREE.Vector3;
    }

    Orbit.prototype.update = function(r, v, h) {
      var path;
      this.out.copy(r.clone().normalize());
      this.west.crossVectors(this.out, Z).normalize();
      this.north.crossVectors(this.west, this.out);
      this.curve.update(r, v, h);
      path = new THREE.CurvePath;
      path.add(this.curve);
      this.line.geometry.vertices = path.createPointsGeometry(ELLIPSE_POINTS).vertices;
      this.line.geometry.verticesNeedUpdate = true;
      this.line.matrix = this.curve.rotation;
      return this.periapsisCage.position.copy(this.curve.e);
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
      mesh.castShadow = true;
      this.radius = radius;
      this.mu = mksG * mesh.mksMass;
      this.LO = mesh.LO;
      this.planetId = mesh.planetId;
      this.add(mesh);
    }

    Planet.prototype.orbitalState = function(altitude) {
      var R, V;
      R = this.radius + altitude;
      V = Math.sqrt(this.mu / R);
      return {
        r: Y.clone().normalize().multiplyScalar(-R).toArray(),
        v: X.clone().multiplyScalar(V).toArray(),
        mu: this.mu
      };
    };

    return Planet;

  })(THREE.Object3D);

  window.Planet = Planet;

}).call(this);

(function() {
  var World;

  World = (function() {
    function World(viewport, socket) {
      this.viewport = viewport;
      this.socket = socket;
      this.crafts = {};
      this.boi = new Planet('Earth', KM(6378));
      this.createScene();
      this.createCamera();
      this.createRenderer();
      this.keyboard = new THREEx.KeyboardState;
      this.craftController = function() {};
      this.cameraController = function() {};
      this.focusObject(this.boi);
      this.scene.add(this.boi);
    }

    World.prototype.createScene = function() {
      var dLight;
      this.scene = new THREE.Scene();
      this.scene.add(new THREE.AmbientLight(0x333333));
      dLight = new THREE.DirectionalLight(0xcccccc, 1);
      dLight.castShadow = true;
      dLight.shadowCameraRight = dLight.shadowCameraTop = KM(20000);
      dLight.shadowCameraLeft = dLight.shadowCameraBottom = -KM(20000);
      dLight.shadowCameraNear = 0;
      dLight.shadowCameraFar = KM(40000);
      dLight.shadowDarkness = 1;
      dLight.position.set(KM(20000), 0, 0);
      return this.scene.add(dLight);
    };

    World.prototype.createRenderer = function() {
      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        logarithmicDepthBuffer: true
      });
      this.renderer.setSize(this.viewport.width(), this.viewport.height());
      this.renderer.shadowMapEnabled = true;
      this.renderer.shadowMapSoft = false;
      this.renderer.autoClear = false;
      return this.viewport.append(this.renderer.domElement);
    };

    World.prototype.render = function() {
      this.renderer.clear();
      return this.renderer.render(this.scene, this.camera);
    };

    World.prototype.createCamera = function() {
      var $viewport;
      this.camera = new THREE.PerspectiveCamera(90, this.viewport.width() / this.viewport.height(), M(1), KM(100000));
      this.camera.up.copy(Z);
      this.camera.position.z = KM(10000);
      this.cameraControls = new THREE.OrbitControls(this.camera);
      this.cameraControls.zoomSpeed = 2;
      this.cameraControls.addEventListener('change', (function(_this) {
        return function() {
          return _this.render();
        };
      })(this));
      $viewport = this.viewport;
      return this.camera.setFrame = function(frameSize) {
        var ratio;
        ratio = $viewport.width() / $viewport.height();
        this.left = -frameSize * ratio;
        this.right = frameSize * ratio;
        this.top = frameSize * ratio;
        this.bottom = -frameSize * ratio;
        return this.updateProjectionMatrix();
      };
    };

    World.prototype.updateCrafts = function(craftStates) {
      var id, state, _ref, _results;
      _results = [];
      for (id in craftStates) {
        state = craftStates[id];
        _results.push((_ref = this.crafts[id]) != null ? _ref.updateState(state) : void 0);
      }
      return _results;
    };

    World.prototype.createCraft = function(state, callback) {
      state.name = prompt("Craft name");
      return $.ajax({
        type: "PUT",
        url: "/crafts",
        data: JSON.stringify(state),
        processData: false,
        contentType: 'application/json; charset=utf-8',
        statusCode: {
          201: (function(_this) {
            return function(data) {
              var craft;
              craft = new Craft(data, _this.boi);
              _this.addCraft(craft);
              return callback(craft);
            };
          })(this),
          403: function(data) {
            return alert(data);
          }
        }
      });
    };

    World.prototype.createOrbitingCraft = function(callback) {
      return this.createCraft(this.boi.orbitalState(this.boi.LO), callback);
    };

    World.prototype.getCrafts = function(callback) {
      return $.get("/crafts", (function(_this) {
        return function(crafts, textStatus, $xhr) {
          var craftData, craftId;
          for (craftId in crafts) {
            craftData = crafts[craftId];
            _this.addCraft(new Craft(craftData, _this.boi));
          }
          return callback(_this.crafts);
        };
      })(this));
    };

    World.prototype.controlCraft = function(craft) {
      this.craftController = craft.controller(this.keyboard, this.socket);
      this.focusObject(craft);
      return craft.orbit.visible = true;
    };

    World.prototype.addCraft = function(craft) {
      var align;
      this.crafts[craft.craftId] = craft;
      align = new THREE.Matrix4;
      align.lookAt(craft.mesh.rollAxis, craft.mksVelocity.clone().normalize(), craft.mesh.yawAxis);
      craft.mesh.applyMatrix(align);
      return this.scene.add(craft);
    };

    World.prototype.focusObject = function(object) {
      var $pitchAxis, $yawAxis, C;
      object.add(this.camera);
      this.cameraControls.target.copy(ORIGIN);
      this.cameraControls.update();
      return;
      C = this.camera;
      object.add(C);
      return;
      $pitchAxis = X.clone();
      $yawAxis = new THREE.Vector3;
      $yawAxis.copy(object.up).normalize();
      return this.cameraController = (function(_this) {
        return function() {
          var K;
          K = _this.keyboard;
          if (K.pressed("shift")) {
            if (K.pressed("shift+up")) {
              C.position.z = Math.max(C.position.z / 2.0, M(10));
            }
            if (K.pressed("shift+down")) {
              C.position.z = Math.min(C.position.z * 2, KM(100000));
            }
            if (C.setFrame) {
              return C.setFrame(C.position.z);
            }
          } else {
            if (K.pressed("left")) {
              C.target.rotateOnAxis($yawAxis, -0.05);
            }
            if (K.pressed("right")) {
              C.target.rotateOnAxis($yawAxis, +0.05);
            }
            if (K.pressed("up")) {
              C.target.rotateOnAxis($pitchAxis, -0.05);
            }
            if (K.pressed("down")) {
              return C.target.rotateOnAxis($pitchAxis, +0.05);
            }
          }
        };
      })(this);
    };

    return World;

  })();

  window.World = World;

}).call(this);

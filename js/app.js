(function() {
  var SCALE, animate, camera, clock, gameLoop, keyboard, render, renderer;

  SCALE = 1;

  window.KM = function(kms) {
    return M(kms) * 1000;
  };

  window.M = function(mts) {
    return mts * SCALE;
  };

  window.mksVector = function(gameVector) {
    var vector;
    vector = gameVector.clone().multiplyScalar(1.0 / SCALE);
    vector.setGameVector = function(v) {
      return v.copy(this).multiplyScalar(SCALE);
    };
    return vector;
  };

  window.LEO = KM(160);

  window.scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, M(1), KM(10000000));

  renderer = new THREE.WebGLRenderer({
    antialias: true,
    logarithmicDepthBuffer: true
  });

  renderer.setSize(window.innerWidth, window.innerHeight);

  renderer.shadowMapEnabled = true;

  keyboard = new THREEx.KeyboardState;

  clock = new THREE.Clock(false);

  scene.add(new THREE.AmbientLight(0x888888));

  gameLoop = [];

  window.NULLVECTOR = new THREE.Vector3;

  window.X = new THREE.Vector3(1, 0, 0);

  window.Y = new THREE.Vector3(0, 1, 0);

  window.Z = new THREE.Vector3(0, 0, 1);

  window.socket = io('http://localhost:8002');

  socket.on('comm', function(data) {
    console.log(data);
    return socket.emit('comm', 'ACK');
  });

  window.setup = function() {
    var planet, ship;
    planet = Planet.create('Earth', KM(6378));
    scene.add(planet);
    ship = new Ship(M(10));
    scene.add(ship);
    ship.orbit(planet, 4 * LEO);
    ship.captureCamera(camera);
    gameLoop.push(ship.control(keyboard));
    gameLoop.push(ship.simulate());
    gameLoop.push(ship.track(camera));
    gameLoop.push(camera.control(keyboard, renderer));
    scene.add(new THREE.ArrowHelper(Z, NULLVECTOR, KM(100000), 0xffffff));
    return window.ship = ship;
  };

  window.run = function() {
    render();
    return animate();
  };

  render = function() {
    return renderer.render(scene, camera);
  };

  animate = function() {
    var f, _i, _len;
    for (_i = 0, _len = gameLoop.length; _i < _len; _i++) {
      f = gameLoop[_i];
      f();
    }
    return requestAnimationFrame(run);
  };

  document.body.appendChild(renderer.domElement);

}).call(this);

(function() {
  var Planet, Ship, TIMESCALE, TWOPI, mksG,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  mksG = 6.67384e-11;

  TWOPI = Math.PI + Math.PI;

  TIMESCALE = 5;

  Planet = {
    create: function(name, radius) {
      var mesh;
      mesh = THREEx.Planets["create" + name](radius);
      mesh.radius = radius;
      mesh.mu = mksG * mesh.mksMass;
      return mesh;
    }
  };

  Ship = (function(_super) {
    __extends(Ship, _super);

    function Ship(size) {
      Ship.__super__.constructor.apply(this, arguments);
      this.mesh = new THREE.Mesh;
      this.mesh.geometry = new THREE.CylinderGeometry(size * 0.25, size * 0.5, size);
      this.mesh.material = new THREE.MeshBasicMaterial({
        color: 0x006600
      });
      this.mesh.matrixAutoUpdate = true;
      this.add(this.mesh);
      this.mesh.rollAxis = this.mesh.up;
      this.mesh.yawAxis = new THREE.Vector3(1, 0, 0);
      if (0 === this.mesh.yawAxis.angleTo(this.mesh.rollAxis)) {
        this.mesh.yawAxis = new THREE.Vector3(0, 0, 1);
      }
      this.mesh.pitchAxis = (new THREE.Vector3).crossVectors(this.mesh.yawAxis, this.mesh.rollAxis);
      this.cameraTarget = new THREE.Object3D;
      this.add(this.cameraTarget);
      this.velArrow = this.arrow(new THREE.Vector3(KM(1000), 0, 0));
      this.add(this.velArrow);
      this.accelArrow = this.arrow(X);
      this.add(this.accelArrow);
      this.thrustArrow = this.arrow(this.mesh.rollAxis, 0xffffff);
      this.add(this.thrustArrow);
      this.thrust = 0;
      this.navCage = new THREE.Mesh;
      this.navCage.geometry = new THREE.BoxGeometry(KM(10), KM(10), KM(10));
      this.navCage.material = new THREE.MeshBasicMaterial({
        color: 0xff0000,
        wireframe: true
      });
      this.add(this.navCage);
      this.periapsisCage = new THREE.Mesh;
      this.periapsisCage.geometry = new THREE.BoxGeometry(KM(100), KM(100), KM(100));
      this.periapsisCage.material = new THREE.MeshBasicMaterial({
        color: 0x00ff00
      });
      this.apoapsisCage = new THREE.Mesh;
      this.apoapsisCage.geometry = new THREE.BoxGeometry(KM(100), KM(100), KM(100));
      this.apoapsisCage.material = new THREE.MeshBasicMaterial({
        color: 0x0000ff
      });
      this.mesh.add(new THREE.AxisHelper(KM(1000)));
      this.consoleElems = {};
    }

    Ship.prototype.console = function(key, value) {
      if (!this.consoleElems[key]) {
        this.consoleElems[key] = document.getElementById("console-" + key) || -1;
      }
      if (this.consoleElems[key] !== -1) {
        return this.consoleElems[key].innerHTML = value;
      }
    };

    Ship.prototype.orbit = function(boi, gameAltitude) {
      var alignAxis, mksDistance, mksOrbitalSpeed;
      this.boi = boi;
      this.mksMass = 1000;
      this.position.x = this.boi.radius + gameAltitude;
      mksDistance = mksVector(this.position).length();
      mksOrbitalSpeed = Math.sqrt(this.boi.mu / mksDistance);
      this.mksVelocity = new THREE.Vector3(0, 0, mksOrbitalSpeed * 1.2);
      this.mksPosition = mksVector(this.position);
      this.mksAngMom = new THREE.Vector3;
      this.referencePosition = this.position.clone();
      alignAxis = new THREE.Vector3;
      alignAxis.crossVectors(this.mesh.up, this.mksVelocity);
      alignAxis.normalize();
      this.mesh.rotateOnAxis(alignAxis, this.mesh.up.angleTo(this.mksVelocity));
      this.eccArrow = new THREE.ArrowHelper(Z, NULLVECTOR, 0, 0x00ff00);
      this.boi.add(this.periapsisCage);
      this.boi.add(this.apoapsisCage);
      return this.boi.add(this.eccArrow);
    };

    Ship.prototype.updateEllipse = function() {
      var P, ecc, ecc2, eccVector, ellipse, geometry, i, inclineAngle, inclineAxis, normal, path, r, semiMajor, semiMinor, v, _i, _len, _ref;
      r = this.mksPosition.clone().normalize();
      eccVector = this.mksVelocity.clone().cross(this.mksAngMom).multiplyScalar(1 / this.boi.mu);
      eccVector.sub(r);
      ecc = eccVector.length();
      ecc2 = eccVector.lengthSq();
      eccVector.normalize();
      P = this.mksAngMom.lengthSq() / this.boi.mu;
      this.apoapsisCage.position.copy(eccVector.clone().multiplyScalar(-P / (1 - ecc)));
      this.periapsisCage.position.copy(eccVector.multiplyScalar(P / (1 + ecc)));
      this.eccArrow.setDirection(eccVector);
      this.eccArrow.setLength(eccVector.length());
      semiMajor = P / (1 - ecc2);
      semiMinor = semiMajor * Math.sqrt(1 - ecc2);
      this.console('eccentricity', "" + (Math.floor(ecc * 100)) + " " + (Math.floor(semiMajor)) + " " + (Math.floor(semiMinor)) + " " + (Math.floor(P / (1 + ecc))));
      ellipse = new THREE.EllipseCurve(eccVector.length() - semiMajor, 0, semiMajor, semiMinor, 0, 2 * Math.PI, false);
      path = new THREE.CurvePath;
      path.add(ellipse);
      geometry = path.createPointsGeometry(2000);
      if (!this.orbitLine) {
        this.orbitLine = new THREE.Line(geometry, new THREE.LineBasicMaterial({
          linewidth: 2,
          color: 0x0000ff,
          depthTest: true
        }));
        this.orbitLine.up = new THREE.Vector3(1, 0, 0);
        geometry.dynamic = true;
        this.parent.add(this.orbitLine);
        this.orbitLine.add(new THREE.ArrowHelper(this.orbitLine.up, NULLVECTOR, KM(10000), 0xff00ff));
      } else {
        this.orbitLine.material = new THREE.LineBasicMaterial({
          color: 0x00ff00
        });
        _ref = geometry.vertices;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          v = _ref[i];
          this.orbitLine.geometry.vertices[i].x = v.x;
          this.orbitLine.geometry.vertices[i].y = v.y;
        }
        this.orbitLine.geometry.verticesNeedUpdate = true;
      }
      normal = this.orbitLine.localToWorld(Z.clone());
      inclineAngle = normal.angleTo(this.mksAngMom);
      if (inclineAngle !== 0) {
        inclineAxis = new THREE.Vector3;
        inclineAxis.crossVectors(normal, this.mksAngMom.clone().normalize());
        inclineAxis.normalize();
        this.orbitLine.rotateOnAxis(inclineAxis, inclineAngle);
      }
      return this.orbitLine.rotateOnAxis(Z, this.orbitLine.up.angleTo(this.orbitLine.worldToLocal(eccVector)));
    };

    Ship.prototype.captureCamera = function(camera) {
      this.camera = camera;
      this.cameraTarget.add(camera);
      camera.position.z = KM(2000);
      camera.target = this.cameraTarget;
      camera.target.rotation.x = -Math.PI / 2;
      return camera.control = function(keyboard, renderer) {
        return (function(_this) {
          return function() {
            if (keyboard.pressed("shift")) {
              if (keyboard.pressed("shift+up")) {
                _this.position.z = Math.max(_this.position.z / 2.0, M(10));
              }
              if (keyboard.pressed("shift+down")) {
                return _this.position.z = Math.min(_this.position.z * 2, KM(100000));
              }
            } else {
              if (keyboard.pressed("left")) {
                _this.target.rotation.y -= 0.05;
              }
              if (keyboard.pressed("right")) {
                _this.target.rotation.y += 0.05;
              }
              if (keyboard.pressed("up")) {
                _this.target.rotation.x -= 0.05;
              }
              if (keyboard.pressed("down")) {
                return _this.target.rotation.x += 0.05;
              }
            }
          };
        })(this);
      };
    };

    Ship.prototype.simulate = function() {
      var clock;
      clock = new THREE.Clock;
      clock.start();
      return (function(_this) {
        return function() {
          var count, dt, oldPosition, oldVel, simulateSeconds, simulateSteps, _ref, _ref1, _ref2;
          if (!_this.a) {
            _this.a = function(x, v, dt) {
              var magnitude, r;
              r = x.clone().normalize().negate();
              magnitude = mksG * _this.boi.mksMass / (x.length() * x.length());
              r.multiplyScalar(magnitude);
              return r.add(_this.thrustCalc(x, v, dt));
            };
          }
          count = 0;
          oldPosition = _this.mksPosition.clone();
          oldVel = _this.mksVelocity.clone();
          dt = 0.00001;
          simulateSeconds = clock.getDelta();
          simulateSteps = TIMESCALE * Math.floor(simulateSeconds / dt);
          while (count < simulateSteps) {
            THREEx.rk4(_this.mksPosition, _this.mksVelocity, _this.a, dt);
            ++count;
          }
          _this.mksPosition.setGameVector(_this.position);
          oldVel.sub(_this.mksVelocity);
          if ((_ref = _this.velArrow) != null) {
            _ref.setDirection(_this.mksVelocity.clone().normalize());
          }
          _this.console('velocity', Math.floor(_this.mksVelocity.length()));
          _this.console('acceleration', Math.floor(oldVel.length() * 1000) / 10.0);
          if ((_ref1 = _this.accelArrow) != null) {
            _ref1.setLength(oldVel.length() * 100);
          }
          if ((_ref2 = _this.accelArrow) != null) {
            _ref2.setDirection(oldVel.negate().normalize());
          }
          _this.mksAngMom.crossVectors(_this.mksPosition, _this.mksVelocity);
          _this.orbitalEnergy = 0.5 * _this.mksVelocity.lengthSq();
          _this.orbitalEnergy -= _this.boi.mu / _this.mksPosition.length();
          _this.console('orbital-energy', Math.floor(_this.orbitalEnergy * 10000) / 10000);
          _this.console('angular-moment', Math.floor(_this.mksAngMom.length() * 10000) / 10000);
          return _this.console('r', _this.mksPosition.length());
        };
      })(this);
    };

    Ship.prototype.control = function(keyboard) {
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
            _this.mesh.rotateOnAxis(_this.mesh.rollAxis, -0.05);
          }
          if (keyboard.pressed("space")) {
            _this.thrust = 1;
            return _this.thrustArrow.visible = true;
          } else {
            _this.thrust = 0;
            return _this.thrustArrow.visible = false;
          }
        };
      })(this);
    };

    Ship.prototype.track = function(camera) {
      return (function(_this) {
        return function() {
          var far, localPos, _ref;
          localPos = camera.position.clone();
          camera.localToWorld(localPos);
          far = localPos.distanceTo(_this.position) > KM(10);
          if ((_ref = _this.orbitLine) != null) {
            _ref.visible = far;
          }
          _this.navCage.visible = far;
          _this.updateEllipse();
          if (far) {
            return _this.velArrow.setLength(_this.mksVelocity.length());
          } else {
            return _this.velArrow.setLength(_this.mksVelocity.length());
          }
        };
      })(this);
    };

    Ship.prototype.arrow = function(vector, color) {
      var direction;
      if (color == null) {
        color = 0xff0000;
      }
      direction = vector.clone().normalize();
      return new THREE.ArrowHelper(direction, this.position, vector.length(), color);
    };

    Ship.prototype.thrustCalc = function(x, v, dt) {
      var F, thrustVector;
      if (this.thrust) {
        F = 200000;
        thrustVector = this.mesh.rollAxis.clone();
        thrustVector.normalize();
        thrustVector.applyMatrix4(this.mesh.matrix);
        this.thrustArrow.setDirection(thrustVector);
        this.thrustArrow.setLength(KM(1));
        thrustVector.multiplyScalar(F / this.mksMass);
        return thrustVector;
      } else {
        return NULLVECTOR;
      }
    };

    return Ship;

  })(THREE.Object3D);

  window.Planet = Planet;

  window.Ship = Ship;

}).call(this);

(function() {
  window.THREEx = window.THREEx || {};

  window.THREEx.rk4 = function(x, v, a, dt) {
    var a1, a2, a3, a4, dt2, dt6, v1, v2, v3, v4, x1, x2, x3, x4;
    dt2 = dt / 2.0;
    dt6 = dt / 6.0;
    x1 = x.clone();
    v1 = v.clone();
    a1 = a(x1, v1, 0);
    x2 = v1.clone().multiplyScalar(dt2).add(x);
    v2 = a1.clone().multiplyScalar(dt2).add(v);
    a2 = a(x2, v2, dt2);
    x3 = v2.clone().multiplyScalar(dt2).add(x);
    v3 = a2.clone().multiplyScalar(dt2).add(v);
    a3 = a(x3, v3, dt2);
    x4 = v3.clone().multiplyScalar(dt).add(x);
    v4 = a3.clone().multiplyScalar(dt).add(v);
    a4 = a(x4, v4, dt);
    v2.multiplyScalar(2.0);
    v3.multiplyScalar(2.0);
    x.add(v1.add(v2).add(v3).add(v4).multiplyScalar(dt6));
    a2.multiplyScalar(2.0);
    a3.multiplyScalar(2.0);
    return v.add(a1.add(a2).add(a3).add(a4).multiplyScalar(dt6));
  };

}).call(this);

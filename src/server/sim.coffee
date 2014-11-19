THREE = require 'three'
TIMESCALE = 25

class Simulation
  constructor: ()->
    @crafts = {}
    @clock = new THREE.Clock

  run: ()->
    console.log 'Simulation running'
    dt = 0.0001*TIMESCALE
    simPeriod = 50
    runLoop = ()=>
      simSeconds = Math.min simPeriod, @clock.getDelta()
      simSteps = TIMESCALE*Math.floor simSeconds/dt
      count = 0
      while count < simSteps
        for id, craft of @crafts
          craft.simulate dt
        ++count
      setTimeout runLoop, simPeriod
    @clock.start()
    runLoop()

rk4 = (x, v, a, dt) ->
    # Returns final (position, velocity) array after time dt has passed.
    #        x: initial position
    #        v: initial velocity
    #        a: acceleration function a(x,v,dt) (must be callable)
    #        dt: timestep

    dt2 = dt/2.0 # dt/2
    dt6 = dt/6.0  # dt6

    x1 = x.clone()
    v1 = v.clone()
    a1 = a(x1, v1, 0)

    # x2 = x + 0.5*v1*dt;
    x2 = v1.clone().multiplyScalar(dt2).add(x)
    # v2 = v + 0.5*a1*dt;
    v2 = a1.clone().multiplyScalar(dt2).add(v)
    a2 = a(x2, v2, dt2)

    # x3 = x + 0.5*v2*dt;
    x3 = v2.clone().multiplyScalar(dt2).add(x)
    # v3 = v + 0.5*a2*dt;
    v3 = a2.clone().multiplyScalar(dt2).add(v)
    a3 = a(x3, v3, dt2);

    # x4 = x + v3*dt;
    x4 = v3.clone().multiplyScalar(dt).add(x)
    # v4 = v + a3*dt;
    v4 = a3.clone().multiplyScalar(dt).add(v)
    a4 = a(x4, v4, dt);


    # xf = x + (dt/6.0)*(v1 + 2*v2 + 2*v3 + v4);
    v2.multiplyScalar(2.0)
    v3.multiplyScalar(2.0)
    x.add(v1.add(v2).add(v3).add(v4).multiplyScalar(dt6))

    # vf = v + (dt/6.0)*(a1 + 2*a2 + 2*a3 + a4);
    a2.multiplyScalar(2.0)
    a3.multiplyScalar(2.0)
    v.add(a1.add(a2).add(a3).add(a4).multiplyScalar(dt6))

rk4b = (r, v, a, dt) ->
    # Returns final (position, velocity) array after time dt has passed.
    #        x: initial position
    #        v: initial velocity
    #        a: acceleration function a(x,v,dt) (must be callable)
    #        dt: timestep

    dt2 = dt/2.0 # dt/2
    dt6 = dt/6.0  # dt6

    kr1 = v
    kv1 = a(r)

    r1 = kr1.clone().multiplyScalar(dt2).add(r)
    kr2 = v.clone().multiply(kr1).multiplyScalar(dt2)
    kv2 = a(r1)

    r2 = kr2.clone().multiplyScalar(dt2).add(r)
    kr3 = v.clone().multiply(kr2).multiplyScalar(dt2)
    kv3 = a(r2)

    r3 = kr3.clone().multiplyScalar(dt).add(r)
    kr4 = v.clone().multiply(kr3).multiplyScalar(dt)
    kv4 = a(r3);

    dv = kv1.add(kv2.add(kv3).multiplyScalar(2)).add(kv4)
    dv.multiplyScalar dt6
    v.add dv

    dr = kr1.add(kr2.add(kr3).multiplyScalar(2)).add(kr4)
    dr.multiplyScalar dt6
    r.add dr


module.exports.Simulation = Simulation
module.exports.rk4 = rk4
# module.exports.rk4 = rk4b
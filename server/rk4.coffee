module.exports = 
  rk4: (x, v, a, dt) ->
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

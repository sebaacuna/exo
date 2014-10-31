window.THREEx  = window.THREEx or {}

window.THREEx.rk4 = (x, v, a, dt) ->
  # Returns final (position, velocity) array after time dt has passed.
  #        x: initial position
  #        v: initial velocity
  #        a: acceleration function a(x,v,dt) (must be callable)
  #        dt: timestep
  x1 = x;
  v1 = v;
  a1 = a(x1, v1, 0);

  x2 = x + 0.5*v1*dt;
  v2 = v + 0.5*a1*dt;
  a2 = a(x2, v2, dt/2);

  x3 = x + 0.5*v2*dt;
  v3 = v + 0.5*a2*dt;
  a3 = a(x3, v3, dt/2);

  x4 = x + v3*dt;
  v4 = v + a3*dt;
  a4 = a(x4, v4, dt);

  xf = x + (dt/6)*(v1 + 2*v2 + 2*v3 + v4);
  vf = v + (dt/6)*(a1 + 2*a2 + 2*a3 + a4);

  return [xf, vf]
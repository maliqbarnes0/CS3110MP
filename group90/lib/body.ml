type b = {
  mass : float;
  pos : Vec3.v;
  vel : Vec3.v;
  radius : float;
}

let make ~mass:m ~pos:p ~vel:v ~radius:r =
  { mass = m; pos = p; vel = v; radius = r }

let mass b = b.mass
let pos b = b.pos
let vel b = b.vel
let radius b = b.radius
let with_pos p b = { b with pos = p }
let with_vel v b = { b with vel = v }

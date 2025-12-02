type b = {
  density : float;
  pos : Vec3.v;
  vel : Vec3.v;
  radius : float;
  mass : float;
}

let make ~density:d ~pos:p ~vel:v ~radius:r =
  { density = d; pos = p; vel = v; radius = r ; mass = (4.0 /. 3.0) *. Float.pi *. r ** 3.0 *. d }

let mass b = b.mass
let pos b = b.pos
let vel b = b.vel
let radius b = b.radius
let density b = b.density
let with_pos p b = { b with pos = p }
let with_vel v b = { b with vel = v }

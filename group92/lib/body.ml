type b = {
    mass : float;
    pos  : Vec3.v;
    vel  : Vec3.v;
}

let make ~mass:m ~pos:p ~vel:v = {
  mass = m;
  pos = p;
  vel = v;
}

let mass b = b.mass 
let pos b = b.pos
let vel b = b.vel

let with_pos p b = {b with pos = p}
let with_vel v b = {b with vel = v}


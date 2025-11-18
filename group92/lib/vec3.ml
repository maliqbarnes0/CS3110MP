
type v = {
  x : float;
  y : float;
  z : float;
}

let make x y z = {x; y; z}

let zer0 = {x = 0.; y = 0.; z = 0.}

let x v = v.x
let y v = v.y
let z v = v.z

let ( + ) v1 v2 = {
  x = v1.x +. v2.x;
  y = v1.y +. v2.y;
  z = v1.z +. v2.z;
}
let ( - ) v1 v2 = {
  x = v1.x -. v2.x;
  y = v1.y -. v2.y;
  z = v1.z -. v2.z;
}
(* we are defining *~ as scaler multiplication*)
let ( *~ ) s v = 
{
  x = s *. v.x;
  y = s *. v.y;
  z = s *. v.z;
}

let dot v1 v2 = v1.x *. v2.x +. v1.y *. v2.y +. v1.z *. v2.z

let norm v = Float.sqrt (dot v v)

let normalize v =
  let n = norm v in
  if n = 0. then zer0 else (1. /. n) *~ v
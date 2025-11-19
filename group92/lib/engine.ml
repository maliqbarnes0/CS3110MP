(* Scaled gravitational constant for pixel-based simulation *)
let g = 1000.

type w = Body.b list


let gravitational_force b1 ~by:b2 =
  let p1 = Body.pos b1 in
  let p2 = Body.pos b2 in
  let dx = Vec3.x p2 -. Vec3.x p1 in
  let dy = Vec3.y p2 -. Vec3.y p1 in
  let dz = Vec3.z p2 -. Vec3.z p1 in
  let r2 = dx *. dx +. dy *. dy +. dz *. dz in
  if r2 = 0. then Vec3.zer0
  else
    let magnitude = g *. Body.mass b1 *. Body.mass b2 /. r2 in
    let dir = Vec3.make dx dy dz |> Vec3.normalize in
    Vec3.(magnitude *~ dir)

let net_force_on b1 world = 
  List.fold_left (fun acc b2 -> 
    if b1 == b2 then acc 
    else 
    Vec3.(acc + gravitational_force b1 ~by:b2)) Vec3.zer0 world


let step ~dt world = 
  List.map (fun b ->
    let f = net_force_on b world in
    let a = Vec3.(1. /. Body.mass b *~ f) in
    let new_vel = Vec3.(Body.vel b + (dt *~ a)) in
    let new_pos = Vec3.(Body.pos b + (dt *~ new_vel)) in
    Body.(b |> with_vel new_vel |> with_pos new_pos)
  ) world
(** Physics system module - handles all physics-related calculations.

    This module provides functions for:
    - Physics updates with substeps
    - Collision detection
    - Trail updates *)

(** Fixed physics timestep for accuracy *)
let fixed_dt = 0.1

(** Update physics with substeps based on time scale. Returns (new_world,
    all_collisions) *)
let update_physics ~time_scale ~world =
  let num_steps = max 1 (int_of_float (Float.ceil time_scale)) in
  let substep_dt = time_scale *. fixed_dt /. float_of_int num_steps in

  let rec do_steps w collisions_acc n =
    if n = 0 then (w, collisions_acc)
    else
      let new_w, step_collisions =
        Engine.step_with_collisions ~dt:substep_dt w
      in
      do_steps new_w (step_collisions @ collisions_acc) (n - 1)
  in
  do_steps world [] num_steps

(** Calculate collision point between two bodies - point on surface where they
    touch *)
let calc_collision_point b1 b2 =
  let pos1 = Body.pos b1 in
  let pos2 = Body.pos b2 in
  let r1 = Body.radius b1 in

  let open Vec3 in
  (* Vector from body1 to body2 *)
  let direction = pos2 - pos1 in
  let distance = norm direction in

  if distance < 0.0001 then
    (* Bodies are at same position, use midpoint *)
    0.5 *~ (pos1 + pos2)
  else
    (* Calculate contact point: move from pos1 toward pos2 by radius of body1 *)
    let normalized_dir = normalize direction in
    let contact_distance = r1 in
    (* Distance from center of body1 to contact point *)
    pos1 + (contact_distance *~ normalized_dir)

(** Update trails with new positions. Returns (new_trails, collision_pairs) *)
let update_trails trails world all_collisions =
  (* Add current positions to trails *)
  let new_trails =
    List.mapi
      (fun i trail ->
        if i < List.length world then
          let body = List.nth world i in
          let pos = Body.pos body in
          let updated_trail = pos :: trail in
          (* Keep only last 100 positions for performance *)
          if List.length updated_trail > 100 then
            List.filteri (fun j _ -> j < 100) updated_trail
          else updated_trail
        else trail)
      trails
  in

  (* Extract collision pairs *)
  let collision_pairs = all_collisions in

  (new_trails, collision_pairs)

(** Check for active collisions in current world state *)
let find_collisions world = Engine.find_collisions world

(** Check if any collisions are occurring *)
let is_colliding world = List.length (find_collisions world) > 0

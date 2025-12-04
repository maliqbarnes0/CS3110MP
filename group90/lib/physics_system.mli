(** Physics system module - handles all physics-related calculations.

    This module provides functions for:
    - Physics updates with substeps for accuracy
    - Collision detection
    - Trail position tracking *)

(** [update_physics ~time_scale ~world] performs physics simulation on [world]
    with the given [time_scale]. Higher time scales use more substeps for
    accuracy. Returns [(new_world, all_collisions)] where [new_world] is the
    updated list of bodies and [all_collisions] is a list of body pairs that
    collided during this update. *)
val update_physics :
  time_scale:float -> world:Body.b list -> Body.b list * (Body.b * Body.b) list

(** [calc_collision_point b1 b2] calculates the point on the surface where
    bodies [b1] and [b2] touch during a collision. *)
val calc_collision_point : Body.b -> Body.b -> Vec3.v

(** [update_trails trails world all_collisions] updates trail histories with
    new positions from [world]. Returns [(new_trails, collision_pairs)]. *)
val update_trails :
  Vec3.v list list ->
  Body.b list ->
  (Body.b * Body.b) list ->
  Vec3.v list list * (Body.b * Body.b) list

(** [find_collisions world] returns a list of all body pairs currently
    colliding in [world]. *)
val find_collisions : Body.b list -> (Body.b * Body.b) list

(** [is_colliding world] returns [true] if any bodies in [world] are currently
    colliding, [false] otherwise. *)
val is_colliding : Body.b list -> bool

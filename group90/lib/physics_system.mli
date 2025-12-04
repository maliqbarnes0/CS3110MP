(** Physics system module - handles all physics-related calculations.

    This module provides functions for:
    - Physics updates with substeps for accuracy
    - Collision detection
    - Trail position tracking *)

val update_physics :
  time_scale:float -> world:Body.b list -> Body.b list * (Body.b * Body.b) list
(** [update_physics ~time_scale ~world] is [(new_world, all_collisions)] where
    [new_world] is the updated list of bodies after physics simulation and
    [all_collisions] is a list of body pairs that collided during this update.
    Higher time scales use more substeps for accuracy. *)

val calc_collision_point : Body.b -> Body.b -> Vec3.v
(** [calc_collision_point b1 b2] is the point on the surface where bodies [b1]
    and [b2] touch during a collision. *)

val update_trails :
  Vec3.v list list ->
  Body.b list ->
  (Body.b * Body.b) list ->
  Vec3.v list list * (Body.b * Body.b) list
(** [update_trails trails world all_collisions] is
    [(new_trails, collision_pairs)] where [new_trails] is the updated trail
    histories with new positions from [world] and [collision_pairs] contains the
    collision information. *)

val find_collisions : Body.b list -> (Body.b * Body.b) list
(** [find_collisions world] is a list of all body pairs currently colliding in
    [world]. *)

val is_colliding : Body.b list -> bool
(** [is_colliding world] returns [true] if any bodies in [world] are currently
    colliding, [false] otherwise. *)

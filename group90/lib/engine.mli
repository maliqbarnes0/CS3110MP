(** N-body physics simulation engine. *)

val g : float
(** [g] is the gravitational constant: 6.67e-11 N⋅m²/kg². *)

type w = Body.b list
(** The type of a world, which is a collection of bodies. *)

val gravitational_force : Body.b -> by:Body.b -> Vec3.v
(** [gravitational_force b1 ~by:b2] is the gravitational force vector on [b1]
    exerted by [b2], computed using Newton's law F = G m₁ m₂ / r². If [b1] and
    [b2] occupy the same position, the result is [Vec3.zer0]. *)

val net_force_on : Body.b -> w -> Vec3.v
(** [net_force_on b world] is the total gravitational force on [b] from all
    other bodies in [world]. *)

val step : dt:float -> w -> w
(** [step ~dt world] is the state of [world] advanced by time [dt] using Euler
    integration. For each body, computes net force, acceleration (F=ma), updates
    velocity (v' = v + a·dt), and position (p' = p + v'·dt). *)

val check_collision : Body.b -> Body.b -> bool
(** [check_collision b1 b2] is [true] if [b1] and [b2] are colliding. Bodies
    collide when the distance between their centers is less than or equal to the
    sum of their radii. *)

val find_collisions : w -> (Body.b * Body.b) list
(** [find_collisions world] is a list of all pairs of colliding bodies in
    [world]. *)

val step_with_collisions : dt:float -> w -> w * (Body.b * Body.b) list
(** [step_with_collisions ~dt world] is [(world', collisions)] where [world'] is
    [world] advanced by time [dt] and [collisions] is the list of body pairs
    that collided during this step. *)

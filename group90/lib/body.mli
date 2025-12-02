(** Celestial body module for N-body physics simulation. Represents a body with
    mass, position, and velocity in 3D space. *)

type b
(** The type representing a celestial body (planet, star, asteroid, etc.). *)

val make : mass:float -> pos:Vec3.v -> vel:Vec3.v -> radius:float -> b
(** [make ~mass ~pos ~vel ~radius] creates a new body with the specified mass
    (in kilograms), position (as a 3D vector in meters), velocity (as a 3D
    vector in meters per second), and radius (in meters). *)

val mass : b -> float
(** [mass b] returns the mass of body [b] in kilograms. *)

val pos : b -> Vec3.v
(** [pos b] returns the current position vector of body [b] in meters. *)

val vel : b -> Vec3.v
(** [vel b] returns the current velocity vector of body [b] in meters per
    second. *)

val radius : b -> float
(** [radius b] returns the radius of body [b] in meters. *)

val with_pos : Vec3.v -> b -> b
(** [with_pos p b] returns a new body identical to [b] but with position [p].
    Useful for updating position during simulation steps without mutation. *)

val with_vel : Vec3.v -> b -> b
(** [with_vel v b] returns a new body identical to [b] but with velocity [v].
    Useful for updating velocity during simulation steps without mutation. *)

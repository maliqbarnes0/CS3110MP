(** Celestial body module for N-body physics simulation.
    Represents a body with mass, position, and velocity in 3D space. *)

(** The type representing a celestial body (planet, star, asteroid, etc.). *)
type b 

(** [make ~mass ~pos ~vel] creates a new body with the given properties.
    @param mass The mass of the body in kilograms (must be positive).
    @param pos The initial position vector in meters.
    @param vel The initial velocity vector in meters per second.
    Example: [make ~mass:5.972e24 ~pos:(Vec3.make 0. 0. 0.) ~vel:(Vec3.make 0. 0. 0.)]
             creates an Earth-mass body at origin with zero velocity. *)
val make : mass:float -> pos:Vec3.v -> vel:Vec3.v -> b

(** [mass b] returns the mass of body [b] in kilograms. *)
val mass : b -> float

(** [pos b] returns the current position vector of body [b] in meters. *)
val pos  : b -> Vec3.v

(** [vel b] returns the current velocity vector of body [b] in meters per second. *)
val vel  : b -> Vec3.v

(** [with_pos p b] returns a new body identical to [b] but with position [p].
    Useful for updating position during simulation steps without mutation. *)
val with_pos : Vec3.v -> b -> b

(** [with_vel v b] returns a new body identical to [b] but with velocity [v].
    Useful for updating velocity during simulation steps without mutation. *)
val with_vel : Vec3.v -> b -> b


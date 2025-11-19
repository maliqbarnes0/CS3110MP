(** 3D vector module for physics calculations.
    Vectors are used to represent positions, velocities, forces, and accelerations. *)

(** The type representing a 3D vector with x, y, z components. *)
type v 

(** [make x y z] creates a new 3D vector with components x, y, z.
    Example: [make 1.0 2.0 3.0] creates vector (1.0, 2.0, 3.0) *)
val make : float -> float -> float -> v

(** [zer0] is the zero vector (0, 0, 0).
    Useful as initial value for accumulating forces or as a default. *)
val zer0 : v

(** [x v] returns the x-component of vector [v]. *)
val x : v -> float

(** [y v] returns the y-component of vector [v]. *)
val y : v -> float

(** [z v] returns the z-component of vector [v]. *)
val z : v -> float

(** [v1 + v2] returns the vector sum of [v1] and [v2].
    Adds corresponding components: (x1+x2, y1+y2, z1+z2) *)
val ( + ) : v -> v -> v

(** [v1 - v2] returns the vector difference [v1] minus [v2].
    Subtracts corresponding components: (x1-x2, y1-y2, z1-z2) *)
val ( - ) : v -> v -> v

(** [s *~ v] returns the scalar multiplication of [s] and [v].
    Multiplies each component by scalar: (s*x, s*y, s*z) *)
val ( *~ ) : float -> v -> v

(** [dot v1 v2] returns the dot product of [v1] and [v2].
    Computes: x1*x2 + y1*y2 + z1*z2 *)
val dot : v -> v -> float

(** [norm v] returns the magnitude (length) of vector [v].
    Computes: sqrt(x² + y² + z²) *)
val norm : v -> float

(** [normalize v] returns a unit vector in the direction of [v].
    Returns [zer0] if [v] is the zero vector to avoid division by zero.
    Otherwise returns [v / norm v]. *)
val normalize : v -> v
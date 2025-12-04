(** 3D vector module for physics calculations. *)

type v
(** The type of a 3D vector. *)

val make : float -> float -> float -> v
(** [make x y z] is a 3D vector with components [x], [y], and [z]. *)

val zer0 : v
(** [zer0] is the zero vector (0, 0, 0). *)

val x : v -> float
(** [x v] is the x-component of [v]. *)

val y : v -> float
(** [y v] is the y-component of [v]. *)

val z : v -> float
(** [z v] is the z-component of [v]. *)

val ( + ) : v -> v -> v
(** [v1 + v2] is the vector sum of [v1] and [v2]. *)

val ( - ) : v -> v -> v
(** [v1 - v2] is the vector difference of [v1] and [v2]. *)

val ( *~ ) : float -> v -> v
(** [s *~ v] is the scalar product of [s] and [v]. *)

val dot : v -> v -> float
(** [dot v1 v2] is the dot product of [v1] and [v2]. *)

val norm : v -> float
(** [norm v] is the magnitude (Euclidean length) of [v]. *)

val normalize : v -> v
(** [normalize v] is a unit vector in the direction of [v]. If [v] is the zero
    vector, the result is [zer0]. *)

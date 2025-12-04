(** Celestial body module for N-body physics simulation. *)

type b
(** The type of a celestial body. *)

(** Type for RGBA color as (r, g, b, a) where each component is 0-255 *)
type color = float * float * float * float

(** [make ~density ~pos ~vel ~radius ~color] is a body with density [density] (in kg/m³),
    position [pos], velocity [vel], radius [radius] (in meters), and color [color].
    Mass is calculated from density and radius using the sphere volume formula. *)
val make : density:float -> pos:Vec3.v -> vel:Vec3.v -> radius:float -> color:color -> b

val mass : b -> float
(** [mass b] is the mass of [b] in kilograms. *)

val pos : b -> Vec3.v
(** [pos b] is the position vector of [b]. *)

val vel : b -> Vec3.v
(** [vel b] is the velocity vector of [b]. *)

val radius : b -> float
(** [radius b] is the radius of [b] in meters. *)

val density : b -> float
(** [density b] is the density of [b] in kg/m³. *)

val with_pos : Vec3.v -> b -> b
(** [with_pos p b] is a body identical to [b] except with position [p]. *)

val with_vel : Vec3.v -> b -> b
(** [with_vel v b] is a body identical to [b] except with velocity [v]. *)

(** [color b] is the RGBA color of [b]. *)
val color : b -> color

(** [set_density d b] sets the density of [b] to [d] and updates its mass. *)
val set_density : float -> b -> unit
(** [set_density d b] sets the density of [b] to [d] and updates its mass. *)

val set_radius : float -> b -> unit
(** [set_radius r b] sets the radius of [b] to [r] and updates its mass. *)

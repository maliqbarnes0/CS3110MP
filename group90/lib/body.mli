(** Celestial body module for N-body physics simulation. *)

(** The type of a celestial body. *)
type b

(** [make ~density ~pos ~vel ~radius] is a body with density [density] (in kg/m³),
    position [pos], velocity [vel], and radius [radius] (in meters).
    Mass is calculated from density and radius using the sphere volume formula. *)
val make : density:float -> pos:Vec3.v -> vel:Vec3.v -> radius:float -> b

(** [mass b] is the mass of [b] in kilograms. *)
val mass : b -> float

(** [pos b] is the position vector of [b]. *)
val pos : b -> Vec3.v

(** [vel b] is the velocity vector of [b]. *)
val vel : b -> Vec3.v

(** [radius b] is the radius of [b] in meters. *)
val radius : b -> float

(** [density b] is the density of [b] in kg/m³. *)
val density : b -> float

(** [with_pos p b] is a body identical to [b] except with position [p]. *)
val with_pos : Vec3.v -> b -> b

(** [with_vel v b] is a body identical to [b] except with velocity [v]. *)
val with_vel : Vec3.v -> b -> b

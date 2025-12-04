(** Simulation state management module.

    This module handles all state management for the simulation including world
    state, trail history, collision animations, planet parameters, and time
    control. *)

type planet_params = float * float
(** Type for planet parameters: (density, radius) *)

type color = int * int * int * int
(** Type for RGBA color as (r, g, b, a) where each component is 0-255 *)

type collision_animation = {
  position : Vec3.v;  (** Position of the collision in 3D space *)
  start_time : float;  (** Time when the collision started *)
  duration : float;  (** How long the animation should last *)
  max_radius : float;  (** Maximum radius of the explosion effect *)
  color : color;  (** Color of the explosion *)
}
(** Type for collision animation *)

(** Type for a trail - can be active (attached to a body) or orphaned (body
    removed and trail is fading out) *)
type trail_state =
  | Active of Vec3.v list  (** Trail for a body that still exists *)
  | Orphaned of {
      positions : Vec3.v list;  (** Historical positions *)
      orphaned_at : float;  (** Time when the body was removed *)
    }  (** Trail for a removed body that is fading out *)

type t = {
  world : Body.b list;  (** Current list of celestial bodies *)
  trails : trail_state list;  (** Position history for rendering trails *)
  collision_anims : collision_animation list;
      (** Active collision animations *)
  time_scale : float;  (** Simulation speed multiplier *)
  paused : bool;  (** Whether the simulation is paused *)
  pending_params : planet_params list;  (** Current slider values *)
  applied_params : planet_params list;  (** Last applied parameter values *)
  current_scenario : string;  (** Name of the current scenario *)
}
(** Main simulation state *)

val create_initial : unit -> t
(** [create_initial ()] is the initial simulation state with default parameters.
*)

val set_time_scale : t -> float -> t
(** [set_time_scale state scale] is [state] with time scale set to [scale]. *)

val toggle_pause : t -> t
(** [toggle_pause state] is [state] with the paused flag toggled. *)

val set_world : t -> Body.b list -> t
(** [set_world state world] is [state] with the world set to [world]. *)

val set_trails : t -> trail_state list -> t
(** [set_trails state trails] is [state] with the trails set to [trails]. *)

val set_collision_anims : t -> collision_animation list -> t
(** [set_collision_anims state anims] is [state] with collision animations set
    to [anims]. *)

val set_pending_params : t -> planet_params list -> t
(** [set_pending_params state params] is [state] with pending parameters set to
    [params]. *)

val apply_params : t -> t
(** [apply_params state] is [state] with applied parameters set to the current
    pending parameters, marking them as the new baseline. *)

val reset_to_defaults : t -> t
(** [reset_to_defaults state] is [state] with both pending and applied
    parameters reset to default values, and trails and animations cleared. *)

val load_scenario : t -> string -> t
(** [load_scenario state scenario_name] is [state] prepared for loading scenario
    [scenario_name], with trails and animations cleared and the scenario name
    updated. *)

val has_pending_changes : t -> bool
(** [has_pending_changes state] is [true] if pending parameters differ from
    applied parameters, [false] otherwise. *)

val num_bodies : t -> int
(** [num_bodies state] is the number of bodies currently in the world. *)

val update_planet_density : t -> int -> float -> t
(** [update_planet_density state planet_idx new_density] is [state] with the
    density of the planet at index [planet_idx] set to [new_density]. Both the
    pending parameters and the live body (if it exists) are updated. *)

val update_planet_radius : t -> int -> float -> t
(** [update_planet_radius state planet_idx new_radius] is [state] with the
    radius of the planet at index [planet_idx] set to [new_radius]. Both the
    pending parameters and the live body (if it exists) are updated. *)

val add_collision_animations :
  t -> (Body.b * Body.b) list -> color list -> float -> t
(** [add_collision_animations state collision_pairs old_body_colors
     current_time] is [state] with new collision animations added for each pair
    in [collision_pairs], using [old_body_colors] to determine explosion colors
    and [current_time] as the animation start time. *)

val prune_expired_animations : t -> float -> t
(** [prune_expired_animations state current_time] is [state] with collision
    animations that have exceeded their duration removed. *)

val update_trails_with_fading : t -> Vec3.v list -> float -> t
(** [update_trails_with_fading state new_positions current_time] is [state] with
    trails updated using [new_positions] for active bodies and orphaned trail
    fading managed based on [current_time]. *)

val get_trail_render_info : trail_state -> float -> Vec3.v list * float
(** [get_trail_render_info trail current_time] is [(positions, alpha)] for
    rendering [trail], where [alpha] is 1.0 for active trails and fades out for
    orphaned trails based on [current_time]. *)

val prune_empty_trails : t -> t
(** [prune_empty_trails state] is [state] with trails that have fully faded out
    (empty orphaned trails) removed. *)

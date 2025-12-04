(** Simulation state management module.

    This module handles all state management for the simulation including world
    state, trail history, collision animations, planet parameters, and time
    control. *)

(** Type for planet parameters: (density, radius) *)
type planet_params = float * float

(** Type for RGBA color as (r, g, b, a) where each component is 0-255 *)
type color = int * int * int * int

(** Type for collision animation *)
type collision_animation = {
  position : Vec3.v;  (** Position of the collision in 3D space *)
  start_time : float;  (** Time when the collision started *)
  duration : float;  (** How long the animation should last *)
  max_radius : float;  (** Maximum radius of the explosion effect *)
  color : color;  (** Color of the explosion *)
}

(** Type for a trail - can be active (attached to a body) or orphaned (body
    removed and trail is fading out) *)
type trail_state =
  | Active of Vec3.v list  (** Trail for a body that still exists *)
  | Orphaned of {
      positions : Vec3.v list;  (** Historical positions *)
      orphaned_at : float;  (** Time when the body was removed *)
    }  (** Trail for a removed body that is fading out *)

(** Main simulation state *)
type t = {
  world : Body.b list;  (** Current list of celestial bodies *)
  trails : trail_state list;  (** Position history for rendering trails *)
  collision_anims : collision_animation list;  (** Active collision animations *)
  time_scale : float;  (** Simulation speed multiplier *)
  paused : bool;  (** Whether the simulation is paused *)
  pending_params : planet_params list;  (** Current slider values *)
  applied_params : planet_params list;  (** Last applied parameter values *)
  current_scenario : string;  (** Name of the current scenario *)
}

(** [create_initial ()] creates the initial simulation state with default
    parameters. *)
val create_initial : unit -> t

(** [set_time_scale state scale] updates the time scale to [scale]. *)
val set_time_scale : t -> float -> t

(** [toggle_pause state] toggles the paused state. *)
val toggle_pause : t -> t

(** [set_world state world] updates the world to [world]. *)
val set_world : t -> Body.b list -> t

(** [set_trails state trails] updates the trails to [trails]. *)
val set_trails : t -> trail_state list -> t

(** [set_collision_anims state anims] updates the collision animations to
    [anims]. *)
val set_collision_anims : t -> collision_animation list -> t

(** [set_pending_params state params] updates the pending parameters to
    [params]. *)
val set_pending_params : t -> planet_params list -> t

(** [apply_params state] copies pending parameters to applied parameters,
    marking them as the new baseline. *)
val apply_params : t -> t

(** [reset_to_defaults state] resets both pending and applied parameters to
    default values and clears trails and animations. *)
val reset_to_defaults : t -> t

(** [load_scenario state scenario_name] prepares the state for loading a new
    scenario by clearing trails and animations and updating the scenario name. *)
val load_scenario : t -> string -> t

(** [has_pending_changes state] returns [true] if pending parameters differ
    from applied parameters. *)
val has_pending_changes : t -> bool

(** [num_bodies state] returns the number of bodies currently in the world. *)
val num_bodies : t -> int

(** [update_planet_density state planet_idx new_density] updates the density
    of the planet at index [planet_idx] to [new_density]. Updates both the
    pending parameters and the live body if it exists. *)
val update_planet_density : t -> int -> float -> t

(** [update_planet_radius state planet_idx new_radius] updates the radius of
    the planet at index [planet_idx] to [new_radius]. Updates both the pending
    parameters and the live body if it exists. *)
val update_planet_radius : t -> int -> float -> t

(** [add_collision_animations state collision_pairs old_body_colors current_time]
    adds new collision animations for each pair in [collision_pairs].
    [old_body_colors] is used to determine the explosion color. *)
val add_collision_animations :
  t -> (Body.b * Body.b) list -> color list -> float -> t

(** [prune_expired_animations state current_time] removes collision animations
    that have exceeded their duration. *)
val prune_expired_animations : t -> float -> t

(** [update_trails_with_fading state new_positions current_time] updates
    trails with new positions for active bodies and manages orphaned trail
    fading. *)
val update_trails_with_fading : t -> Vec3.v list -> float -> t

(** [get_trail_render_info trail current_time] returns [(positions, alpha)]
    for rendering a trail, where [alpha] is 1.0 for active trails and fades
    out for orphaned trails. *)
val get_trail_render_info : trail_state -> float -> Vec3.v list * float

(** [prune_empty_trails state] removes trails that have fully faded out (empty
    orphaned trails). *)
val prune_empty_trails : t -> t

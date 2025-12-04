(** Scenario module - handles creation of different physics scenarios.

    This module provides pre-configured celestial body setups for simulation,
    including various N-body problems and orbital configurations. *)

(** Type representing a simulation scenario *)
type scenario = {
  name : string;  (** Human-readable name of the scenario *)
  description : string;  (** Brief description of the scenario *)
  bodies : Body.b list;  (** List of celestial bodies in this scenario *)
  recommended_camera : float * float * float;
      (** Recommended camera position as (theta, phi, radius) *)
}

(** [create_three_body_system ?custom_params ()] creates a deterministic
    three-body system. If [custom_params] is provided as
    [Some (d1, r1, d2, r2, d3, r3)], uses those density and radius values for
    the three bodies. Otherwise uses default values for a stable binary pair
    with an interloping third body. *)
val create_three_body_system :
  ?custom_params:(float * float * float * float * float * float) option ->
  unit ->
  Body.b list

(** [default_scenario ()] returns the default three-body problem scenario. *)
val default_scenario : unit -> scenario

(** [scenario_from_params params_list] creates a three-body scenario from a
    list of [(density, radius)] pairs. Requires at least 3 pairs. *)
val scenario_from_params : (float * float) list -> scenario

(** [get_scenario_by_name name] returns the scenario with the given name.
    Returns the default scenario if [name] is not recognized. *)
val get_scenario_by_name : string -> scenario

(** [all_scenarios] is a list of all available scenario names. *)
val all_scenarios : string list

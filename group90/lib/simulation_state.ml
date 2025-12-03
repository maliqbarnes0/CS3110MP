(**
   Simulation state management module.

   This module handles all state management for the simulation including:
   - World state (bodies)
   - Trail history
   - Collision animations
   - Planet parameters
   - Time control (time scale, paused state)
*)

(** Type for planet parameters: (density, radius) *)
type planet_params = float * float

(** Type for RGBA color as (r, g, b, a) where each component is 0-255 *)
type color = int * int * int * int

(** Type for collision animation *)
type collision_animation = {
  position : Vec3.v;
  start_time : float;
  duration : float;
  max_radius : float;
  color : color;
}

(** Type for a trail - can be active (attached to a body) or orphaned (body removed) *)
type trail_state =
  | Active of Vec3.v list
  | Orphaned of { positions : Vec3.v list; orphaned_at : float }

(** Main simulation state *)
type t = {
  world : Body.b list;
  trails : trail_state list;
  collision_anims : collision_animation list;
  time_scale : float;
  paused : bool;
  pending_params : planet_params list;
  applied_params : planet_params list;
  current_scenario : string;
}

(** Create initial simulation state with default parameters *)
let create_initial () =
  let default_params = [
    (3.5747e10, 20.);  (* Planet 1: density, radius *)
    (2.6810e10, 18.);  (* Planet 2: density, radius *)
    (1.7873e10, 16.);  (* Planet 3: density, radius *)
  ] in
  {
    world = [];
    trails = [ Active []; Active []; Active [] ];
    collision_anims = [];
    time_scale = 1.0;
    paused = false;
    pending_params = default_params;
    applied_params = default_params;
    current_scenario = "Three-Body Problem";
  }

(** Update time scale *)
let set_time_scale state scale =
  { state with time_scale = scale }

(** Toggle paused state *)
let toggle_pause state =
  { state with paused = not state.paused }

(** Update world state *)
let set_world state world =
  { state with world = world }

(** Update trails *)
let set_trails state trails =
  { state with trails = trails }

(** Update collision animations *)
let set_collision_anims state anims =
  { state with collision_anims = anims }

(** Update pending parameters *)
let set_pending_params state params =
  { state with pending_params = params }

(** Apply pending parameters to applied parameters *)
let apply_params state =
  { state with applied_params = state.pending_params }

(** Reset to default parameters *)
let reset_to_defaults state =
  let default_params = [
    (3.5747e10, 20.);
    (2.6810e10, 18.);
    (1.7873e10, 16.);
  ] in
  { state with
    pending_params = default_params;
    applied_params = default_params;
    trails = [ Active []; Active []; Active [] ];
    collision_anims = [];
  }

(** Load a scenario by name *)
let load_scenario state scenario_name =
  { state with
    trails = [ Active []; Active []; Active [] ];
    collision_anims = [];
    current_scenario = scenario_name;
  }

(** Check if there are unapplied parameter changes *)
let has_pending_changes state =
  state.pending_params <> state.applied_params

(** Get number of alive bodies *)
let num_bodies state =
  List.length state.world

(** Update a specific planet's density *)
let update_planet_density state planet_idx new_density =
  let new_params = List.mapi (fun i (old_d, old_r) ->
    if i = planet_idx then (new_density, old_r) else (old_d, old_r)
  ) state.pending_params in
  { state with pending_params = new_params }

(** Update a specific planet's radius *)
let update_planet_radius state planet_idx new_radius =
  let new_params = List.mapi (fun i (old_d, old_r) ->
    if i = planet_idx then (old_d, new_radius) else (old_d, old_r)
  ) state.pending_params in
  { state with pending_params = new_params }

(** Add collision animations for collision pairs *)
let add_collision_animations state collision_pairs old_body_colors current_time =
  let new_anims = List.fold_left
    (fun acc (b1, b2) ->
      let pos_b1 = Body.pos b1 in
      let pos_b2 = Body.pos b2 in
      let pos = Vec3.((0.5 *~ (pos_b1 + pos_b2))) in
      let max_radius = Float.max (Body.radius b1) (Body.radius b2) *. 4.0 in

      (* Find indices of colliding bodies *)
      let idx1_opt = List.find_index (fun b -> b == b1) state.world in
      let idx2_opt = List.find_index (fun b -> b == b2) state.world in

      (* Get and blend colors *)
      let explosion_color = match (idx1_opt, idx2_opt) with
        | (Some idx1, Some idx2) ->
            let (r1, g1, b1, a1) = List.nth old_body_colors idx1 in
            let (r2, g2, b2, a2) = List.nth old_body_colors idx2 in
            ((r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2, (a1 + a2) / 2)
        | _ -> (255, 200, 150, 255)
      in

      let new_anim = {
        position = pos;
        start_time = current_time;
        duration = 1.0;
        max_radius;
        color = explosion_color;
      } in
      new_anim :: acc
    )
    state.collision_anims
    collision_pairs
  in
  { state with collision_anims = new_anims }

(** Remove expired collision animations *)
let prune_expired_animations state current_time =
  let active_anims = List.filter (fun anim ->
    current_time -. anim.start_time < anim.duration
  ) state.collision_anims in
  { state with collision_anims = active_anims }

(** Update trails - mark trails as orphaned when bodies are removed, fade orphaned trails *)
let update_trails_with_fading state new_positions current_time =
  let num_bodies = List.length state.world in
  let fade_duration = 3.0 in  (* Trails fade out over 3 seconds *)

  (* Update trails - add new positions for active bodies, mark others as orphaned *)
  let updated_trails = List.mapi (fun i trail ->
    match trail with
    | Active positions ->
        if i < num_bodies then
          (* Body still exists - add new position *)
          let new_pos = List.nth new_positions i in
          let updated = new_pos :: positions in
          (* Keep only last 100 positions *)
          let trimmed = if List.length updated > 100 then
            List.filteri (fun j _ -> j < 100) updated
          else
            updated
          in
          Active trimmed
        else
          (* Body removed - mark as orphaned *)
          Orphaned { positions = positions; orphaned_at = current_time }
    | Orphaned { positions; orphaned_at } ->
        (* Already orphaned - fade it out *)
        let age = current_time -. orphaned_at in
        if age > fade_duration then
          Orphaned { positions = []; orphaned_at }  (* Fully faded *)
        else
          (* Gradually remove points *)
          let remove_fraction = age /. fade_duration in
          let num_to_remove = int_of_float (float_of_int (List.length positions) *. remove_fraction) in
          let remaining = List.filteri (fun j _ -> j < (List.length positions - num_to_remove)) positions in
          Orphaned { positions = remaining; orphaned_at }
  ) state.trails in

  { state with trails = updated_trails }

(** Get trail positions and alpha values for rendering *)
let get_trail_render_info trail current_time =
  match trail with
  | Active positions -> (positions, 1.0)
  | Orphaned { positions; orphaned_at } ->
      let fade_duration = 3.0 in
      let age = current_time -. orphaned_at in
      let alpha = max 0.0 (1.0 -. (age /. fade_duration)) in
      (positions, alpha)

(** Clean up empty orphaned trails *)
let prune_empty_trails state =
  let non_empty = List.filter (fun trail ->
    match trail with
    | Active _ -> true
    | Orphaned { positions; _ } -> List.length positions > 0
  ) state.trails in
  { state with trails = non_empty }

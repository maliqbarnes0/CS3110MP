(** Simulation state management module.

    This module handles all state management for the simulation including:
    - World state (bodies)
    - Trail history
    - Collision animations
    - Planet parameters
    - Time control (time scale, paused state) *)

type planet_params = float * float
(** Type for planet parameters: (density, radius) *)

type color = int * int * int * int
(** Type for RGBA color as (r, g, b, a) where each component is 0-255 *)

type collision_animation = {
  position : Vec3.v;
  start_time : float;
  duration : float;
  max_radius : float;
  color : color;
}
(** Type for collision animation *)

(** Type for a trail - can be active (attached to a body) or orphaned (body
    removed) *)
type trail_state =
  | Active of Vec3.v list
  | Orphaned of {
      positions : Vec3.v list;
      orphaned_at : float;
    }

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
(** Main simulation state *)

(** Create initial simulation state with default parameters *)
let create_initial () =
  let default_params =
    [
      (3.5747e10, 20.);
      (* Planet 1: density, radius *)
      (2.6810e10, 18.);
      (* Planet 2: density, radius *)
      (1.7873e10, 16.);
      (* Planet 3: density, radius *)
    ]
  in
  {
    world = [];
    trails = [];  (* Will be initialized based on actual body count *)
    collision_anims = [];
    time_scale = 1.0;
    paused = false;
    pending_params = default_params;
    applied_params = default_params;
    current_scenario = "Three-Body Problem";
  }

(** Update time scale *)
let set_time_scale state scale = { state with time_scale = scale }

(** Toggle paused state *)
let toggle_pause state = { state with paused = not state.paused }

(** Update world state *)
let set_world state world = { state with world }

(** Update trails *)
let set_trails state trails = { state with trails }

(** Update collision animations *)
let set_collision_anims state anims = { state with collision_anims = anims }

(** Update pending parameters *)
let set_pending_params state params = { state with pending_params = params }

(** Apply pending parameters to applied parameters *)
let apply_params state = { state with applied_params = state.pending_params }

(** Reset to default parameters *)
let reset_to_defaults state =
  let default_params =
    [ (3.5747e10, 20.); (2.6810e10, 18.); (1.7873e10, 16.) ]
  in
  {
    state with
    pending_params = default_params;
    applied_params = default_params;
    trails = [];  (* Will be initialized based on actual body count *)
    collision_anims = [];
  }

(** Load a scenario by name *)
let load_scenario state scenario_name =
  (* Clear trails and animations for new scenario *)
  {
    state with
    trails = [];  (* Will be initialized based on actual body count *)
    collision_anims = [];
    current_scenario = scenario_name;
  }

(** Check if there are unapplied parameter changes *)
let has_pending_changes state = state.pending_params <> state.applied_params

(** Get number of alive bodies *)
let num_bodies state = List.length state.world

(** Update a specific planet's density *)
let update_planet_density state planet_idx new_density =
  let new_params =
    List.mapi
      (fun i (old_d, old_r) ->
        if i = planet_idx then (new_density, old_r) else (old_d, old_r))
      state.pending_params
  in
  { state with pending_params = new_params }

(** Update a specific planet's radius *)
let update_planet_radius state planet_idx new_radius =
  let new_params =
    List.mapi
      (fun i (old_d, old_r) ->
        if i = planet_idx then (old_d, new_radius) else (old_d, old_r))
      state.pending_params
  in
  { state with pending_params = new_params }

(** Add collision animations for collision pairs *)
let add_collision_animations state collision_pairs old_body_colors current_time
    =
  let new_anims =
    List.fold_left
      (fun acc (b1, b2) ->
        let pos1 = Body.pos b1 in
        let pos2 = Body.pos b2 in
        let radius1 = Body.radius b1 in
        let radius2 = Body.radius b2 in

        (* Calculate collision point at center of mass - where merged body will be *)
        let mass1 = Body.mass b1 in
        let mass2 = Body.mass b2 in
        let total_mass = mass1 +. mass2 in

        (* Center of mass calculation - exactly where the merged body appears *)
        let collision_pos =
          let open Vec3 in
          (1. /. total_mass) *~ ((mass1 *~ pos1) + (mass2 *~ pos2))
        in

        (* Explosion size based on sum of radii, but capped reasonably *)
        let max_radius = Float.min ((radius1 +. radius2) *. 1.5) 60.0 in

        (* Find indices of colliding bodies *)
        let idx1_opt = List.find_index (fun b -> b == b1) state.world in
        let idx2_opt = List.find_index (fun b -> b == b2) state.world in

        (* Get and blend colors *)
        let explosion_color =
          match (idx1_opt, idx2_opt) with
          | Some idx1, Some idx2 ->
              let red1, green1, blue1, alpha1 = List.nth old_body_colors idx1 in
              let red2, green2, blue2, alpha2 = List.nth old_body_colors idx2 in
              ((red1 + red2) / 2, (green1 + green2) / 2, (blue1 + blue2) / 2, (alpha1 + alpha2) / 2)
          | _ -> (255, 200, 150, 255)
        in

        let new_anim =
          {
            position = collision_pos;
            start_time = current_time;
            duration = 1.2;  (* Slightly longer for better visibility *)
            max_radius;
            color = explosion_color;
          }
        in
        new_anim :: acc)
      state.collision_anims collision_pairs
  in
  { state with collision_anims = new_anims }

(** Remove expired collision animations *)
let prune_expired_animations state current_time =
  let active_anims =
    List.filter
      (fun anim -> current_time -. anim.start_time < anim.duration)
      state.collision_anims
  in
  { state with collision_anims = active_anims }

(** Update trails - mark trails as orphaned when bodies are removed, fade
    orphaned trails *)
let update_trails_with_fading state new_positions current_time =
  let num_bodies = List.length state.world in
  let fade_duration = 2.5 in
  (* Trails fade out over 2.5 seconds *)

  (* Ensure we have enough trail slots *)
  let num_trails_needed = max num_bodies (List.length state.trails) in
  let padded_trails =
    if List.length state.trails < num_trails_needed then
      state.trails @ List.init (num_trails_needed - List.length state.trails) (fun _ -> Active [])
    else
      state.trails
  in

  (* Update trails - add new positions for active bodies, mark others as orphaned *)
  let updated_trails =
    List.mapi
      (fun i trail ->
        match trail with
        | Active positions ->
            if i < num_bodies then
              (* Body still exists - add new position *)
              let new_pos = List.nth new_positions i in
              let updated = new_pos :: positions in
              (* Keep only last 120 positions for smoother trails *)
              let trimmed =
                if List.length updated > 120 then
                  List.filteri (fun j _ -> j < 120) updated
                else updated
              in
              Active trimmed
            else
              (* Body removed - mark as orphaned, keep all positions for smooth fade *)
              Orphaned { positions; orphaned_at = current_time }
        | Orphaned { positions; orphaned_at } ->
            (* Already orphaned - keep positions but fade via alpha *)
            let age = current_time -. orphaned_at in
            if age > fade_duration then
              Orphaned { positions = []; orphaned_at }  (* Fully faded *)
            else
              (* Keep all positions, alpha will handle the fade *)
              Orphaned { positions; orphaned_at })
      padded_trails
  in

  { state with trails = updated_trails }

(** Get trail positions and alpha values for rendering *)
let get_trail_render_info trail current_time =
  match trail with
  | Active positions -> (positions, 1.0)
  | Orphaned { positions; orphaned_at } ->
      let fade_duration = 2.5 in
      let age = current_time -. orphaned_at in
      (* Use a smooth fade curve (quadratic easing) *)
      let linear_alpha = max 0.0 (1.0 -. (age /. fade_duration)) in
      let alpha = linear_alpha *. linear_alpha in  (* Quadratic fade for smoother look *)
      (positions, alpha)

(** Clean up empty orphaned trails *)
let prune_empty_trails state =
  let non_empty =
    List.filter
      (fun trail ->
        match trail with
        | Active _ -> true
        | Orphaned { positions; _ } -> List.length positions > 0)
      state.trails
  in
  { state with trails = non_empty }

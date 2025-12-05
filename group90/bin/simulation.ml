open Raylib
open Group90

(** Main simulation loop - handles rendering and input *)
let rec simulation_loop state camera theta phi radius =
  (* Handle UI button interactions *)
  let state_after_ui_buttons = handle_ui_buttons state in

  (* Handle slider interactions for planet parameters *)
  let state_after_sliders =
    if state_after_ui_buttons.Simulation_state.sidebar_visible then
      handle_slider_input state_after_ui_buttons
    else state_after_ui_buttons
  in

  (* Handle keyboard input *)
  let state_after_keyboard = handle_keyboard_input state_after_sliders in

  (* Handle planet selection *)
  let state_after_planet_selection =
    handle_planet_selection state_after_keyboard camera
  in

  let state_after_physics =
    if state_after_planet_selection.Simulation_state.paused then
      state_after_planet_selection
    else update_physics_step state_after_planet_selection
  in

  (* Update camera via dragging *)
  let new_camera, new_theta, new_phi, new_radius =
    if Ui.mouse_over_ui state_after_physics.sidebar_visible then
      (camera, theta, phi, radius)
    else Cameracontrol.update_camera camera theta phi radius
  in

  (* Check for exit condition *)
  let should_exit = Ui.check_exit_button () || window_should_close () in

  if should_exit then ()
  else begin
    render_frame state_after_physics new_camera;

    (* Framerate *)
    Unix.sleepf 0.016;

    (* Loop *)
    simulation_loop state_after_physics new_camera new_theta new_phi new_radius
  end

(** Handle UI button interactions *)
and handle_ui_buttons state =
  let state_after_close =
    if
      Ui.check_sidebar_close_button () && state.Simulation_state.sidebar_visible
    then Simulation_state.set_sidebar_visible state false
    else state
  in

  let state_after_arrows =
    if state_after_close.Simulation_state.sidebar_visible then begin
      if Ui.check_left_arrow () then
        Simulation_state.cycle_selected_planet state_after_close (-1)
      else if Ui.check_right_arrow () then
        Simulation_state.cycle_selected_planet state_after_close 1
      else state_after_close
    end
    else state_after_close
  in

  state_after_arrows

and handle_planet_selection state camera =
  if
    is_mouse_button_pressed MouseButton.Left
    && not (Ui.mouse_over_ui state.Simulation_state.sidebar_visible)
  then
    let mouse_pos = get_mouse_position () in
    let ray = get_screen_to_world_ray mouse_pos camera in

    (* Check collision with each body *)
    let clicked_planet_idx =
      List.fold_left
        (fun acc_idx (i, body) ->
          match acc_idx with
          | Some _ -> acc_idx
          | None ->
              let body_pos = Body.pos body in
              let render_scale = 0.1 in
              let pos_vec3 =
                Raylib.Vector3.create
                  (render_scale *. Vec3.x body_pos)
                  (render_scale *. Vec3.y body_pos)
                  (render_scale *. Vec3.z body_pos)
              in
              let body_radius = Body.radius body *. render_scale in
              let collision =
                Raylib.get_ray_collision_sphere ray pos_vec3 body_radius
              in
              if Raylib.RayCollision.hit collision then Some i else None)
        None
        (List.mapi (fun i b -> (i, b)) state.Simulation_state.world)
    in

    match clicked_planet_idx with
    | Some idx ->
        let state_with_selection =
          Simulation_state.set_selected_planet state idx
        in
        Simulation_state.set_sidebar_visible state_with_selection true
    | None -> state
  else state

(** Handle slider input for params *)
and handle_slider_input state =
  let sidebar_x = 560 in
  let sidebar_y = 50 in
  let slider_start_y = sidebar_y + 90 in
  let selected_idx = state.Simulation_state.selected_planet in

  let state_after_density =
    match Ui.check_slider_drag (sidebar_x + 20) slider_start_y 130 1. 20. with
    | Some ui_density ->
        let actual_density = Ui.ui_scale_to_density ui_density in
        Simulation_state.update_planet_density state selected_idx actual_density
    | None -> state
  in
  let state_after_radius =
    match
      Ui.check_slider_drag (sidebar_x + 20) (slider_start_y + 70) 130 1. 20.
    with
    | Some ui_radius ->
        let actual_radius = Ui.ui_scale_to_radius ui_radius in
        Simulation_state.update_planet_radius state_after_density selected_idx
          actual_radius
    | None -> state_after_density
  in

  state_after_radius

(** Handle keyboard input for simulation control *)
and handle_keyboard_input state =
  (* Scenario switching *)
  let state_after_scenario =
    if is_key_pressed Key.One then load_scenario_by_index state 0
    else if is_key_pressed Key.Two then load_scenario_by_index state 1
    else if is_key_pressed Key.Three then load_scenario_by_index state 2
    else if is_key_pressed Key.Four then load_scenario_by_index state 3
    else if is_key_pressed Key.Five then load_scenario_by_index state 4
    else if is_key_pressed Key.Six then load_scenario_by_index state 5
    else state
  in

  (* Check for reset *)
  let state_after_reset =
    if is_key_pressed Key.R then begin
      let scenario_name =
        state_after_scenario.Simulation_state.current_scenario
      in
      if scenario_name = "Three-Body Problem" then begin
        let new_bodies =
          Scenario.create_three_body_system
            ~custom_params:
              (Some
                 (extract_params_tuple
                    state_after_scenario.Simulation_state.pending_params))
            ()
        in
        let state_with_bodies =
          Simulation_state.set_world state_after_scenario new_bodies
        in
        let state_with_trails =
          Simulation_state.set_trails state_with_bodies []
        in
        let state_with_anims =
          Simulation_state.set_collision_anims state_with_trails []
        in
        Simulation_state.apply_params state_with_anims
      end
      else begin
        let scenario = Scenario.get_scenario_by_name scenario_name in
        let state_with_bodies =
          Simulation_state.set_world state_after_scenario scenario.bodies
        in
        let state_with_trails =
          Simulation_state.set_trails state_with_bodies []
        in
        let state_with_anims =
          Simulation_state.set_collision_anims state_with_trails []
        in
        let body_params =
          List.map
            (fun body -> (Body.density body, Body.radius body))
            scenario.bodies
        in
        let default_param = (3e10, 18.) in
        let reset_params =
          match body_params with
          | [] -> [ default_param; default_param; default_param ]
          | [ p1 ] -> [ p1; default_param; default_param ]
          | [ p1; p2 ] -> [ p1; p2; default_param ]
          | p1 :: p2 :: p3 :: _ -> [ p1; p2; p3 ]
        in
        {
          state_with_anims with
          pending_params = reset_params;
          applied_params = reset_params;
        }
      end
    end
    else state_after_scenario
  in

  let state_after_timescale =
    if is_key_pressed Key.Z then
      Simulation_state.set_time_scale state_after_reset
        (min (state_after_reset.time_scale *. 1.5) 20.0)
    else if is_key_pressed Key.X then
      Simulation_state.set_time_scale state_after_reset
        (max (state_after_reset.time_scale /. 1.5) 0.1)
    else state_after_reset
  in

  (* Check for pause *)
  if is_key_pressed Key.P then
    Simulation_state.toggle_pause state_after_timescale
  else state_after_timescale

and load_scenario_by_index state index =
  if index >= 0 && index < List.length Scenario.all_scenarios then
    let scenario_name = List.nth Scenario.all_scenarios index in
    let scenario = Scenario.get_scenario_by_name scenario_name in
    let state_loaded = Simulation_state.load_scenario state scenario.name in
    let state_with_bodies =
      Simulation_state.set_world state_loaded scenario.bodies
    in
    let body_params =
      List.map
        (fun body -> (Body.density body, Body.radius body))
        scenario.bodies
    in
    let default_param = (3e10, 18.) in
    let reset_params =
      match body_params with
      | [] -> [ default_param; default_param; default_param ]
      | [ p1 ] -> [ p1; default_param; default_param ]
      | [ p1; p2 ] -> [ p1; p2; default_param ]
      | p1 :: p2 :: p3 :: _ -> [ p1; p2; p3 ]
    in
    {
      state_with_bodies with
      pending_params = reset_params;
      applied_params = reset_params;
    }
  else state

(** Extract params *)
and extract_params_tuple params_list =
  match params_list with
  | (d1, r1) :: (d2, r2) :: (d3, r3) :: _ -> (d1, r1, d2, r2, d3, r3)
  | _ -> (3.5747e10, 20., 2.6810e10, 18., 1.7873e10, 16.)

(** Update physics for one step *)
and update_physics_step state =
  let current_time = Unix.gettimeofday () in

  let old_body_colors =
    List.map
      (fun body ->
        let r, g, b, a = Group90.Body.color body in
        let clamp_to_byte x = int_of_float (Float.max 0. (Float.min 255. x)) in
        (clamp_to_byte r, clamp_to_byte g, clamp_to_byte b, clamp_to_byte a))
      state.Simulation_state.world
  in

  (* Update physics *)
  let new_world, all_collisions =
    Physics_system.update_physics ~time_scale:state.time_scale
      ~world:state.world
  in

  (* Get new positions for trail updates *)
  let new_positions = List.map Body.pos new_world in

  (* Update state with new world *)
  let state_with_world = Simulation_state.set_world state new_world in

  (* Update trails with fading for removed bodies *)
  let state_with_trails =
    Simulation_state.update_trails_with_fading state_with_world new_positions
      current_time
  in

  let state_pruned = Simulation_state.prune_empty_trails state_with_trails in

  (* Add collision animations if any collisions occurred *)
  let state_with_collisions =
    if List.length all_collisions > 0 then
      Simulation_state.add_collision_animations state_pruned all_collisions
        old_body_colors current_time
    else state_pruned
  in

  (* Remove expired animations *)
  Simulation_state.prune_expired_animations state_with_collisions current_time

(** Render a frame *)
and render_frame state camera =
  begin_drawing ();
  clear_background (Ui.color 5 5 15 255);

  begin_scissor_mode 0 0 800 600;

  begin_mode_3d camera;

  (* Draw starbox *)
  Render.draw_starbox camera;

  let current_time = Unix.gettimeofday () in
  List.iteri
    (fun i trail ->
      let positions, alpha =
        Simulation_state.get_trail_render_info trail current_time
      in
      if List.length positions > 0 then begin
        (* Get color from corresponding body if available, otherwise use
           default *)
        let r, g, b, base_alpha =
          if i < List.length state.world then
            let body = List.nth state.world i in
            let r, g, b, a = Group90.Body.color body in
            let clamp_to_byte x =
              int_of_float (Float.max 0. (Float.min 255. x))
            in
            (clamp_to_byte r, clamp_to_byte g, clamp_to_byte b, 100)
          else (200, 200, 200, 100)
        in
        let faded_alpha = int_of_float (float_of_int base_alpha *. alpha) in
        let trail_color = Ui.color r g b faded_alpha in
        Render.draw_trail positions trail_color
      end)
    state.Simulation_state.trails;

  (* Draw bodies *)
  let body_colors = List.map Ui.get_body_color_from_body state.world in
  List.iter2 Render.draw_body state.world body_colors;

  let current_time = Unix.gettimeofday () in
  let render_scale = 0.1 in
  List.iter
    (fun anim ->
      let age = current_time -. anim.Simulation_state.start_time in
      let progress = age /. anim.duration in
      if progress < 1.0 then begin
        let current_radius = anim.max_radius *. progress *. render_scale in
        let alpha = int_of_float (255.0 *. (1.0 -. progress)) in
        let r, g, b, _ = anim.color in
        let fade_color = Raylib.Color.create r g b alpha in
        let pos_vec3 =
          Raylib.Vector3.create
            (render_scale *. Vec3.x anim.position)
            (render_scale *. Vec3.y anim.position)
            (render_scale *. Vec3.z anim.position)
        in
        Raylib.draw_sphere pos_vec3 current_radius fade_color
      end)
    state.collision_anims;

  end_mode_3d ();
  end_scissor_mode ();

  let is_colliding = Physics_system.is_colliding state.world in
  let has_changes = Simulation_state.has_pending_changes state in
  let num_alive = Simulation_state.num_bodies state in
  (* Draw 2D UI overlay *)
  Ui.draw_ui is_colliding state.time_scale state.paused state.pending_params
    has_changes num_alive state.current_scenario state.world
    state.sidebar_visible state.selected_planet;

  end_drawing ()

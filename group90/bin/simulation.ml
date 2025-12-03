(**
   Core simulation module - handles physics updates and main game loop.

   This module is the heart of the application, coordinating:
   - Physics simulation using Group90.Engine
   - User input processing (keyboard and sliders)
   - Camera updates via cameracontrol.ml
   - Rendering delegation to render.ml
   - UI updates via ui.ml
   - State management (trails, collision animations, planet parameters)

   The simulation_loop is a recursive function that runs each frame,
   maintaining all state through its parameters.
*)

open Raylib
open Group90
open Unix

let create_system ?(custom_params = None) () =
  let g = 6.67e-11 in

  (* Default parameters - densities calculated to match original masses *)
  (* Original: mass1 = 8000./g, mass2 = 6000./g, mass3 = 4000./g *)
  let default_radius1 = 20. in
  let default_radius2 = 18. in
  let default_radius3 = 16. in

  (* Calculate densities to preserve original masses *)
  let original_mass1 = 8000. /. g in
  let original_mass2 = 6000. /. g in
  let original_mass3 = 4000. /. g in

  let volume1 = (4.0 /. 3.0) *. Float.pi *. (default_radius1 ** 3.0) in
  let volume2 = (4.0 /. 3.0) *. Float.pi *. (default_radius2 ** 3.0) in
  let volume3 = (4.0 /. 3.0) *. Float.pi *. (default_radius3 ** 3.0) in

  let default_density1 = original_mass1 /. volume1 in
  let default_density2 = original_mass2 /. volume2 in
  let default_density3 = original_mass3 /. volume3 in

  (* Use custom params if provided, otherwise use defaults *)
  let (density1, radius1, density2, radius2, density3, radius3) = match custom_params with
    | Some params -> params
    | None -> (default_density1, default_radius1, default_density2, default_radius2, default_density3, default_radius3)
  in

  (* Calculate masses from density and radius *)
  let volume1 = (4.0 /. 3.0) *. Float.pi *. (radius1 ** 3.0) in
  let volume2 = (4.0 /. 3.0) *. Float.pi *. (radius2 ** 3.0) in
  let volume3 = (4.0 /. 3.0) *. Float.pi *. (radius3 ** 3.0) in

  let mass1 = density1 *. volume1 in
  let mass2 = density2 *. volume2 in
  let _mass3 = density3 *. volume3 in

  let separation = 120. in
  (* Compact separation to keep everything visible *)

  (* Center of mass at origin *)
  let com_x = 0. in
  let com_y = 0. in
  let com_z = 0. in

  (* Distances from center of mass *)
  let r1 = separation *. mass2 /. (mass1 +. mass2) in
  let r2 = separation *. mass1 /. (mass1 +. mass2) in

  (* Calculate orbital velocities using G from engine *)
  let total_mass = mass1 +. mass2 in
  let v_rel = Float.sqrt (g *. total_mass /. separation) in
  let v1 = v_rel *. mass2 /. total_mass in
  let v2 = v_rel *. mass1 /. total_mass in

  (* Body 1 - Heavy star orbiting in YZ plane *)
  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make com_x (com_y -. r1) com_z)
      ~vel:(Vec3.make 0. 0. v1) ~radius:radius1
  in
  (* Body 2 - Medium companion orbiting opposite direction *)
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make com_x (com_y +. r2) com_z)
      ~vel:(Vec3.make 0. 0. (-.v2)) ~radius:radius2
  in
  (* Body 3 - Interloper approaching at an angle with slower velocity *)
  let body3 =
    Body.make ~density:density3
      ~pos:(Vec3.make 180. 60. 100.) (* Even closer to keep in view *)
      ~vel:(Vec3.make (-1.0) (-0.4) (-0.6)) (* Slower to stay visible *)
      ~radius:radius3
  in
  [ body1; body2; body3 ]

let rec simulation_loop world trails time_scale paused camera theta phi radius
    collision_anims pending_params applied_params =
  (* Fixed physics timestep for accuracy *)
  let fixed_dt = 0.1 in

  (* Handle slider interactions - always work with 3 planets *)
  let sidebar_x = 600 in
  let new_pending_params =
    let params = ref pending_params in
    for i = 0 to 2 do
      let base_y = 55 + i * 145 in

      (* Check density slider with centered ranges *)
      (match Ui.check_slider_drag (sidebar_x + 50) (base_y + 60) 130 1e10 6e10 with
      | Some new_density ->
          params := List.mapi (fun j (old_d, old_r) ->
            if j = i then (new_density, old_r) else (old_d, old_r)
          ) !params
      | None -> ());

      (* Check radius slider *)
      (match Ui.check_slider_drag (sidebar_x + 50) (base_y + 110) 130 10. 40. with
      | Some new_radius ->
          params := List.mapi (fun j (old_d, old_r) ->
            if j = i then (old_d, new_radius) else (old_d, old_r)
          ) !params
      | None -> ())
    done;
    !params
  in

  (* Check for apply (A) or reset (R) *)
  let reset_world, reset_trails, reset_anims, reset_pending, reset_applied =
    if is_key_pressed Key.A then
      (* Apply current slider values - reset simulation with custom params *)
      let (d1, r1, d2, r2, d3, r3) = match new_pending_params with
        | (d1, r1) :: (d2, r2) :: (d3, r3) :: _ -> (d1, r1, d2, r2, d3, r3)
        | _ -> (3.5747e10, 20., 2.6810e10, 18., 1.7873e10, 16.) (* fallback to defaults *)
      in
      let custom_sys = create_system ~custom_params:(Some (d1, r1, d2, r2, d3, r3)) () in
      let reset_params = [(d1, r1); (d2, r2); (d3, r3)] in
      (custom_sys, [ []; []; [] ], [], reset_params, reset_params)
    else if is_key_pressed Key.R then
      (* Reset to original defaults - use exact same hardcoded values as initial_params *)
      let default_params = [
        (3.5747e10, 20.);  (* Planet 1: density, radius *)
        (2.6810e10, 18.);  (* Planet 2: density, radius *)
        (1.7873e10, 16.);  (* Planet 3: density, radius *)
      ] in
      let default_sys = create_system () in
      (default_sys, [ []; []; [] ], [], default_params, default_params)
    else (world, trails, collision_anims, new_pending_params, applied_params)
  in

  (* Update physics only if not paused, using substeps for accuracy *)
  let new_world, all_collisions =
    if paused then (reset_world, [])
    else begin
      (* Run multiple substeps based on time_scale to maintain accuracy *)
      let num_steps = max 1 (int_of_float (Float.ceil time_scale)) in
      let substep_dt = time_scale *. fixed_dt /. float_of_int num_steps in
      let rec do_steps w collisions_acc n =
        if n = 0 then (w, collisions_acc)
        else
          let new_w, step_collisions = Engine.step_with_collisions ~dt:substep_dt w in
          do_steps new_w (step_collisions @ collisions_acc) (n - 1)
      in
      do_steps reset_world [] num_steps
    end
  in

  (* Update trails with new positions (only if not paused) *)
  let new_trails, collision_pairs =
    if paused then (reset_trails, [])
    else Render.update_trails reset_trails new_world all_collisions
  in

  (* Check if parameters have changed *)
  let has_changes = reset_pending <> reset_applied in

  (* Get current time for animations *)
  let current_time = Unix.gettimeofday () in

  (* Add new collision animations for each collision pair *)
  let updated_anims =
    if List.length collision_pairs > 0 then
      (* Find body colors from old world before collision *)
      let old_body_colors = List.mapi (fun i _ -> Ui.get_body_color i) reset_world in
      List.fold_left
        (fun acc (b1, b2) ->
          let pos = Render.calc_collision_point b1 b2 in
          (* Calculate animation size based on the larger body *)
          let max_radius = Float.max (Body.radius b1) (Body.radius b2) *. 4.0 in

          (* Find indices of colliding bodies in old world *)
          let idx1_opt = List.find_index (fun b -> b == b1) reset_world in
          let idx2_opt = List.find_index (fun b -> b == b2) reset_world in

          (* Get and blend colors *)
          let explosion_color = match (idx1_opt, idx2_opt) with
            | (Some idx1, Some idx2) ->
                let c1 = List.nth old_body_colors idx1 in
                let c2 = List.nth old_body_colors idx2 in
                Ui.blend_colors c1 c2
            | _ -> Ui.color 255 200 150 255  (* fallback color *)
          in

          let new_anim =
            {
              Render.position = pos;
              start_time = current_time;
              duration = 1.0;
              (* Animation lasts 1 second *)
              max_radius;
              color = explosion_color;
            }
          in
          new_anim :: acc)
        reset_anims
        collision_pairs
    else
      reset_anims
  in

  (* Update existing animations (remove expired ones) *)
  let new_collision_anims =
    Render.update_collision_animations updated_anims current_time
  in

  (* Check for collisions in the NEW world state *)
  let collisions = Engine.find_collisions new_world in
  let is_colliding = List.length collisions > 0 in

  (* Update camera *)
  let new_camera, new_theta, new_phi, new_radius =
    Cameracontrol.update_camera camera theta phi radius
  in

  (* Check for key presses to adjust simulation speed *)
  let new_time_scale, new_paused =
    if is_key_pressed Key.Z then (min (time_scale *. 1.5) 20.0, paused)
    else if is_key_pressed Key.X then (max (time_scale /. 1.5) 0.1, paused)
    else if is_key_pressed Key.P then (time_scale, not paused)
    else (time_scale, paused)
  in

  let should_exit = Ui.check_exit_button () || window_should_close () in

  if should_exit then ()
  else begin
    (* Start drawing *)
    begin_drawing ();
    clear_background (Ui.color 5 5 15 255);  (* Dark space background *)

    (* Restrict 3D rendering to left side (non-sidebar area) *)
    begin_scissor_mode 0 0 600 600;

    (* 3D rendering *)
    begin_mode_3d new_camera;

    (* Draw in order: back to front *)
    Render.draw_starbox new_camera;       (* Stars first - farthest *)

    (* Draw trails first (behind bodies) *)
    let all_trail_colors =
      [ Ui.color 255 200 100 100; Ui.color 100 150 255 100; Ui.color 255 100 100 100 ]
    in
    let trail_colors =
      List.filteri (fun i _ -> i < List.length new_trails) all_trail_colors
    in
    List.iter2 Render.draw_trail new_trails trail_colors;

    (* Draw the bodies as spheres *)
    let all_body_colors =
      [ Ui.color 255 200 100 255; Ui.color 100 150 255 255; Ui.color 255 100 100 255 ]
    in
    let body_colors =
      List.filteri (fun i _ -> i < List.length new_world) all_body_colors
    in
    List.iter2 Render.draw_body new_world body_colors;

    (* Draw collision animations *)
    List.iter
      (fun anim -> Render.draw_collision_animation anim current_time)
      new_collision_anims;

    end_mode_3d ();

    (* End scissor mode *)
    end_scissor_mode ();

    (* Use params for UI display (shows what will be applied on reset) *)
    (* 2D UI overlay *)
    let num_alive = List.length new_world in
    Ui.draw_ui is_colliding new_time_scale new_paused reset_pending has_changes num_alive;

    end_drawing ();

    Unix.sleepf 0.016;
    simulation_loop new_world new_trails new_time_scale new_paused new_camera
      new_theta new_phi new_radius new_collision_anims reset_pending reset_applied
  end

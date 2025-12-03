open Raylib
open Group90
open Unix

(* Unit scaling for GUI visualization *)
(*
   The engine uses the real gravitational constant G = 6.67e-11 m³/(kg·s²)
   To make this work with pixel coordinates, we scale the masses by 1/G:

   mass_scaled = desired_strength / G

   This way: G * mass_scaled = desired_strength
   For example: mass1 = 1000/G means G*mass1 = 1000

   With this approach:
   - Positions are in pixels
   - Velocities are in pixels/second
   - The effective gravitational strength equals the desired value directly
*)

(* Helper to create Raylib Color *)
let color r g b a = Color.create r g b a
let black = color 0 0 0 255
let white = color 255 255 255 255
let red = color 255 0 0 255
let gray = color 80 80 80 255
let dark_gray = color 40 40 40 255

(* Trail configuration *)
let max_trail_length = 120 (* Number of positions to keep in trail *)

(* Render scale: physics coordinates to visual coordinates *)
let render_scale = 0.1  (* 1 physics unit = 0.1 render units *)

(* Generate stars once at initialization *)
let stars = ref []

let initialize_stars () =
  Random.self_init ();
  stars := List.init 400 (fun _ ->
    let theta = Random.float (2. *. Float.pi) in
    let phi = Random.float Float.pi -. (Float.pi /. 2.) in
    (* Stars between 800 and 1200 units away *)
    let radius = 800. +. Random.float 400. in

    let x = radius *. Float.cos phi *. Float.cos theta in
    let y = radius *. Float.sin phi in
    let z = radius *. Float.cos phi *. Float.sin theta in

    let brightness = 200 + Random.int 56 in
    let size = 1.5 +. Random.float 2.0 in

    (x, y, z, brightness, size)
  )

let draw_starbox camera =
  let cam_pos = Camera3D.position camera in

  (* Draw the starbox - stars follow camera *)
  List.iter (fun (x, y, z, brightness, size) ->
    let star_pos = Vector3.create
      (Vector3.x cam_pos +. x)
      (Vector3.y cam_pos +. y)
      (Vector3.z cam_pos +. z)
    in

    let star_color = color brightness brightness 255 255 in
    draw_sphere star_pos size star_color
  ) !stars

let draw_infinite_grid camera =
  let cam_pos = Camera3D.position camera in
  let cam_x = Vector3.x cam_pos in
  let cam_z = Vector3.z cam_pos in
  
  let grid_spacing = 50. in
  let grid_center_x = Float.round (cam_x /. grid_spacing) *. grid_spacing in
  let grid_center_z = Float.round (cam_z /. grid_spacing) *. grid_spacing in
  
  let visible_range = 800. in
  let num_lines = 20 in
  
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    
    let dist = Float.abs offset in
    let fade = Float.max 0. (1. -. (dist /. visible_range)) in
    let alpha = int_of_float (fade *. 50.) in
    
    if alpha > 5 then begin
      let grid_color = color 30 30 50 alpha in
      
      let start_x = Vector3.create 
        (grid_center_x -. visible_range) 0. (grid_center_z +. offset) in
      let end_x = Vector3.create 
        (grid_center_x +. visible_range) 0. (grid_center_z +. offset) in
      draw_line_3d start_x end_x grid_color;
      
      let start_z = Vector3.create 
        (grid_center_x +. offset) 0. (grid_center_z -. visible_range) in
      let end_z = Vector3.create 
        (grid_center_x +. offset) 0. (grid_center_z +. visible_range) in
      draw_line_3d start_z end_z grid_color
    end
  done

(* Trail type: list of Vec3 positions for each body *)
type trails = Vec3.v list list

(* Collision animation type *)
type collision_animation = {
  position : Vec3.v;
  start_time : float;
  duration : float;
  max_radius : float;
  color : Color.t;
}

type collision_animations = collision_animation list

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

let draw_body body body_color =
  let pos = Body.pos body in
  let radius = Body.radius body *. render_scale in
  let position = Vector3.create 
    (render_scale *. Vec3.x pos) 
    (render_scale *. Vec3.y pos) 
    (render_scale *. Vec3.z pos) in
  draw_sphere position radius body_color

(* Draw trail for a single body *)
let draw_trail trail trail_color =
  let rec draw_segments = function
    | [] | [ _ ] -> ()
    | p1 :: p2 :: rest ->
        let pos1 = Vector3.create 
          (render_scale *. Vec3.x p1) 
          (render_scale *. Vec3.y p1) 
          (render_scale *. Vec3.z p1) in
        let pos2 = Vector3.create 
          (render_scale *. Vec3.x p2) 
          (render_scale *. Vec3.y p2) 
          (render_scale *. Vec3.z p2) in
        (* Draw thicker lines by drawing small spheres at each position *)
        draw_sphere pos1 (1.5 *. render_scale) trail_color;
        draw_line_3d pos1 pos2 trail_color;
        draw_segments (p2 :: rest)
  in
  draw_segments trail

(* Calculate collision point between two bodies *)
let calc_collision_point b1 b2 =
  let pos1 = Body.pos b1 in
  let pos2 = Body.pos b2 in
  let r1 = Body.radius b1 in
  let r2 = Body.radius b2 in
  (* Calculate collision point: weighted by radii to be on the surface where they touch *)
  let total_r = r1 +. r2 in
  let weight1 = r1 /. total_r in
  let weight2 = r2 /. total_r in
  Vec3.((weight2 *~ pos1) + (weight1 *~ pos2))

(* Get color for a body based on index *)
let get_body_color index =
  let all_body_colors =
    [ color 255 200 100 255; color 100 150 255 255; color 255 100 100 255 ]
  in
  List.nth all_body_colors (index mod List.length all_body_colors)

(* Blend two colors together *)
let blend_colors c1 c2 =
  let r = (Color.r c1 + Color.r c2) / 2 in
  let g = (Color.g c1 + Color.g c2) / 2 in
  let b = (Color.b c1 + Color.b c2) / 2 in
  color r g b 255

(* Update trails with new positions, return (new_trails, collision_pairs) *)
let update_trails trails world collision_pairs =
  (* Rebuild trails when world size changes, and return collision pairs *)
  if List.length trails <> List.length world then
    (* Create empty trails for current world *)
    let new_trails = List.map (fun body -> [ Body.pos body ]) world in
    (new_trails, collision_pairs)
  else
    let new_trails =
      List.map2
        (fun trail body ->
          let pos = Body.pos body in
          let new_trail = pos :: trail in
          (* Keep only the last max_trail_length positions *)
          if List.length new_trail > max_trail_length then
            List.rev (List.tl (List.rev new_trail))
          else new_trail)
        trails world
    in
    (new_trails, collision_pairs)

(* Draw collision animation as simple expanding burst *)
let draw_collision_animation anim current_time =
  let elapsed = current_time -. anim.start_time in
  if elapsed < anim.duration then begin
    let progress = elapsed /. anim.duration in
    let pos =
      Vector3.create 
        (render_scale *. Vec3.x anim.position)
        (render_scale *. Vec3.y anim.position)
        (render_scale *. Vec3.z anim.position)
    in

    (* Get color components *)
    let r = Color.r anim.color in
    let g = Color.g anim.color in
    let b = Color.b anim.color in

    (* Single expanding sphere that fades out *)
    let alpha = int_of_float (255. *. (1. -. progress)) in
    let radius = anim.max_radius *. progress *. render_scale in

    if alpha > 0 && radius > 0. then
      draw_sphere pos radius (color r g b alpha)
  end

(* Update collision animations, removing expired ones *)
let update_collision_animations anims current_time =
  List.filter
    (fun anim -> current_time -. anim.start_time < anim.duration)
    anims

(* Draw 3D axis indicators and grid planes at origin *)
let draw_axes () =
  let axis_length = 150. in
  let grid_size = 400. in
  let grid_spacing = 50. in
  let grid_color = color 40 40 40 255 in

  (* Main axis lines - brighter *)
  (* X axis - Red *)
  let x_start = Vector3.create (-.axis_length) 0. 0. in
  let x_end = Vector3.create axis_length 0. 0. in
  draw_line_3d x_start x_end (color 255 80 80 255);

  (* Y axis - Green *)
  let y_start = Vector3.create 0. (-.axis_length) 0. in
  let y_end = Vector3.create 0. axis_length 0. in
  draw_line_3d y_start y_end (color 80 255 80 255);

  (* Z axis - Blue *)
  let z_start = Vector3.create 0. 0. (-.axis_length) in
  let z_end = Vector3.create 0. 0. axis_length in
  draw_line_3d z_start z_end (color 80 80 255 255);

  (* Grid lines on YZ plane (X = 0) *)
  let num_lines = int_of_float (grid_size /. grid_spacing) in
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Horizontal lines (parallel to Z) *)
    let start_z = Vector3.create 0. offset (-.grid_size /. 2.) in
    let end_z = Vector3.create 0. offset (grid_size /. 2.) in
    draw_line_3d start_z end_z grid_color;
    (* Vertical lines (parallel to Y) *)
    let start_y = Vector3.create 0. (-.grid_size /. 2.) offset in
    let end_y = Vector3.create 0. (grid_size /. 2.) offset in
    draw_line_3d start_y end_y grid_color
  done;

  (* Grid lines on XZ plane (Y = 0) *)
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Lines parallel to X *)
    let start_x = Vector3.create (-.grid_size /. 2.) 0. offset in
    let end_x = Vector3.create (grid_size /. 2.) 0. offset in
    draw_line_3d start_x end_x grid_color;
    (* Lines parallel to Z *)
    let start_z = Vector3.create offset 0. (-.grid_size /. 2.) in
    let end_z = Vector3.create offset 0. (grid_size /. 2.) in
    draw_line_3d start_z end_z grid_color
  done;

  (* Grid lines on XY plane (Z = 0) *)
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Lines parallel to X *)
    let start_x = Vector3.create (-.grid_size /. 2.) offset 0. in
    let end_x = Vector3.create (grid_size /. 2.) offset 0. in
    draw_line_3d start_x end_x grid_color;
    (* Lines parallel to Y *)
    let start_y = Vector3.create offset (-.grid_size /. 2.) 0. in
    let end_y = Vector3.create offset (grid_size /. 2.) 0. in
    draw_line_3d start_y end_y grid_color
  done

(* Slider helper functions *)
let draw_slider x y width value min_val max_val label =
  let slider_height = 6 in
  let handle_size = 12. in

  (* Calculate normalized position *)
  let normalized = (value -. min_val) /. (max_val -. min_val) in
  let filled_width = int_of_float (normalized *. float_of_int width) in
  let handle_x = x + filled_width in

  (* Filled part of track *)
  draw_rectangle x (y + 3) filled_width slider_height (color 100 140 200 255);

  (* Empty part of track *)
  draw_rectangle (x + filled_width) (y + 3) (width - filled_width) slider_height (color 40 45 60 255);

  (* Handle *)
  draw_circle handle_x (y + 6) handle_size (color 120 140 200 255);
  draw_circle handle_x (y + 6) (handle_size -. 2.) (color 200 220 255 255);

  (* Label and value *)
  draw_text label x (y - 18) 12 (color 200 200 220 255);
  (* Format value appropriately - use scientific notation for large values *)
  let value_str =
    if value > 1e9 then Printf.sprintf "%.1e" value
    else Printf.sprintf "%.1f" value
  in
  draw_text value_str (x + width + 10) (y - 2) 10 white

let check_slider_drag x y width min_val max_val =
  if is_mouse_button_down MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in

    if mouse_y >= y - 10 && mouse_y <= y + 16 && mouse_x >= x && mouse_x <= x + width then
      let normalized = float_of_int (mouse_x - x) /. float_of_int width in
      let clamped = Float.max 0. (Float.min 1. normalized) in
      Some (min_val +. clamped *. (max_val -. min_val))
    else
      None
  else
    None

(* Draw 2D UI overlay with sidebar *)
let draw_ui is_colliding time_scale paused planet_params has_changes num_alive_planets =
  (* Sidebar panel - right side *)
  let sidebar_x = 600 in
  let sidebar_y = 0 in
  let sidebar_width = 200 in
  let sidebar_height = 600 in

  (* Draw sidebar background *)
  draw_rectangle sidebar_x sidebar_y sidebar_width sidebar_height (color 20 25 35 230);
  draw_rectangle sidebar_x sidebar_y 3 sidebar_height (color 80 100 140 255);

  (* Title *)
  draw_text "CONTROL PANEL" (sidebar_x + 15) 15 14 (color 150 180 255 255);
  draw_line (sidebar_x + 10) 35 (sidebar_x + sidebar_width - 10) 35 (color 80 100 140 255);

  (* Change notification *)
  if has_changes then begin
    draw_text "(Changes made -" (sidebar_x + 20) 45 10 (color 255 200 100 255);
    draw_text " press A to apply)" (sidebar_x + 20) 57 10 (color 255 200 100 255)
  end;

  (* Planet controls - always show all 3 *)
  let planet_colors = [
    ("Planet 1", color 255 200 100 255);
    ("Planet 2", color 100 150 255 255);
    ("Planet 3", color 255 100 100 255);
  ] in

  List.iteri (fun i (name, col) ->
    let (density, radius) = List.nth planet_params i in
    let base_y = 75 + i * 160 in
    let is_merged = i >= num_alive_planets in

    (* Planet section header *)
    draw_text name (sidebar_x + 15) base_y 13 col;
    if is_merged then
      draw_text "(merged)" (sidebar_x + 95) base_y 10 (color 150 150 150 255);
    draw_circle (sidebar_x + 25) (base_y + 25) 8. col;

    (* Density slider with centered range *)
    draw_slider (sidebar_x + 50) (base_y + 60) 130 density 1e10 6e10 "Density";

    (* Radius slider *)
    draw_slider (sidebar_x + 50) (base_y + 110) 130 radius 10. 40. "Radius";

    (* Separator *)
    if i < 2 then
      draw_line (sidebar_x + 10) (base_y + 145) (sidebar_x + sidebar_width - 10) (base_y + 145) (color 50 60 80 255)
  ) planet_colors;

  (* Bottom controls *)
  draw_text (Printf.sprintf "Speed: %.1fx" time_scale) (sidebar_x + 15) 515 12 white;
  draw_text (if paused then "[P] Resume" else "[P] Pause") (sidebar_x + 15) 535 11 (color 180 180 200 255);
  draw_text "[A] Apply changes" (sidebar_x + 15) 553 11 (color 180 180 200 255);
  draw_text "[R] Reset to default" (sidebar_x + 15) 571 11 (color 180 180 200 255);

  (* Exit button - moved to left *)
  draw_rectangle 10 560 80 30 (color 180 50 50 255);
  draw_text "EXIT" 25 570 20 white;

  (* Draw collision warning *)
  if is_colliding then begin
    draw_rectangle 250 560 150 30 red;
    draw_text "COLLISION!" 260 570 18 white
  end

(* Check if exit button is clicked *)
let check_exit_button () =
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in
    (* Y coordinate: button is at y=560-590 from top *)
    mouse_x >= 10 && mouse_x <= 90 && mouse_y >= 560 && mouse_y <= 590
  else false

(* Update camera based on input *)
let update_camera camera theta phi radius =
  let open Vector3 in
  let target = Camera3D.target camera in

  (* Mouse drag to rotate *)
  let new_theta, new_phi =
    if is_mouse_button_down MouseButton.Left then
      let delta = get_mouse_delta () in
      let sensitivity = 0.003 in
      let theta_change = theta -. (Vector2.x delta *. sensitivity) in
      let phi_change = phi +. (Vector2.y delta *. sensitivity) in
      (* Clamp phi to avoid gimbal lock *)
      let clamped_phi = Float.max (-1.5) (Float.min 1.5 phi_change) in
      (theta_change, clamped_phi)
    else (theta, phi)
  in

  (* Zoom with mouse wheel - allow very close and very far zoom *)
  let wheel = get_mouse_wheel_move () in
  let new_radius =
    Float.max 10. (Float.min 50000. (radius -. (wheel *. 100.)))
  in

  (* Convert spherical to Cartesian *)
  let new_x =
    x target +. (new_radius *. Float.cos new_phi *. Float.cos new_theta)
  in
  let new_y = y target +. (new_radius *. Float.sin new_phi) in
  let new_z =
    z target +. (new_radius *. Float.cos new_phi *. Float.sin new_theta)
  in

  let new_camera =
    Camera3D.create
      (Vector3.create new_x new_y new_z)
      target (Vector3.create 0. 1. 0.) 70. CameraProjection.Perspective
  in
  (new_camera, new_theta, new_phi, new_radius)

let rec simulation_loop world trails time_scale paused camera theta phi radius
    collision_anims pending_params applied_params =
  (* Fixed physics timestep for accuracy *)
  let fixed_dt = 0.1 in

  (* Handle slider interactions - always work with 3 planets *)
  let sidebar_x = 600 in
  let new_pending_params =
    let params = ref pending_params in
    for i = 0 to 2 do
      let base_y = 75 + i * 160 in

      (* Check density slider with centered ranges *)
      (match check_slider_drag (sidebar_x + 50) (base_y + 60) 130 1e10 6e10 with
      | Some new_density ->
          params := List.mapi (fun j (old_d, old_r) ->
            if j = i then (new_density, old_r) else (old_d, old_r)
          ) !params
      | None -> ());

      (* Check radius slider *)
      (match check_slider_drag (sidebar_x + 50) (base_y + 110) 130 10. 40. with
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
      (* Reset to original defaults completely *)
      let g = 6.67e-11 in
      let default_radius1 = 20. in
      let default_radius2 = 18. in
      let default_radius3 = 16. in
      let original_mass1 = 8000. /. g in
      let original_mass2 = 6000. /. g in
      let original_mass3 = 4000. /. g in
      let volume1 = (4.0 /. 3.0) *. Float.pi *. (default_radius1 ** 3.0) in
      let volume2 = (4.0 /. 3.0) *. Float.pi *. (default_radius2 ** 3.0) in
      let volume3 = (4.0 /. 3.0) *. Float.pi *. (default_radius3 ** 3.0) in
      let default_density1 = original_mass1 /. volume1 in
      let default_density2 = original_mass2 /. volume2 in
      let default_density3 = original_mass3 /. volume3 in

      let default_sys = create_system () in
      let default_params = [(default_density1, default_radius1); (default_density2, default_radius2); (default_density3, default_radius3)] in
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
    else update_trails reset_trails new_world all_collisions
  in

  (* Check if parameters have changed *)
  let has_changes = reset_pending <> reset_applied in

  (* Get current time for animations *)
  let current_time = Unix.gettimeofday () in

  (* Add new collision animations for each collision pair *)
  let updated_anims =
    if List.length collision_pairs > 0 then
      (* Find body colors from old world before collision *)
      let old_body_colors = List.mapi (fun i _ -> get_body_color i) reset_world in
      List.fold_left
        (fun acc (b1, b2) ->
          let pos = calc_collision_point b1 b2 in
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
                blend_colors c1 c2
            | _ -> color 255 200 150 255  (* fallback color *)
          in

          let new_anim =
            {
              position = pos;
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
    update_collision_animations updated_anims current_time
  in

  (* Check for collisions in the NEW world state *)
  let collisions = Engine.find_collisions new_world in
  let is_colliding = List.length collisions > 0 in

  (* Update camera *)
  let new_camera, new_theta, new_phi, new_radius =
    update_camera camera theta phi radius
  in

  (* Check for key presses to adjust simulation speed *)
  let new_time_scale, new_paused =
    if is_key_pressed Key.Z then (min (time_scale *. 1.5) 20.0, paused)
    else if is_key_pressed Key.X then (max (time_scale /. 1.5) 0.1, paused)
    else if is_key_pressed Key.P then (time_scale, not paused)
    else (time_scale, paused)
  in

  let should_exit = check_exit_button () || window_should_close () in

  if should_exit then ()
  else begin
    (* Start drawing *)
    begin_drawing ();
    clear_background (color 5 5 15 255);  (* Dark space background *)

    (* Restrict 3D rendering to left side (non-sidebar area) *)
    begin_scissor_mode 0 0 600 600;

    (* 3D rendering *)
    begin_mode_3d new_camera;

    (* Draw in order: back to front *)
    draw_starbox new_camera;       (* Stars first - farthest *)

    (* Draw trails first (behind bodies) *)
    let all_trail_colors =
      [ color 255 200 100 100; color 100 150 255 100; color 255 100 100 100 ]
    in
    let trail_colors =
      List.filteri (fun i _ -> i < List.length new_trails) all_trail_colors
    in
    List.iter2 draw_trail new_trails trail_colors;

    (* Draw the bodies as spheres *)
    let all_body_colors =
      [ color 255 200 100 255; color 100 150 255 255; color 255 100 100 255 ]
    in
    let body_colors =
      List.filteri (fun i _ -> i < List.length new_world) all_body_colors
    in
    List.iter2 draw_body new_world body_colors;

    (* Draw collision animations *)
    List.iter
      (fun anim -> draw_collision_animation anim current_time)
      new_collision_anims;

    end_mode_3d ();

    (* End scissor mode *)
    end_scissor_mode ();

    (* Use params for UI display (shows what will be applied on reset) *)
    (* 2D UI overlay *)
    let num_alive = List.length new_world in
    draw_ui is_colliding new_time_scale new_paused reset_pending has_changes num_alive;

    end_drawing ();

    Unix.sleepf 0.016;
    simulation_loop new_world new_trails new_time_scale new_paused new_camera
      new_theta new_phi new_radius new_collision_anims reset_pending reset_applied
  end

let () =
  init_window 800 600 "3D Gravity Simulation";
  set_target_fps 60;

  initialize_stars ();  (* Generate stars once *)

  (* Setup 3D camera closer to action *)
  let camera =
    Camera3D.create
      (Vector3.create 150. 100. 150.) (* position: much closer view *)
      (Vector3.create 0. 0. 0.) (* target: origin *)
      (Vector3.create 0. 1. 0.) (* up vector *)
      70. (* fov - wider to see more *)
      CameraProjection.Perspective
  in

  (* Initial spherical coordinates for camera *)
  let initial_radius =
    Float.sqrt ((150. *. 150.) +. (100. *. 100.) +. (150. *. 150.))
  in
  let initial_theta = Float.atan2 150. 150. in
  let initial_phi = Float.asin (100. /. initial_radius) in

  (* Initial empty trails for 3 bodies *)
  let initial_trails = [ []; []; [] ] in

  (* Initial empty collision animations *)
  let initial_collision_anims = [] in

  (* Initial parameters - using defaults calculated in create_system *)
  (* These match the original masses: 8000/g, 6000/g, 4000/g *)
  let initial_params = [
    (3.5747e10, 20.);  (* Planet 1: density, radius *)
    (2.6810e10, 18.);  (* Planet 2: density, radius *)
    (1.7873e10, 16.);  (* Planet 3: density, radius *)
  ] in

  (* Start with 1.0x time scale (real-time) *)
  simulation_loop (create_system ()) initial_trails 1.0 false camera
    initial_theta initial_phi initial_radius initial_collision_anims initial_params initial_params;

  (* Exit screen - keep drawing until user presses a key *)
  let rec exit_screen () =
    if window_should_close () then ()
    else if is_key_pressed Key.Space || is_key_pressed Key.Enter then ()
    else begin
      begin_drawing ();
      clear_background black;
      draw_text "Simulation Closed. Press SPACE or ENTER to exit." 80 300 20
        white;
      end_drawing ();
      Unix.sleepf 0.016;
      exit_screen ()
    end
  in
  exit_screen ();

  close_window ()

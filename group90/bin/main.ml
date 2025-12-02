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
let max_trail_length = 120  (* Number of positions to keep in trail *)

(* Trail type: list of Vec3 positions for each body *)
type trails = Vec3.v list list

let create_system () =
  (* Masses - more similar for chaotic interactions *)
  let g = 6.67e-11 in
  (* Increased masses significantly to keep velocities lower *)
  let mass1 = 8000. *. (1. /. g) in   (* Heavy star *)
  let mass2 = 6000. *. (1. /. g) in   (* Medium companion *)
  let mass3 = 4000. *. (1. /. g) in   (* Smaller interloper *)

  (* Visual radii based on mass (cube root scaling for volume) *)
  let radius1 = 20. *. Float.pow (mass1 /. mass1) (1. /. 3.) in  (* 20 units *)
  let radius2 = 20. *. Float.pow (mass2 /. mass1) (1. /. 3.) in (* ~18 units *)
  let radius3 = 20. *. Float.pow (mass3 /. mass1) (1. /. 3.) in(* ~15.7 units *)

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
  let density1 = mass1 /. ((4.0 /. 3.0) *. Float.pi *. radius1 ** 3.0) in
  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make com_x (com_y -. r1) com_z)
      ~vel:(Vec3.make 0. 0. v1) ~radius:radius1
  in
  (* Body 2 - Medium companion orbiting opposite direction *)
  let density2 = mass2 /. ((4.0 /. 3.0) *. Float.pi *. radius2 ** 3.0) in
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make com_x (com_y +. r2) com_z)
      ~vel:(Vec3.make 0. 0. (-.v2)) ~radius:radius2
  in
  (* Body 3 - Interloper approaching at an angle with slower velocity *)
  let density3 = mass3 /. ((4.0 /. 3.0) *. Float.pi *. radius3 ** 3.0) in
  let body3 =
    Body.make ~density:density3
      ~pos:(Vec3.make 180. 60. 100.) (* Even closer to keep in view *)
      ~vel:(Vec3.make (-1.0) (-0.4) (-0.6)) (* Slower to stay visible *)
      ~radius:radius3
  in
  [ body1; body2; body3 ]

let draw_body body body_color =
  let pos = Body.pos body in
  let radius = Body.radius body in
  let position = Vector3.create (Vec3.x pos) (Vec3.y pos) (Vec3.z pos) in
  draw_sphere position radius body_color

(* Draw trail for a single body *)
let draw_trail trail trail_color =
  let rec draw_segments = function
    | [] | [_] -> ()
    | p1 :: p2 :: rest ->
        let pos1 = Vector3.create (Vec3.x p1) (Vec3.y p1) (Vec3.z p1) in
        let pos2 = Vector3.create (Vec3.x p2) (Vec3.y p2) (Vec3.z p2) in
        (* Draw thicker lines by drawing small spheres at each position *)
        draw_sphere pos1 1.5 trail_color;
        draw_line_3d pos1 pos2 trail_color;
        draw_segments (p2 :: rest)
  in
  draw_segments trail

(* Update trails with new positions *)
let update_trails trails world =
  List.map2
    (fun trail body ->
      let pos = Body.pos body in
      let new_trail = pos :: trail in
      (* Keep only the last max_trail_length positions *)
      if List.length new_trail > max_trail_length then
        List.rev (List.tl (List.rev new_trail))
      else
        new_trail)
    trails world

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

(* Draw 2D UI overlay *)
let draw_ui is_colliding dt paused =
  (* Draw exit button *)
  draw_rectangle 10 560 80 30 gray;
  draw_text "EXIT" 25 570 20 white;

  (* Draw collision warning *)
  if is_colliding then begin
    draw_rectangle 300 560 200 30 red;
    draw_text "COLLISION!" 310 570 20 white
  end;

  (* Draw speed info *)
  draw_text (Printf.sprintf "Speed: %.1fx" dt) 650 570 20 white;
  draw_text "Z: faster | X: slower" 630 550 15 white;
  draw_text (if paused then "P: unpause" else "P: pause") 630 530 15 white;
  draw_text "R: reset simulation" 630 510 15 white;

  (* Draw camera controls *)
  draw_text "Left Click + Drag: Rotate Camera" 10 10 15 white;
  draw_text "Mouse Wheel: Zoom" 10 30 15 white

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

  (* Zoom with mouse wheel *)
  let wheel = get_mouse_wheel_move () in
  let new_radius = Float.max 100. (Float.min 2000. (radius -. wheel *. 50.)) in

  (* Convert spherical to Cartesian *)
  let new_x = x target +. new_radius *. Float.cos new_phi *. Float.cos 
  new_theta in
  let new_y = y target +. new_radius *. Float.sin new_phi in
  let new_z = z target +. new_radius *. Float.cos new_phi *. Float.sin 
  new_theta in

  let new_camera = Camera3D.create
    (Vector3.create new_x new_y new_z)
    target
    (Vector3.create 0. 1. 0.)
    70.
    CameraProjection.Perspective
  in
  (new_camera, new_theta, new_phi, new_radius)

let rec simulation_loop world trails dt paused camera theta phi radius =
  (* Check for reset *)
  let reset_world, reset_trails =
    if is_key_pressed Key.R then
      (create_system (), [[];[];[]])  (* Reset trails to empty lists *)
    else
      (world, trails)
  in

  (* Update physics only if not paused *)
  let new_world = if paused then reset_world else Engine.step ~dt reset_world in

  (* Update trails with new positions (only if not paused) *)
  let new_trails =
    if paused then reset_trails
    else update_trails reset_trails new_world
  in

  (* Check for collisions in the NEW world state *)
  let collisions = Engine.find_collisions new_world in
  let is_colliding = List.length collisions > 0 in

  (* Update camera *)
  let new_camera, new_theta, new_phi, new_radius =
    update_camera camera theta phi radius in

  (* Check for key presses to adjust simulation speed *)
  let new_dt, new_paused =
    if is_key_pressed Key.Z then (min (dt *. 1.5) 100.0, paused)
    else if is_key_pressed Key.X then (max (dt /. 1.5) 0.1, paused)
    else if is_key_pressed Key.P then (dt, not paused)
    else (dt, paused)
  in

  let should_exit = check_exit_button () || window_should_close () in

  if should_exit then ()
  else begin
    (* Start drawing *)
    begin_drawing ();
    clear_background black;

    (* 3D rendering *)
    begin_mode_3d new_camera;

    (* Draw axis indicators *)
    draw_axes ();

    (* Draw trails first (behind bodies) *)
    draw_trail (List.nth new_trails 0) (color 255 200 100 100);  (* Semi-transparent *)
    draw_trail (List.nth new_trails 1) (color 100 150 255 100);
    draw_trail (List.nth new_trails 2) (color 255 100 100 100);

    (* Draw the 3 bodies as spheres *)
    draw_body (List.nth new_world 0) (color 255 200 100 255);
    draw_body (List.nth new_world 1) (color 100 150 255 255);
    draw_body (List.nth new_world 2) (color 255 100 100 255);

    end_mode_3d ();

    (* 2D UI overlay *)
    draw_ui is_colliding new_dt new_paused;

    end_drawing ();

    Unix.sleepf 0.016;
    simulation_loop new_world new_trails new_dt new_paused new_camera new_theta new_phi new_radius
  end

let () =
  init_window 800 600 "3D Gravity Simulation";
  set_target_fps 60;

  (* Setup 3D camera closer to action *)
  let camera = Camera3D.create
    (Vector3.create 400. 300. 400.)  (* position: closer view *)
    (Vector3.create 0. 0. 0.)        (* target: origin *)
    (Vector3.create 0. 1. 0.)        (* up vector *)
    70.                               (* fov - wider to see more *)
    CameraProjection.Perspective
  in

  (* Initial spherical coordinates for camera *)
  let initial_radius = Float.sqrt (400. *. 400. +. 300. *. 300. +. 400. *. 400.) in
  let initial_theta = Float.atan2 400. 400. in
  let initial_phi = Float.asin (300. /. initial_radius) in

  (* Initial empty trails for 3 bodies *)
  let initial_trails = [[];[];[]] in

  simulation_loop (create_system ()) initial_trails 0.5 false camera 
  initial_theta initial_phi initial_radius;

  (* Exit screen - keep drawing until user presses a key *)
  let rec exit_screen () =
    if window_should_close () then ()
    else if is_key_pressed Key.Space || is_key_pressed Key.Enter then ()
    else begin
      begin_drawing ();
      clear_background black;
      draw_text "Simulation Closed. Press SPACE or ENTER to exit." 80 300 20 white;
      end_drawing ();
      Unix.sleepf 0.016;
      exit_screen ()
    end
  in
  exit_screen ();

  close_window ()

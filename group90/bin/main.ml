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

let create_system () =
  (* Masses *)
  let g = 6.67e-11 in
  let mass1 = 1000. *. (1. /. g) in
  let mass2 = 100. *. (1. /. g) in
  let mass3 = 200. *. (1. /. g) in

  (* Visual radii based on mass (cube root scaling for volume) *)
  let radius1 = 15. *. Float.pow (mass1 /. mass1) (1. /. 3.) in  (* 15 units *)
  let radius2 = 15. *. Float.pow (mass2 /. mass1) (1. /. 3.) in  (* ~7 units *)
  let radius3 = 15. *. Float.pow (mass3 /. mass1) (1. /. 3.) in  (* ~9 units *)

  let separation = 300. in
  (* pixels *)

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

  (* Large mass - closer to center *)
  (* Bodies orbit in XY plane (vertical when viewed from default camera angle) *)
  let body1 =
    Body.make ~mass:mass1
      ~pos:(Vec3.make (com_x -. r1) com_y com_z)
      ~vel:(Vec3.make 0. v1 0.) ~radius:radius1
  in
  (* Smaller mass - farther from center *)
  let body2 =
    Body.make ~mass:mass2
      ~pos:(Vec3.make (com_x +. r2) com_y com_z)
      ~vel:(Vec3.make 0. (-.v2) 0.) ~radius:radius2
  in
  (* Third body on collision course with body2 *)
  let body3 =
    Body.make ~mass:mass3
      ~pos:(Vec3.make (com_x +. r2 +. 150.) com_y com_z) (* start to the right *)
      ~vel:(Vec3.make (-2.) 0. 0.) (* moving left toward body2 *)
      ~radius:radius3
  in
  [ body1; body2; body3 ]

let draw_body body body_color =
  let pos = Body.pos body in
  let radius = Body.radius body in
  let position = Vector3.create (Vec3.x pos) (Vec3.y pos) (Vec3.z pos) in
  draw_sphere position radius body_color

(* Draw a 3D grid on the XZ plane *)
let draw_grid slices spacing =
  let half_size = float_of_int slices *. spacing /. 2. in
  for i = 0 to slices do
    let offset = (float_of_int i *. spacing) -. half_size in
    (* Lines parallel to X axis *)
    let start_x = Vector3.create (-.half_size) 0. offset in
    let end_x = Vector3.create half_size 0. offset in
    draw_line_3d start_x end_x dark_gray;
    (* Lines parallel to Z axis *)
    let start_z = Vector3.create offset 0. (-.half_size) in
    let end_z = Vector3.create offset 0. half_size in
    draw_line_3d start_z end_z dark_gray
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
  let new_x = x target +. new_radius *. Float.cos new_phi *. Float.cos new_theta in
  let new_y = y target +. new_radius *. Float.sin new_phi in
  let new_z = z target +. new_radius *. Float.cos new_phi *. Float.sin new_theta in

  let new_camera = Camera3D.create
    (Vector3.create new_x new_y new_z)
    target
    (Vector3.create 0. 1. 0.)
    45.
    CameraProjection.Perspective
  in
  (new_camera, new_theta, new_phi, new_radius)

let rec simulation_loop world dt paused camera theta phi radius =
  (* Check for reset *)
  let reset_world = if is_key_pressed Key.R then create_system () else world in

  (* Update physics only if not paused *)
  let new_world = if paused then reset_world else Engine.step ~dt reset_world in

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

    (* Draw grid *)
    draw_grid 40 50.;

    (* Draw the 3 bodies as spheres *)
    draw_body (List.nth new_world 0) (color 255 200 100 255);
    draw_body (List.nth new_world 1) (color 100 150 255 255);
    draw_body (List.nth new_world 2) (color 255 100 100 255);

    end_mode_3d ();

    (* 2D UI overlay *)
    draw_ui is_colliding new_dt new_paused;

    end_drawing ();

    Unix.sleepf 0.016;
    simulation_loop new_world new_dt new_paused new_camera new_theta new_phi new_radius
  end

let () =
  init_window 800 600 "3D Gravity Simulation";
  set_target_fps 60;

  (* Setup 3D camera *)
  let camera = Camera3D.create
    (Vector3.create 600. 400. 600.)  (* position: looking from an angle *)
    (Vector3.create 0. 0. 0.)        (* target: origin *)
    (Vector3.create 0. 1. 0.)        (* up vector *)
    45.                               (* fov *)
    CameraProjection.Perspective
  in

  (* Initial spherical coordinates for camera *)
  let initial_radius = Float.sqrt (600. *. 600. +. 400. *. 400. +. 600. *. 600.) in
  let initial_theta = Float.atan2 600. 600. in
  let initial_phi = Float.asin (400. /. initial_radius) in

  simulation_loop (create_system ()) 2.0 false camera initial_theta initial_phi initial_radius;

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

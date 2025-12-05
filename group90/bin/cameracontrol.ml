(** Camera control module - manages 3D camera movement and positioning.

    Implements a spherical coordinate camera system that orbits around a
    movable target:
    - theta: Horizontal angle around the target
    - phi: Vertical angle (clamped to prevent gimbal lock)
    - radius: Distance from target (zoom level)

    Input handling:
    - Left mouse drag: Rotate camera (only when not over sidebar)
    - Mouse wheel: Zoom in/out (range: 10 to 50,000 units)
    - WASD: Pan camera (relative to camera orientation)
    - Q/E: Move camera down/up

    Called by simulation.ml each frame to update camera based on user input. *)

open Raylib

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
  let new_radius =
    Float.max 10. (Float.min 50000. (radius -. (wheel *. 10.)))
  in

  (* Camera panning with WASD/QE - movement relative to camera orientation *)
  let pan_speed = 5.0 in
  
  (* Calculate forward vector (from target to camera, projected on XZ plane) *)
  let cam_pos = Camera3D.position camera in
  let forward_x = x cam_pos -. x target in
  let forward_z = z cam_pos -. z target in
  let forward_len = Float.sqrt (forward_x *. forward_x +. forward_z *. forward_z) in
  let forward_x_norm = if forward_len > 0. then forward_x /. forward_len else 0. in
  let forward_z_norm = if forward_len > 0. then forward_z /. forward_len else 0. in
  
  (* Right vector (perpendicular to forward on XZ plane) *)
  let right_x = -.forward_z_norm in
  let right_z = forward_x_norm in
  
  (* Calculate target offset based on key presses *)
  let offset_x = ref 0. in
  let offset_y = ref 0. in
  let offset_z = ref 0. in
  
  (* W: Move forward (toward where camera is pointing) *)
  if is_key_down Key.W then begin
    offset_x := !offset_x -. forward_x_norm *. pan_speed;
    offset_z := !offset_z -. forward_z_norm *. pan_speed;
  end;
  
  (* S: Move backward (away from where camera is pointing) *)
  if is_key_down Key.S then begin
    offset_x := !offset_x +. forward_x_norm *. pan_speed;
    offset_z := !offset_z +. forward_z_norm *. pan_speed;
  end;
  
  (* A: Strafe right *)
  if is_key_down Key.A then begin
    offset_x := !offset_x +. right_x *. pan_speed;
    offset_z := !offset_z +. right_z *. pan_speed;
  end;
  
  (* D: Strafe left *)
  if is_key_down Key.D then begin
    offset_x := !offset_x -. right_x *. pan_speed;
    offset_z := !offset_z -. right_z *. pan_speed;
  end;
  
  (* Q: Move down *)
  if is_key_down Key.Q then begin
    offset_y := !offset_y -. pan_speed;
  end;
  
  (* E: Move up *)
  if is_key_down Key.E then begin
    offset_y := !offset_y +. pan_speed;
  end;
  
  (* Apply offset to target *)
  let new_target = Vector3.create 
    (x target +. !offset_x) 
    (y target +. !offset_y) 
    (z target +. !offset_z) in

  (* Convert spherical to Cartesian relative to new target *)
  let new_x =
    x new_target +. (new_radius *. Float.cos new_phi *. Float.cos new_theta)
  in
  let new_y = y new_target +. (new_radius *. Float.sin new_phi) in
  let new_z =
    z new_target +. (new_radius *. Float.cos new_phi *. Float.sin new_theta)
  in

  let new_camera =
    Camera3D.create
      (Vector3.create new_x new_y new_z)
      new_target (Vector3.create 0. 1. 0.) 70. CameraProjection.Perspective
  in
  (new_camera, new_theta, new_phi, new_radius)

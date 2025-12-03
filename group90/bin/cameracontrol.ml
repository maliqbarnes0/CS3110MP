(** Camera control module - manages 3D camera movement and positioning.

    Implements a spherical coordinate camera system that orbits around the
    origin:
    - theta: Horizontal angle around the target
    - phi: Vertical angle (clamped to prevent gimbal lock)
    - radius: Distance from target (zoom level)

    Input handling:
    - Left mouse drag: Rotate camera (only when not over sidebar)
    - Mouse wheel: Zoom in/out (range: 10 to 50,000 units)

    Called by simulation.ml each frame to update camera based on user input. *)

open Raylib

(* Update camera based on input *)
let update_camera camera theta phi radius =
  let open Vector3 in
  let target = Camera3D.target camera in

  (* Check if mouse is over sidebar (right side at x >= 600) *)
  let mouse_over_sidebar = Ui.mouse_over_sidebar () in

  (* Mouse drag to rotate - only if not over sidebar *)
  let new_theta, new_phi =
    if is_mouse_button_down MouseButton.Left && not mouse_over_sidebar then
      let delta = get_mouse_delta () in
      let sensitivity = 0.003 in
      let theta_change = theta -. (Vector2.x delta *. sensitivity) in
      let phi_change = phi +. (Vector2.y delta *. sensitivity) in
      (* Clamp phi to avoid gimbal lock *)
      let clamped_phi = Float.max (-1.5) (Float.min 1.5 phi_change) in
      (theta_change, clamped_phi)
    else (theta, phi)
  in

  (* Zoom with mouse wheel - only if not over sidebar *)
  let wheel = if not mouse_over_sidebar then get_mouse_wheel_move () else 0. in
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

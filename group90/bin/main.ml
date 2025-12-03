(** Main entry point for the 3D Gravity Simulation.

    This module initializes the application window, sets up the initial camera,
    and bootstraps the simulation. It delegates to:
    - render.ml: For star initialization and 3D rendering
    - simulation.ml: For the main physics and game loop
    - ui.ml: For 2D interface elements

    Flow: Window setup → Star generation → Camera initialization → Start
    simulation loop → Exit screen *)

open Raylib
open Unix

let () =
  init_window 800 600 "3D Gravity Simulation";
  set_target_fps 60;

  Render.initialize_stars ();

  (* Generate stars once *)

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
  let initial_params =
    [
      (3.5747e10, 20.);
      (* Planet 1: density, radius *)
      (2.6810e10, 18.);
      (* Planet 2: density, radius *)
      (1.7873e10, 16.);
      (* Planet 3: density, radius *)
    ]
  in

  (* Start with 1.0x time scale (real-time) *)
  Simulation.simulation_loop
    (Simulation.create_system ())
    initial_trails 1.0 false camera initial_theta initial_phi initial_radius
    initial_collision_anims initial_params initial_params;

  (* Exit screen - keep drawing until user presses a key *)
  let rec exit_screen () =
    if window_should_close () then ()
    else if is_key_pressed Key.Space || is_key_pressed Key.Enter then ()
    else begin
      begin_drawing ();
      clear_background Ui.black;
      draw_text "Simulation Closed. Press SPACE or ENTER to exit." 80 300 20
        Ui.white;
      end_drawing ();
      Unix.sleepf 0.016;
      exit_screen ()
    end
  in
  exit_screen ();

  close_window ()

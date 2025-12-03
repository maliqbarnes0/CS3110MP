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

  (* Create initial simulation state using backend modules *)
  let default_scenario = Group90.Scenario.default_scenario () in
  let initial_state = Group90.Simulation_state.create_initial () in
  let initial_state_with_world = Group90.Simulation_state.set_world initial_state default_scenario.bodies in

  (* Start the simulation loop *)
  Simulation.simulation_loop
    initial_state_with_world
    camera initial_theta initial_phi initial_radius;

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

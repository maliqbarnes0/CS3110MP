(** N-Body Physics Simulation with Interactive 2D Visualization *)

open Graphics
open Group92
open Unix

(** Configuration constants *)
module Config = struct
  let width = 1200
  let height = 900
  let fps = 60
  let frame_delay = 1.0 /. float_of_int fps

  (** Default simulation time step (can be adjusted with speed controls) *)
  let default_dt = 3600.0 *. 24.0  (* 1 day per frame *)

  (** Trail configuration *)
  let max_trail_length = 100
  let trail_fade = true
end

(** Camera state for 2D projection and navigation *)
type camera = {
  zoom : float;        (* meters per pixel *)
  offset_x : float;    (* camera center x in world coordinates *)
  offset_y : float;    (* camera center y in world coordinates *)
}

(** GUI state *)
type state = {
  world : Engine.w;
  camera : camera;
  paused : bool;
  speed : float;        (* time multiplier *)
  trails : (Vec3.v list) list;  (* position history for each body *)
  time_elapsed : float; (* total simulation time in seconds *)
}

(** Color palette for bodies *)
let body_colors = [|
  0xFFD700;  (* Gold *)
  0x4169E1;  (* Royal Blue *)
  0xFF4500;  (* Orange Red *)
  0x32CD32;  (* Lime Green *)
  0xFF1493;  (* Deep Pink *)
  0x00CED1;  (* Dark Turquoise *)
  0xFF8C00;  (* Dark Orange *)
  0x9370DB;  (* Medium Purple *)
  0xDC143C;  (* Crimson *)
  0x00FA9A;  (* Medium Spring Green *)
|]

(** Get color for body at index i *)
let get_body_color i =
  body_colors.(i mod Array.length body_colors)

(** Planet names for labeling *)
let planet_names = [|
  "Sun";
  "Mercury";
  "Venus";
  "Earth";
  "Mars";
  "Jupiter";
  "Saturn";
  "Uranus";
  "Neptune"
|]

(** Convert world coordinates to screen coordinates *)
let world_to_screen (cam : camera) (pos : Vec3.v) : int * int =
  let screen_center_x = Config.width / 2 in
  let screen_center_y = Config.height / 2 in

  (* Project 3D to 2D (view from above, looking down at XY plane) *)
  let world_x = Vec3.x pos in
  let world_y = Vec3.y pos in

  (* Apply camera transform *)
  let rel_x = world_x -. cam.offset_x in
  let rel_y = world_y -. cam.offset_y in

  let screen_x = screen_center_x + int_of_float (rel_x /. cam.zoom) in
  let screen_y = screen_center_y + int_of_float (rel_y /. cam.zoom) in

  (screen_x, screen_y)

(** Calculate appropriate radius for rendering based on mass *)
let body_radius (mass : float) : int =
  (* Logarithmic scaling for better visualization *)
  let base_radius = 3.0 in
  let scale = log10 (mass /. 1e20 +. 1.0) in
  max 3 (int_of_float (base_radius +. scale *. 2.0))

(** Draw a single body *)
let draw_body (cam : camera) (body : Body.b) (color : int) : unit =
  let pos = Body.pos body in
  let (sx, sy) = world_to_screen cam pos in

  (* Only draw if on screen *)
  if sx >= -50 && sx <= Config.width + 50 &&
     sy >= -50 && sy <= Config.height + 50 then begin
    let radius = body_radius (Body.mass body) in

    (* Draw body with glow effect *)
    set_color color;
    fill_circle sx sy radius;

    (* Outer glow *)
    set_color (Graphics.rgb
      ((color lsr 16) land 0xFF)
      ((color lsr 8) land 0xFF)
      (color land 0xFF));
    draw_circle sx sy (radius + 1);
  end

(** Draw a label for a body *)
let draw_label (cam : camera) (body : Body.b) (name : string) : unit =
  let pos = Body.pos body in
  let (sx, sy) = world_to_screen cam pos in

  (* Only draw if on screen *)
  if sx >= -50 && sx <= Config.width + 50 &&
     sy >= -50 && sy <= Config.height + 50 then begin
    let radius = body_radius (Body.mass body) in

    (* Draw label slightly above and to the right of the body *)
    set_color white;
    moveto (sx + radius + 5) (sy + radius + 5);
    draw_string name;
  end

(** Draw trail for a body *)
let draw_trail (cam : camera) (trail : Vec3.v list) (color : int) : unit =
  let rec draw_segments points alpha =
    match points with
    | p1 :: p2 :: rest ->
        let (x1, y1) = world_to_screen cam p1 in
        let (x2, y2) = world_to_screen cam p2 in

        (* Fade trail based on age *)
        let r = ((color lsr 16) land 0xFF) in
        let g = ((color lsr 8) land 0xFF) in
        let b = (color land 0xFF) in
        let faded_color = Graphics.rgb
          (r * alpha / 255)
          (g * alpha / 255)
          (b * alpha / 255) in

        set_color faded_color;
        moveto x1 y1;
        lineto x2 y2;

        let new_alpha = if Config.trail_fade then alpha - 2 else alpha in
        draw_segments (p2 :: rest) new_alpha
    | _ -> ()
  in
  draw_segments trail 200

(** Draw UI overlay with information and controls *)
let draw_ui (st : state) (world_list : Body.b list) : unit =
  set_color (Graphics.rgb 240 240 240);

  (* Background panel *)
  fill_rect 10 (Config.height - 120) 280 110;

  set_color black;
  draw_rect 10 (Config.height - 120) 280 110;

  (* Draw text *)
  moveto 20 (Config.height - 30);
  draw_string (Printf.sprintf "Bodies: %d" (List.length world_list));

  moveto 20 (Config.height - 50);
  let days = st.time_elapsed /. (3600.0 *. 24.0) in
  let years = days /. 365.25 in
  draw_string (Printf.sprintf "Time: %.1f days (%.2f years)" days years);

  moveto 20 (Config.height - 70);
  draw_string (Printf.sprintf "Speed: %.1fx" st.speed);

  moveto 20 (Config.height - 90);
  draw_string (Printf.sprintf "Zoom: %.2e m/px" st.camera.zoom);

  moveto 20 (Config.height - 110);
  draw_string (if st.paused then "Status: PAUSED" else "Status: Running");

  (* Controls help *)
  set_color (Graphics.rgb 240 240 240);
  fill_rect 10 10 300 170;
  set_color black;
  draw_rect 10 10 300 170;

  moveto 20 165;
  draw_string "Controls:";
  moveto 20 145;
  draw_string "SPACE - Pause/Resume";
  moveto 20 125;
  draw_string "+/-   - Speed up/down";
  moveto 20 105;
  draw_string "Z/X   - Zoom in/out";
  moveto 20 85;
  draw_string "W/A/S/D - Pan camera (WASD)";
  moveto 20 65;
  draw_string "C       - Reset camera only";
  moveto 20 45;
  draw_string "R       - Reset simulation";
  moveto 20 25;
  draw_string "Q/ESC   - Quit"

(** Render the entire scene *)
let render (st : state) : unit =
  (* Clear screen with space background *)
  set_color (Graphics.rgb 10 10 25);
  fill_rect 0 0 Config.width Config.height;

  (* Draw grid for reference *)
  set_color (Graphics.rgb 30 30 50);
  let grid_spacing = 100 in
  for i = 0 to Config.width / grid_spacing do
    let x = i * grid_spacing in
    moveto x 0;
    lineto x Config.height;
  done;
  for i = 0 to Config.height / grid_spacing do
    let y = i * grid_spacing in
    moveto 0 y;
    lineto Config.width y;
  done;

  (* Convert world to list for iteration *)
  let world_list = st.world in

  (* Draw trails *)
  List.iteri (fun i trail ->
    if List.length trail > 1 then
      draw_trail st.camera trail (get_body_color i)
  ) st.trails;

  (* Draw bodies *)
  List.iteri (fun i body ->
    draw_body st.camera body (get_body_color i)
  ) world_list;

  (* Draw labels *)
  List.iteri (fun i body ->
    if i < Array.length planet_names then
      draw_label st.camera body planet_names.(i)
  ) world_list;

  (* Draw UI *)
  draw_ui st world_list;

  synchronize ()

(** Update trails with new positions *)
let update_trails (world : Engine.w) (old_trails : (Vec3.v list) list) : (Vec3.v list) list =
  List.map2 (fun body trail ->
    let new_pos = Body.pos body in
    let updated = new_pos :: trail in
    (* Limit trail length *)
    if List.length updated > Config.max_trail_length then
      List.rev (List.tl (List.rev updated))
    else
      updated
  ) world old_trails

(** Initialize trails *)
let init_trails (world : Engine.w) : (Vec3.v list) list =
  List.map (fun body -> [Body.pos body]) world

(** Handle keyboard input - returns (new_state option, reset_simulation) *)
let handle_input (st : state) : state option * bool =
  if key_pressed () then
    let key = read_key () in
    match key with
    | ' ' -> (Some { st with paused = not st.paused }, false)
    | '+' | '=' -> (Some { st with speed = st.speed *. 1.5 }, false)
    | '-' | '_' -> (Some { st with speed = st.speed /. 1.5 }, false)
    | 'z' | 'Z' ->
        (* Zoom IN - decrease zoom value (fewer meters per pixel) *)
        (Some { st with camera = { st.camera with zoom = st.camera.zoom *. 0.8 }}, false)
    | 'x' | 'X' ->
        (* Zoom OUT - increase zoom value (more meters per pixel) *)
        (Some { st with camera = { st.camera with zoom = st.camera.zoom *. 1.25 }}, false)
    | 'w' | 'W' ->
        (* Pan up *)
        let pan_amount = st.camera.zoom *. 50.0 in
        (Some { st with camera = { st.camera with offset_y = st.camera.offset_y +. pan_amount }}, false)
    | 's' | 'S' ->
        (* Pan down *)
        let pan_amount = st.camera.zoom *. 50.0 in
        (Some { st with camera = { st.camera with offset_y = st.camera.offset_y -. pan_amount }}, false)
    | 'a' | 'A' ->
        (* Pan left *)
        let pan_amount = st.camera.zoom *. 50.0 in
        (Some { st with camera = { st.camera with offset_x = st.camera.offset_x -. pan_amount }}, false)
    | 'd' | 'D' ->
        (* Pan right *)
        let pan_amount = st.camera.zoom *. 50.0 in
        (Some { st with camera = { st.camera with offset_x = st.camera.offset_x +. pan_amount }}, false)
    | 'r' | 'R' ->
        (* Full reset - restart simulation *)
        (None, true)
    | 'c' | 'C' ->
        (* Reset camera only *)
        (Some { st with camera = { zoom = 1e10; offset_x = 0.0; offset_y = 0.0 }}, false)
    | 'q' | 'Q' -> (None, false)  (* Quit *)
    | '\027' -> (* ESC - quit *)
        (None, false)
    | _ -> (Some st, false)
  else
    (Some st, false)

(** Main simulation loop *)
let rec loop (st : state) (initial_world : Engine.w) : unit =
  let start_time = Unix.gettimeofday () in

  (* Handle input *)
  match handle_input st with
  | (None, false) -> () (* Quit *)
  | (None, true) ->
      (* Full reset - restart with initial world *)
      let reset_state = {
        world = initial_world;
        camera = { zoom = 1e10; offset_x = 0.0; offset_y = 0.0 };
        paused = false;
        speed = 1.0;
        trails = init_trails initial_world;
        time_elapsed = 0.0;
      } in
      loop reset_state initial_world
  | (Some st, _) ->
      (* Update simulation if not paused *)
      let new_st =
        if st.paused then st
        else
          let dt = Config.default_dt *. st.speed in
          let new_world = Engine.step ~dt st.world in
          let new_trails = update_trails new_world st.trails in
          { st with
            world = new_world;
            trails = new_trails;
            time_elapsed = st.time_elapsed +. dt }
      in

      (* Render *)
      render new_st;

      (* Frame timing *)
      let elapsed = Unix.gettimeofday () -. start_time in
      let sleep_time = Config.frame_delay -. elapsed in
      if sleep_time > 0.0 then
        Unix.sleepf sleep_time;

      loop new_st initial_world

(** Create a simple solar system example *)
let create_solar_system () : Engine.w =
  let open Vec3 in

  (* Sun at center *)
  let sun = Body.make
    ~mass:1.989e30
    ~pos:(make 0.0 0.0 0.0)
    ~vel:(make 0.0 0.0 0.0) in

  (* Mercury *)
  let mercury_dist = 5.791e10 in
  let mercury_vel = 47870.0 in
  let mercury = Body.make
    ~mass:3.285e23
    ~pos:(make mercury_dist 0.0 0.0)
    ~vel:(make 0.0 mercury_vel 0.0) in

  (* Venus *)
  let venus_dist = 1.082e11 in
  let venus_vel = 35020.0 in
  let venus = Body.make
    ~mass:4.867e24
    ~pos:(make venus_dist 0.0 0.0)
    ~vel:(make 0.0 venus_vel 0.0) in

  (* Earth *)
  let earth_dist = 1.496e11 in (* 1 AU *)
  let earth_vel = 29780.0 in   (* ~30 km/s *)
  let earth = Body.make
    ~mass:5.972e24
    ~pos:(make earth_dist 0.0 0.0)
    ~vel:(make 0.0 earth_vel 0.0) in

  (* Mars *)
  let mars_dist = 2.279e11 in
  let mars_vel = 24070.0 in
  let mars = Body.make
    ~mass:6.417e23
    ~pos:(make mars_dist 0.0 0.0)
    ~vel:(make 0.0 mars_vel 0.0) in

  (* Jupiter *)
  let jupiter_dist = 7.785e11 in
  let jupiter_vel = 13070.0 in
  let jupiter = Body.make
    ~mass:1.898e27
    ~pos:(make jupiter_dist 0.0 0.0)
    ~vel:(make 0.0 jupiter_vel 0.0) in

  (* Saturn *)
  let saturn_dist = 1.432e12 in
  let saturn_vel = 9690.0 in
  let saturn = Body.make
    ~mass:5.683e26
    ~pos:(make saturn_dist 0.0 0.0)
    ~vel:(make 0.0 saturn_vel 0.0) in

  (* Uranus *)
  let uranus_dist = 2.867e12 in
  let uranus_vel = 6810.0 in
  let uranus = Body.make
    ~mass:8.681e25
    ~pos:(make uranus_dist 0.0 0.0)
    ~vel:(make 0.0 uranus_vel 0.0) in

  (* Neptune *)
  let neptune_dist = 4.515e12 in
  let neptune_vel = 5430.0 in
  let neptune = Body.make
    ~mass:1.024e26
    ~pos:(make neptune_dist 0.0 0.0)
    ~vel:(make 0.0 neptune_vel 0.0) in

  [sun; mercury; venus; earth; mars; jupiter; saturn; uranus; neptune]

(** Main entry point *)
let () =
  Printf.printf "Starting N-Body Physics Simulation...\n";
  Printf.printf "Initializing graphics...\n";

  (* Initialize graphics *)
  let window_spec = Printf.sprintf " %dx%d" Config.width Config.height in
  open_graph window_spec;
  set_window_title "N-Body Physics Simulation";
  auto_synchronize false;

  Printf.printf "Creating solar system...\n";

  (* Create initial world *)
  let initial_world = create_solar_system () in
  let initial_trails = init_trails initial_world in

  (* Initial camera (zoom level to see solar system) *)
  let initial_camera = {
    zoom = 1e10;      (* 10 million km per pixel - adjusted for solar system *)
    offset_x = 0.0;
    offset_y = 0.0;
  } in

  let initial_state = {
    world = initial_world;
    camera = initial_camera;
    paused = false;
    speed = 1.0;
    trails = initial_trails;
    time_elapsed = 0.0;
  } in

  Printf.printf "Starting simulation loop...\n";
  Printf.printf "Use controls shown in window to interact.\n";

  (* Run main loop *)
  loop initial_state initial_world;

  (* Cleanup *)
  close_graph ();
  Printf.printf "Simulation ended.\n"

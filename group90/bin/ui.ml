(**
   User Interface module - handles 2D overlay and UI interactions.

   Responsibilities:
   - Drawing the right sidebar control panel (x=600-800)
   - Rendering interactive sliders for planet density and radius
   - Displaying simulation status (speed, pause, collisions)
   - Providing control instructions and key bindings
   - Managing UI color palette
   - Handling mouse interactions (sliders, buttons)
   - Detecting mouse-over-sidebar to prevent camera control conflicts

   Used by simulation.ml to render UI and process UI interactions.
*)

open Raylib

(* Helper to create Raylib Color *)
let color r g b a = Color.create r g b a
let black = color 0 0 0 255
let white = color 255 255 255 255
let red = color 255 0 0 255
let gray = color 80 80 80 255
let dark_gray = color 40 40 40 255

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
let draw_ui is_colliding time_scale paused planet_params has_changes num_alive_planets current_scenario =
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

  (* No change notification needed - changes are always live *)

  (* Planet controls - always show all 3 *)
  let planet_colors = [
    ("Planet 1", color 255 200 100 255);
    ("Planet 2", color 100 150 255 255);
    ("Planet 3", color 255 100 100 255);
  ] in

  List.iteri (fun i (name, col) ->
    let (density, radius) = List.nth planet_params i in
    let base_y = 55 + i * 145 in
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
      draw_line (sidebar_x + 10) (base_y + 130) (sidebar_x + sidebar_width - 10) (base_y + 130) (color 50 60 80 255)
  ) planet_colors;

  (* Scenario info *)
  draw_line (sidebar_x + 10) 470 (sidebar_x + sidebar_width - 10) 470 (color 50 60 80 255);
  draw_text "SCENARIO" (sidebar_x + 15) 478 11 (color 150 180 255 255);
  (* Truncate scenario name if too long *)
  let scenario_display = if String.length current_scenario > 18 then
    String.sub current_scenario 0 15 ^ "..."
  else
    current_scenario
  in
  draw_text scenario_display (sidebar_x + 15) 493 10 white;
  draw_text "[1-6] Switch scenario" (sidebar_x + 15) 507 10 (color 180 180 200 255);
  draw_text "[R] Restart w/ sliders" (sidebar_x + 15) 520 10 (color 180 180 200 255);

  (* Bottom controls *)
  draw_line (sidebar_x + 10) 535 (sidebar_x + sidebar_width - 10) 535 (color 50 60 80 255);
  draw_text (Printf.sprintf "Speed: %.1fx" time_scale) (sidebar_x + 15) 543 12 white;
  draw_text "[Z] Faster  [X] Slower" (sidebar_x + 15) 560 10 (color 180 180 200 255);
  draw_text (if paused then "[P] Resume" else "[P] Pause") (sidebar_x + 15) 576 11 (color 180 180 200 255);

  (* Scenario list - bottom left *)
  draw_text "SCENARIOS" 15 360 11 (color 150 180 255 255);
  draw_text "[1] Three-Body" 15 378 9 (color 180 180 200 255);
  draw_text "[2] Randomized 3-Body" 15 392 8 (color 180 180 200 255);
  draw_text "[3] Binary Star" 15 406 9 (color 180 180 200 255);
  draw_text "[4] Solar System" 15 420 9 (color 180 180 200 255);
  draw_text "[5] Collision" 15 434 9 (color 180 180 200 255);
  draw_text "[6] Figure-8" 15 448 9 (color 180 180 200 255);

  (* Camera controls - bottom left *)
  draw_text "CAMERA" 15 480 11 (color 150 180 255 255);
  draw_text "Rotate: Drag" 15 498 10 (color 180 180 200 255);
  draw_text "Zoom: Wheel" 15 513 10 (color 180 180 200 255);

  (* Exit button - moved to left *)
  draw_rectangle 10 540 80 30 (color 180 50 50 255);
  draw_text "EXIT" 25 550 20 white;

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
    (* Y coordinate: button is at y=540-570 from top *)
    mouse_x >= 10 && mouse_x <= 90 && mouse_y >= 540 && mouse_y <= 570
  else false

(* Check if mouse is over sidebar *)
let mouse_over_sidebar () =
  let mouse_x = get_mouse_x () in
  mouse_x >= 600

(** User Interface module - handles 2D overlay and UI interactions.

    Responsibilities:
    - Drawing instructions box (bottom left)
    - Rendering collapsible sidebar for planet editing
    - Displaying simulation status
    - Managing UI color palette
    - Handling mouse interactions (sliders, buttons, planet selection)
    - Detecting mouse-over-UI to prevent camera control conflicts

    Used by simulation.ml to render UI and process UI interactions. *)

open Raylib

(* Helper to create Raylib Color *)
let color r g b a = Color.create r g b a
let black = color 0 0 0 255
let white = color 255 255 255 255
let red = color 255 0 0 255
let gray = color 80 80 80 255
let dark_gray = color 40 40 40 255

(* Get color for a body - converts Body.color tuple to Raylib Color *)
let body_color_to_raylib (r, g, b, a) =
  let clamp_to_byte x =
    int_of_float (Float.max 0. (Float.min 255. x))
  in
  color (clamp_to_byte r) (clamp_to_byte g) (clamp_to_byte b) (clamp_to_byte a)

(* Get color for a body based on the body itself *)
let get_body_color_from_body body =
  let c = Group90.Body.color body in
  body_color_to_raylib c

(* Fallback: Get color for a body based on index (for when body isn't available) *)
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

(* Conversion functions between UI scale (1-20) and actual values *)
(* Density: map 1-20 to 1e9-1e11 *)
let density_to_ui_scale density =
  let min_density = 1e9 in
  let max_density = 1e11 in
  let normalized = (density -. min_density) /. (max_density -. min_density) in
  1.0 +. (normalized *. 19.0)

let ui_scale_to_density ui_value =
  let min_density = 1e9 in
  let max_density = 1e11 in
  let normalized = (ui_value -. 1.0) /. 19.0 in
  min_density +. (normalized *. (max_density -. min_density))

(* Radius: map 1-20 to 10-40 *)
let radius_to_ui_scale radius =
  let min_radius = 10.0 in
  let max_radius = 40.0 in
  let normalized = (radius -. min_radius) /. (max_radius -. min_radius) in
  1.0 +. (normalized *. 19.0)

let ui_scale_to_radius ui_value =
  let min_radius = 10.0 in
  let max_radius = 40.0 in
  let normalized = (ui_value -. 1.0) /. 19.0 in
  min_radius +. (normalized *. (max_radius -. min_radius))

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
  draw_rectangle (x + filled_width) (y + 3) (width - filled_width) slider_height
    (color 40 45 60 255);

  (* Handle *)
  draw_circle handle_x (y + 6) handle_size (color 120 140 200 255);
  draw_circle handle_x (y + 6) (handle_size -. 2.) (color 200 220 255 255);

  (* Label and value *)
  draw_text label x (y - 18) 12 (color 200 200 220 255);
  (* Display value as simple number (1 decimal place) *)
  let value_str = Printf.sprintf "%.1f" value in
  draw_text value_str (x + width + 10) (y - 2) 10 white

let check_slider_drag x y width min_val max_val =
  if is_mouse_button_down MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in

    if
      mouse_y >= y - 10
      && mouse_y <= y + 16
      && mouse_x >= x
      && mouse_x <= x + width
    then
      let normalized = float_of_int (mouse_x - x) /. float_of_int width in
      let clamped = Float.max 0. (Float.min 1. normalized) in
      Some (min_val +. (clamped *. (max_val -. min_val)))
    else None
  else None

(* Draw instructions box - bottom left *)
let draw_instructions time_scale paused current_scenario =
  let box_x = 10 in
  let box_y = 360 in
  let box_width = 180 in
  let box_height = 180 in

  (* Draw instructions background *)
  draw_rectangle box_x box_y box_width box_height (color 20 25 35 230);
  draw_rectangle box_x box_y 3 box_height (color 80 100 140 255);

  (* Scenario info at top *)
  draw_text "SCENARIO" (box_x + 10) (box_y + 10) 11 (color 150 180 255 255);
  let scenario_display =
    if String.length current_scenario > 18 then
      String.sub current_scenario 0 15 ^ "..."
    else current_scenario
  in
  draw_text scenario_display (box_x + 10) (box_y + 25) 9 white;
  draw_line (box_x + 5) (box_y + 40) (box_x + box_width - 5) (box_y + 40)
    (color 50 60 80 255);

  (* Scenario list *)
  draw_text "[1] Three-Body" (box_x + 10) (box_y + 48) 8
    (color 180 180 200 255);
  draw_text "[2] Randomized" (box_x + 10) (box_y + 60) 8
    (color 180 180 200 255);
  draw_text "[3] Binary Star" (box_x + 10) (box_y + 72) 8
    (color 180 180 200 255);
  draw_text "[4] Solar System" (box_x + 10) (box_y + 84) 8
    (color 180 180 200 255);
  draw_text "[5] Collision" (box_x + 10) (box_y + 96) 8
    (color 180 180 200 255);
  draw_text "[R] Restart" (box_x + 10) (box_y + 108) 8
    (color 180 180 200 255);

  draw_line (box_x + 5) (box_y + 132) (box_x + box_width - 5) (box_y + 132)
    (color 50 60 80 255);

  (* Controls *)
  draw_text
    (Printf.sprintf "Speed: %.1fx" time_scale)
    (box_x + 10) (box_y + 140) 10 white;
  draw_text "[Z/X] Speed" (box_x + 10) (box_y + 153) 8
    (color 180 180 200 255);
  draw_text
    (if paused then "[P] Resume" else "[P] Pause")
    (box_x + 10) (box_y + 165) 9 (color 180 180 200 255);
  ()

(* Draw planet sidebar *)
let draw_sidebar selected_planet_idx planet_params world num_alive =
  let sidebar_x = 560 in
  let sidebar_y = 50 in
  let sidebar_width = 230 in
  let sidebar_height = 250 in

  (* Draw sidebar background *)
  draw_rectangle sidebar_x sidebar_y sidebar_width sidebar_height
    (color 20 25 35 240);
  draw_rectangle sidebar_x sidebar_y 3 sidebar_height (color 80 100 140 255);

  (* Get current planet info *)
  let density, radius =
    if selected_planet_idx < List.length planet_params then
      List.nth planet_params selected_planet_idx
    else (3e10, 18.)
  in
  let planet_col =
    if selected_planet_idx < List.length world then
      get_body_color_from_body (List.nth world selected_planet_idx)
    else get_body_color selected_planet_idx
  in
  let is_merged = selected_planet_idx >= num_alive in

  (* Header with close button *)
  draw_text "Selected Planet" (sidebar_x + 15) (sidebar_y + 10) 12
    (color 150 180 255 255);

  (* Close button (X) *)
  let close_btn_x = sidebar_x + sidebar_width - 25 in
  let close_btn_y = sidebar_y + 8 in
  draw_rectangle close_btn_x close_btn_y 18 18 (color 180 50 50 255);
  draw_text "X" (close_btn_x + 5) (close_btn_y + 2) 14 white;

  draw_line (sidebar_x + 10) (sidebar_y + 32)
    (sidebar_x + sidebar_width - 10)
    (sidebar_y + 32) (color 80 100 140 255);

  (* Planet selector with arrows *)
  let selector_y = sidebar_y + 45 in

  (* Left arrow *)
  draw_rectangle (sidebar_x + 15) selector_y 25 25 (color 60 70 90 255);
  draw_text "<" (sidebar_x + 23) (selector_y + 5) 16 white;

  (* Planet circle and name *)
  let planet_name =
    Printf.sprintf "Planet %d" (selected_planet_idx + 1)
    ^ if is_merged then " (merged)" else ""
  in
  draw_circle (sidebar_x + 70) (selector_y + 12) 10. planet_col;
  draw_text planet_name (sidebar_x + 85) (selector_y + 5) 11 white;

  (* Right arrow *)
  draw_rectangle (sidebar_x + sidebar_width - 40) selector_y 25 25
    (color 60 70 90 255);
  draw_text ">" (sidebar_x + sidebar_width - 32) (selector_y + 5) 16 white;

  (* Sliders *)
  let slider_start_y = sidebar_y + 90 in

  (* Convert actual values to UI scale (1-20) *)
  let density_ui = density_to_ui_scale density in
  let radius_ui = radius_to_ui_scale radius in

  (* Density slider *)
  draw_slider (sidebar_x + 20) slider_start_y 130 density_ui 1. 20. "Density";

  (* Radius slider *)
  draw_slider (sidebar_x + 20) (slider_start_y + 70) 130 radius_ui 1. 20.
    "Radius";

  (* Info text *)
  draw_text "Drag sliders to adjust" (sidebar_x + 20) (sidebar_y + 215) 8
    (color 150 150 170 255);
  draw_text "Click planets to select" (sidebar_x + 20) (sidebar_y + 227) 8
    (color 150 150 170 255);
  ()

(* Draw 2D UI overlay *)
let draw_ui is_colliding time_scale paused planet_params has_changes
    num_alive_planets current_scenario world sidebar_visible selected_planet =
  (* Instructions box - bottom left *)
  draw_instructions time_scale paused current_scenario;

  (* Exit button - top left *)
  draw_rectangle 10 10 70 25 (color 180 50 50 255);
  draw_text "EXIT" 22 15 16 white;

  (* Collision warning *)
  if is_colliding then begin
    draw_rectangle 250 560 150 30 red;
    draw_text "COLLISION!" 260 570 18 white
  end;

  (* Draw sidebar if visible *)
  if sidebar_visible then
    draw_sidebar selected_planet planet_params world num_alive_planets

(* Check if exit button is clicked *)
let check_exit_button () =
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in
    mouse_x >= 10 && mouse_x <= 80 && mouse_y >= 10 && mouse_y <= 35
  else false

(* Check if sidebar close button is clicked *)
let check_sidebar_close_button () =
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in
    let close_btn_x = 560 + 230 - 25 in
    let close_btn_y = 50 + 8 in
    mouse_x >= close_btn_x
    && mouse_x <= close_btn_x + 18
    && mouse_y >= close_btn_y
    && mouse_y <= close_btn_y + 18
  else false

(* Check if left arrow is clicked *)
let check_left_arrow () =
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in
    let arrow_x = 560 + 15 in
    let arrow_y = 50 + 45 in
    mouse_x >= arrow_x
    && mouse_x <= arrow_x + 25
    && mouse_y >= arrow_y
    && mouse_y <= arrow_y + 25
  else false

(* Check if right arrow is clicked *)
let check_right_arrow () =
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_x = get_mouse_x () in
    let mouse_y = get_mouse_y () in
    let arrow_x = 560 + 230 - 40 in
    let arrow_y = 50 + 45 in
    mouse_x >= arrow_x
    && mouse_x <= arrow_x + 25
    && mouse_y >= arrow_y
    && mouse_y <= arrow_y + 25
  else false

(* Check if mouse is over any UI element *)
let mouse_over_ui sidebar_visible =
  let mouse_x = get_mouse_x () in
  let mouse_y = get_mouse_y () in

  (* Instructions box *)
  let over_instructions =
    mouse_x >= 10 && mouse_x <= 190 && mouse_y >= 360 && mouse_y <= 540
  in

  (* Exit button *)
  let over_exit = mouse_x >= 10 && mouse_x <= 80 && mouse_y >= 10 && mouse_y <= 35 in

  (* Sidebar *)
  let over_sidebar =
    if sidebar_visible then
      mouse_x >= 560 && mouse_x <= 790 && mouse_y >= 50 && mouse_y <= 300
    else false
  in

  over_instructions || over_exit || over_sidebar

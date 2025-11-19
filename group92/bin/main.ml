open Graphics
open Group92

(* Unit scaling for GUI visualization *)
(*
   The engine uses the real gravitational constant G = 6.67e-11 m³/(kg·s²)
   To make this work with pixel coordinates, we scale the masses:

   Scale factor = 1.5e13 (to make G*scaled_mass behave like G_effective = 1000)
   This means: 1 simulation mass unit ≈ 1.5e13 kg in "real" units

   With this scaling:
   - Positions are in pixels (treat as "meters" for physics)
   - Velocities are in pixels/second
   - Masses are scaled up by the factor below
*)
let create_system () =
  (* Mass scaling factor to make real G work with pixel coordinates *)
  let g_real = 6.67e-11 in
  let g_effective = 1000. in (* desired effective G for visible orbits *)
  let mass_scale = g_effective /. g_real in

  (* Display masses (what we conceptually think of) *)
  let mass1_display = 1000. in
  let mass2_display = 100. in

  (* Scaled masses for physics engine *)
  let mass1 = mass1_display *. mass_scale in
  let mass2 = mass2_display *. mass_scale in

  let separation = 300. in (* pixels *)

  (* Center of mass at screen center (400, 300) *)
  let com_x = 400. in
  let com_y = 300. in

  (* Distances from center of mass (using display masses for ratio) *)
  let r1 = separation *. mass2_display /. (mass1_display +. mass2_display) in
  let r2 = separation *. mass1_display /. (mass1_display +. mass2_display) in

  (* Calculate orbital velocities using real G with scaled masses *)
  let total_mass = mass1 +. mass2 in
  let v_rel = Float.sqrt (g_real *. total_mass /. separation) in
  let v1 = v_rel *. mass2 /. total_mass in
  let v2 = v_rel *. mass1 /. total_mass in

  (* Large mass - closer to center *)
  let body1 =
    Body.make ~mass:mass1
      ~pos:(Vec3.make (com_x -. r1) com_y 0.)
      ~vel:(Vec3.make 0. v1 0.)
  in
  (* Smaller mass - farther from center *)
  let body2 =
    Body.make ~mass:mass2
      ~pos:(Vec3.make (com_x +. r2) com_y 0.)
      ~vel:(Vec3.make 0. (-.v2) 0.)
  in
  [ body1; body2 ]

let draw_body body color radius =
  let pos = Body.pos body in
  let x = int_of_float (Vec3.x pos) in
  let y = int_of_float (Vec3.y pos) in
  set_color color;
  fill_circle x y radius

let rec simulation_loop world =
  (* Clear screen *)
  set_color black;
  fill_rect 0 0 800 600;

  (* Draw exit button *)
  set_color (rgb 80 80 80);
  fill_rect 10 560 80 30;
  set_color white;
  moveto 25 570;
  draw_string "EXIT";

  (* Draw the 2 bodies *)
  draw_body (List.nth world 0) (rgb 255 200 100) 20;
  draw_body (List.nth world 1) (rgb 100 150 255) 12;

  synchronize ();

  (* Update physics *)
  let new_world = Engine.step ~dt:0.1 world in

  (* Check for exit *)
  if button_down () then begin
    let x, y = mouse_pos () in
    if x >= 10 && x <= 90 && y >= 560 && y <= 590 then ()
    else begin
      Unix.sleepf 0.016;
      simulation_loop new_world
    end
  end
  else begin
    Unix.sleepf 0.016;
    simulation_loop new_world
  end

let () =
  open_graph " 800x600";
  set_window_title "2-Body Gravity";
  auto_synchronize false;

  let world = create_system () in
  simulation_loop world;

  close_graph ()

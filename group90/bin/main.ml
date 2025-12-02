open Graphics
open Group90
open Unix (* Make sure to open Unix for sleep/sleepf functions *)

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
let create_system () =
  (* Masses *)
  let g = 6.67e-11 in
  let mass1 = 1000. *. (1. /. g) in
  let mass2 = 100. *. (1. /. g) in
  let mass3 = 200. *. (1. /. g) in

  let separation = 300. in
  (* pixels *)

  (* Center of mass at screen center (400, 300) *)
  let com_x = 400. in
  let com_y = 300. in

  (* Distances from center of mass *)
  let r1 = separation *. mass2 /. (mass1 +. mass2) in
  let r2 = separation *. mass1 /. (mass1 +. mass2) in

  (* Calculate orbital velocities using G from engine *)
  let total_mass = mass1 +. mass2 in
  let v_rel = Float.sqrt (g *. total_mass /. separation) in
  let v1 = v_rel *. mass2 /. total_mass in
  let v2 = v_rel *. mass1 /. total_mass in

  (* Large mass - closer to center *)
  let body1 =
    Body.make ~mass:mass1
      ~pos:(Vec3.make (com_x -. r1) com_y 0.)
      ~vel:(Vec3.make 0. v1 0.) ~radius:20.
  in
  (* Smaller mass - farther from center *)
  let body2 =
    Body.make ~mass:mass2
      ~pos:(Vec3.make (com_x +. r2) com_y 0.)
      ~vel:(Vec3.make 0. (-.v2) 0.) ~radius:12.
  in
  (* Third body on collision course with body2 *)
  let body3 =
    Body.make ~mass:mass3
      ~pos:(Vec3.make (com_x +. r2 +. 150.) com_y 0.) (* start to the right *)
      ~vel:(Vec3.make (-2.) 0. 0.) (* moving left toward body2 *)
      ~radius:8.
  in
  [ body1; body2; body3 ]

let draw_body body color radius =
  let pos = Body.pos body in
  let x = int_of_float (Vec3.x pos) in
  let y = int_of_float (Vec3.y pos) in
  set_color color;
  fill_circle x y radius

let rec simulation_loop world dt paused =
  (* Clear screen *)
  set_color black;
  fill_rect 0 0 800 600;

  (* Update physics only if not paused *)
  let new_world = if paused then world else Engine.step ~dt world in

  (* Check for collisions in the NEW world state *)
  let collisions = Engine.find_collisions new_world in
  let is_colliding = List.length collisions > 0 in

  (* Draw exit button *)
  set_color (rgb 80 80 80);
  fill_rect 10 560 80 30;
  set_color white;
  moveto 25 570;
  draw_string "EXIT";

  (* Draw collision warning BEFORE synchronize *)
  if is_colliding then begin
    set_color red;
    fill_rect 300 560 200 30;
    (* background for visibility *)
    set_color white;
    moveto 310 570;
    draw_string "COLLISION!"
  end;

  (* Draw speed info *)
  moveto 650 570;
  draw_string (Printf.sprintf "Speed: %.1fx" dt);
  moveto 630 550;
  draw_string "Z: faster | X: slower";
  moveto 630 530;
  draw_string (if paused then "P: unpause" else "P: pause");

  (* Draw the 3 bodies *)
  draw_body (List.nth new_world 0) (rgb 255 200 100) 20;
  draw_body (List.nth new_world 1) (rgb 100 150 255) 12;
  draw_body (List.nth new_world 2) (rgb 255 100 100) 8;

  synchronize ();

  (* Check for key presses to adjust simulation speed *)
  let new_dt, new_paused =
    if key_pressed () then
      match read_key () with
      | 'z' | 'Z' -> (min (dt *. 1.5) 100.0, paused)
      | 'x' | 'X' -> (max (dt /. 1.5) 0.1, paused)
      | 'p' | 'P' -> (dt, not paused)
      | _ -> (dt, paused)
    else (dt, paused)
  in

  let should_exit =
    if button_down () then
      let x, y = mouse_pos () in
      x >= 10 && x <= 90 && y >= 560 && y <= 590
    else false
  in

  if should_exit then ()
  else begin
    Unix.sleepf 0.016;
    simulation_loop new_world new_dt new_paused
  end

let () =
  open_graph " 800x600";
  set_window_title "2-Body Gravity";
  auto_synchronize false;

  simulation_loop (create_system ()) 2.0 false;

  set_color black;
  fill_rect 0 0 800 600;

  moveto 100 300;
  set_color white;
  draw_string "Simulation Closed by User. Press any key to exit program.";
  synchronize ();

  ignore (read_key ());
  close_graph ()

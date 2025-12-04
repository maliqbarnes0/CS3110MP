open Raylib
open Group90

(* Render scale: physics coordinates to visual coordinates *)
let render_scale = 0.1 (* 1 physics unit = 0.1 render units *)

(* Trail configuration *)
let max_trail_length = 120 (* Number of positions to keep in trail *)

(* Trail type: list of Vec3 positions for each body *)
type trails = Vec3.v list list

(* Collision animation type *)
type collision_animation = {
  position : Vec3.v;
  start_time : float;
  duration : float;
  max_radius : float;
  color : Color.t;
}

type collision_animations = collision_animation list

(* Generate stars once at initialization *)
let stars = ref []

let initialize_stars () =
  Random.self_init ();
  stars :=
    List.init 400 (fun _ ->
        let theta = Random.float (2. *. Float.pi) in
        let phi = Random.float Float.pi -. (Float.pi /. 2.) in
        (* Stars between 800 and 1200 units away *)
        let radius = 800. +. Random.float 400. in

        let x = radius *. Float.cos phi *. Float.cos theta in
        let y = radius *. Float.sin phi in
        let z = radius *. Float.cos phi *. Float.sin theta in

        let brightness = 200 + Random.int 56 in
        let size = 1.5 +. Random.float 2.0 in

        (x, y, z, brightness, size))

let draw_starbox camera =
  let cam_pos = Camera3D.position camera in

  (* Draw the starbox - stars follow camera *)
  List.iter
    (fun (x, y, z, brightness, size) ->
      let star_pos =
        Vector3.create
          (Vector3.x cam_pos +. x)
          (Vector3.y cam_pos +. y)
          (Vector3.z cam_pos +. z)
      in

      let star_color = Ui.color brightness brightness 255 255 in
      draw_sphere star_pos size star_color)
    !stars

let draw_infinite_grid camera =
  let cam_pos = Camera3D.position camera in
  let cam_x = Vector3.x cam_pos in
  let cam_z = Vector3.z cam_pos in

  let grid_spacing = 50. in
  let grid_center_x = Float.round (cam_x /. grid_spacing) *. grid_spacing in
  let grid_center_z = Float.round (cam_z /. grid_spacing) *. grid_spacing in

  let visible_range = 800. in
  let num_lines = 20 in

  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in

    let dist = Float.abs offset in
    let fade = Float.max 0. (1. -. (dist /. visible_range)) in
    let alpha = int_of_float (fade *. 50.) in

    if alpha > 5 then begin
      let grid_color = Ui.color 30 30 50 alpha in

      let start_x =
        Vector3.create
          (grid_center_x -. visible_range)
          0. (grid_center_z +. offset)
      in
      let end_x =
        Vector3.create
          (grid_center_x +. visible_range)
          0. (grid_center_z +. offset)
      in
      draw_line_3d start_x end_x grid_color;

      let start_z =
        Vector3.create (grid_center_x +. offset) 0.
          (grid_center_z -. visible_range)
      in
      let end_z =
        Vector3.create (grid_center_x +. offset) 0.
          (grid_center_z +. visible_range)
      in
      draw_line_3d start_z end_z grid_color
    end
  done

let draw_body body body_color =
  let pos = Body.pos body in
  let radius = Body.radius body *. render_scale in
  let position =
    Vector3.create
      (render_scale *. Vec3.x pos)
      (render_scale *. Vec3.y pos)
      (render_scale *. Vec3.z pos)
  in
  draw_sphere position radius body_color

(* Draw trail for a single body *)
let draw_trail trail trail_color =
  let rec draw_segments = function
    | [] | [ _ ] -> ()
    | p1 :: p2 :: rest ->
        let pos1 =
          Vector3.create
            (render_scale *. Vec3.x p1)
            (render_scale *. Vec3.y p1)
            (render_scale *. Vec3.z p1)
        in
        let pos2 =
          Vector3.create
            (render_scale *. Vec3.x p2)
            (render_scale *. Vec3.y p2)
            (render_scale *. Vec3.z p2)
        in
        (* Draw thicker lines by drawing small spheres at each position *)
        draw_sphere pos1 (1.5 *. render_scale) trail_color;
        draw_line_3d pos1 pos2 trail_color;
        draw_segments (p2 :: rest)
  in
  draw_segments trail

(* Update trails with new positions, return (new_trails, collision_pairs) *)
let update_trails trails world collision_pairs =
  (* Rebuild trails when world size changes, and return collision pairs *)
  if List.length trails <> List.length world then
    (* Create empty trails for current world *)
    let new_trails = List.map (fun body -> [ Body.pos body ]) world in
    (new_trails, collision_pairs)
  else
    let new_trails =
      List.map2
        (fun trail body ->
          let pos = Body.pos body in
          let new_trail = pos :: trail in
          (* Keep only the last max_trail_length positions *)
          if List.length new_trail > max_trail_length then
            List.rev (List.tl (List.rev new_trail))
          else new_trail)
        trails world
    in
    (new_trails, collision_pairs)

(* Draw collision animation as simple expanding burst *)
let draw_collision_animation anim current_time =
  let elapsed = current_time -. anim.start_time in
  if elapsed < anim.duration then begin
    let progress = elapsed /. anim.duration in
    let pos =
      Vector3.create
        (render_scale *. Vec3.x anim.position)
        (render_scale *. Vec3.y anim.position)
        (render_scale *. Vec3.z anim.position)
    in

    (* Get color components *)
    let r = Color.r anim.color in
    let g = Color.g anim.color in
    let b = Color.b anim.color in

    (* Single expanding sphere that fades out *)
    let alpha = int_of_float (255. *. (1. -. progress)) in
    let radius = anim.max_radius *. progress *. render_scale in

    if alpha > 0 && radius > 0. then
      draw_sphere pos radius (Ui.color r g b alpha)
  end

(* Update collision animations, removing expired ones *)
let update_collision_animations anims current_time =
  List.filter
    (fun anim -> current_time -. anim.start_time < anim.duration)
    anims

(* Draw 3D axis indicators and grid planes at origin *)
let draw_axes () =
  let axis_length = 150. in
  let grid_size = 400. in
  let grid_spacing = 50. in
  let grid_color = Ui.color 40 40 40 255 in

  (* Main axis lines - brighter *)
  (* X axis - Red *)
  let x_start = Vector3.create (-.axis_length) 0. 0. in
  let x_end = Vector3.create axis_length 0. 0. in
  draw_line_3d x_start x_end (Ui.color 255 80 80 255);

  (* Y axis - Green *)
  let y_start = Vector3.create 0. (-.axis_length) 0. in
  let y_end = Vector3.create 0. axis_length 0. in
  draw_line_3d y_start y_end (Ui.color 80 255 80 255);

  (* Z axis - Blue *)
  let z_start = Vector3.create 0. 0. (-.axis_length) in
  let z_end = Vector3.create 0. 0. axis_length in
  draw_line_3d z_start z_end (Ui.color 80 80 255 255);

  (* Grid lines on YZ plane (X = 0) *)
  let num_lines = int_of_float (grid_size /. grid_spacing) in
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Horizontal lines (parallel to Z) *)
    let start_z = Vector3.create 0. offset (-.grid_size /. 2.) in
    let end_z = Vector3.create 0. offset (grid_size /. 2.) in
    draw_line_3d start_z end_z grid_color;
    (* Vertical lines (parallel to Y) *)
    let start_y = Vector3.create 0. (-.grid_size /. 2.) offset in
    let end_y = Vector3.create 0. (grid_size /. 2.) offset in
    draw_line_3d start_y end_y grid_color
  done;

  (* Grid lines on XZ plane (Y = 0) *)
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Lines parallel to X *)
    let start_x = Vector3.create (-.grid_size /. 2.) 0. offset in
    let end_x = Vector3.create (grid_size /. 2.) 0. offset in
    draw_line_3d start_x end_x grid_color;
    (* Lines parallel to Z *)
    let start_z = Vector3.create offset 0. (-.grid_size /. 2.) in
    let end_z = Vector3.create offset 0. (grid_size /. 2.) in
    draw_line_3d start_z end_z grid_color
  done;

  (* Grid lines on XY plane (Z = 0) *)
  for i = -num_lines to num_lines do
    let offset = float_of_int i *. grid_spacing in
    (* Lines parallel to X *)
    let start_x = Vector3.create (-.grid_size /. 2.) offset 0. in
    let end_x = Vector3.create (grid_size /. 2.) offset 0. in
    draw_line_3d start_x end_x grid_color;
    (* Lines parallel to Y *)
    let start_y = Vector3.create offset (-.grid_size /. 2.) 0. in
    let end_y = Vector3.create offset (grid_size /. 2.) 0. in
    draw_line_3d start_y end_y grid_color
  done

(* Calculate collision point between two bodies *)
let calc_collision_point b1 b2 =
  let pos1 = Body.pos b1 in
  let pos2 = Body.pos b2 in
  let r1 = Body.radius b1 in
  let r2 = Body.radius b2 in
  (* Calculate collision point: weighted by radii to be on the surface where
     they touch *)
  let total_r = r1 +. r2 in
  let weight1 = r1 /. total_r in
  let weight2 = r2 /. total_r in
  Vec3.((weight2 *~ pos1) + (weight1 *~ pos2))

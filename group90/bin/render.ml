open Raylib
open Group90

let render_scale = 0.1

(* Trail configuration *)
let max_trail_length = 120 (* Number of positions to keep in trail *)

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

  (* Draw the starbox *)
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

(* Calculate collision point between two bodies *)
let calc_collision_point b1 b2 =
  let pos1 = Body.pos b1 in
  let pos2 = Body.pos b2 in
  let r1 = Body.radius b1 in
  let r2 = Body.radius b2 in
  let total_r = r1 +. r2 in
  let weight1 = r1 /. total_r in
  let weight2 = r2 /. total_r in
  Vec3.((weight2 *~ pos1) + (weight1 *~ pos2))

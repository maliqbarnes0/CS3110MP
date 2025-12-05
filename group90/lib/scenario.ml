(** Scenario module - handles creation of different physics scenarios.

    This module provides functions for creating various celestial body
    configurations for simulation. *)

type scenario = {
  name : string;
  description : string;
  bodies : Body.b list;
  recommended_camera : float * float * float; (* theta, phi, radius *)
}

(** Gravitational constant *)
let g = 6.67e-11

(** Calculate mass from density and radius *)
let calculate_mass ~density ~radius =
  let volume = 4.0 /. 3.0 *. Float.pi *. (radius ** 3.0) in
  density *. volume

(** Create a three-body orbital system with custom parameters. Parameters:
    (density1, radius1, density2, radius2, density3, radius3) *)
let create_three_body_system ?(custom_params = None) () =
  (* Default densities and radii - deterministic *)
  let default_density1 = 3.5747e10 in
  let default_radius1 = 20. in
  let default_density2 = 2.6810e10 in
  let default_radius2 = 18. in
  let default_density3 = 1.7873e10 in
  let default_radius3 = 16. in

  (* Use custom params if provided, otherwise use defaults *)
  let density1, radius1, density2, radius2, density3, radius3 =
    match custom_params with
    | Some params -> params
    | None ->
        ( default_density1,
          default_radius1,
          default_density2,
          default_radius2,
          default_density3,
          default_radius3 )
  in

  (* Calculate masses from density and radius *)
  let mass1 = calculate_mass ~density:density1 ~radius:radius1 in
  let mass2 = calculate_mass ~density:density2 ~radius:radius2 in
  let _mass3 = calculate_mass ~density:density3 ~radius:radius3 in

  (* Separation for binary pair *)
  let separation = 120. in

  (* Center of mass at origin *)
  let com_x = 0. in
  let com_y = 0. in
  let com_z = 0. in

  (* Distances from center of mass for binary pair *)
  let r1 = separation *. mass2 /. (mass1 +. mass2) in
  let r2 = separation *. mass1 /. (mass1 +. mass2) in

  (* Calculate orbital velocities for binary pair *)
  let total_mass = mass1 +. mass2 in
  let v_rel = Float.sqrt (g *. total_mass /. separation) in
  let v1 = v_rel *. mass2 /. total_mass in
  let v2 = v_rel *. mass1 /. total_mass in

  (* Body 1 - Heavy star orbiting in YZ plane - Vibrant Red *)
  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make com_x (com_y -. r1) com_z)
      ~vel:(Vec3.make 0. 0. v1) ~radius:radius1 ~color:(255., 60., 60., 255.)
  in
  (* Body 2 - Medium companion orbiting opposite direction - Vibrant Green *)
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make com_x (com_y +. r2) com_z)
      ~vel:(Vec3.make 0. 0. (-.v2)) ~radius:radius2 ~color:(60., 255., 60., 255.)
  in
  (* Body 3 - Interloper approaching at an angle - Vibrant Blue *)
  let body3 =
    Body.make ~density:density3 ~pos:(Vec3.make 180. 60. 100.)
      ~vel:(Vec3.make (-1.0) (-0.4) (-0.6))
      ~radius:radius3 ~color:(60., 60., 255., 255.)
  in
  [ body1; body2; body3 ]

(** Create randomized three-body system *)
let create_randomized_three_body () =
  let rand_range min max = min +. Random.float (max -. min) in

  (* Generate density and radius - use lower densities for more stable orbits *)
  (* Density range: 1e9 to 5e10 (instead of 1e11) to reduce mass and gravitational pull *)
  let density1 = rand_range 1e9 5e10 in
  let density2 = rand_range 1e9 5e10 in
  let density3 = rand_range 1e9 5e10 in

  (* Use smaller radii on average to reduce collision cross-section *)
  let radius1 = rand_range 12. 25. in
  let radius2 = rand_range 12. 25. in
  let radius3 = rand_range 12. 25. in

  (* Use spherical coordinates to ensure good separation *)
  (* Planet 1: Random angle and distance from origin *)
  let angle1 = rand_range 0. (2. *. Float.pi) in
  let distance1 = rand_range 100. 180. in
  let height1 = rand_range (-40.) 40. in
  let pos1_x = distance1 *. Float.cos angle1 in
  let pos1_y = height1 in
  let pos1_z = distance1 *. Float.sin angle1 in

  (* Planet 2: Different angle, ensure separation from planet 1 *)
  let angle2 = angle1 +. rand_range (2. *. Float.pi /. 3.) (4. *. Float.pi /. 3.) in
  let distance2 = rand_range 100. 180. in
  let height2 = rand_range (-40.) 40. in
  let pos2_x = distance2 *. Float.cos angle2 in
  let pos2_y = height2 in
  let pos2_z = distance2 *. Float.sin angle2 in

  (* Planet 3: Another different angle, separated from both *)
  let angle3 = angle2 +. rand_range (2. *. Float.pi /. 3.) (4. *. Float.pi /. 3.) in
  let distance3 = rand_range 120. 220. in
  let height3 = rand_range (-50.) 50. in
  let pos3_x = distance3 *. Float.cos angle3 in
  let pos3_y = height3 in
  let pos3_z = distance3 *. Float.sin angle3 in

  (* Generate random velocities with variety in direction and magnitude *)
  let speed_range_max = 12.0 in
  let vel1_x = rand_range (-.speed_range_max) speed_range_max in
  let vel1_y = rand_range (-.speed_range_max) speed_range_max in
  let vel1_z = rand_range (-.speed_range_max) speed_range_max in
  let vel2_x = rand_range (-.speed_range_max) speed_range_max in
  let vel2_y = rand_range (-.speed_range_max) speed_range_max in
  let vel2_z = rand_range (-.speed_range_max) speed_range_max in
  let vel3_x = rand_range (-.speed_range_max) speed_range_max in
  let vel3_y = rand_range (-.speed_range_max) speed_range_max in
  let vel3_z = rand_range (-.speed_range_max) speed_range_max in

  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make pos1_x pos1_y pos1_z)
      ~vel:(Vec3.make vel1_x vel1_y vel1_z)
      ~radius:radius1 ~color:(0., 255., 255., 255.)
    (* Cyan *)
  in
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make pos2_x pos2_y pos2_z)
      ~vel:(Vec3.make vel2_x vel2_y vel2_z)
      ~radius:radius2 ~color:(255., 0., 255., 255.)
    (* Magenta *)
  in
  let body3 =
    Body.make ~density:density3
      ~pos:(Vec3.make pos3_x pos3_y pos3_z)
      ~vel:(Vec3.make vel3_x vel3_y vel3_z)
      ~radius:radius3 ~color:(255., 255., 0., 255.)
    (* Yellow *)
  in
  [ body1; body2; body3 ]

(** Randomized three-body scenario *)
let randomized_three_body_scenario () =
  {
    name = "Randomized 3-Body";
    description = "Three bodies with random masses, positions, and velocities";
    bodies = create_randomized_three_body ();
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Create default three-body scenario *)
let default_scenario () =
  {
    name = "Three-Body Problem";
    description = "A binary star system with an interloping third body";
    bodies = create_three_body_system ();
    recommended_camera = (0.0, 0.0, 400.0);
    (* theta, phi, radius *)
  }

(** Create a scenario from custom planet parameters *)
let scenario_from_params params_list =
  let d1, r1, d2, r2, d3, r3 =
    match params_list with
    | (d1, r1) :: (d2, r2) :: (d3, r3) :: _ -> (d1, r1, d2, r2, d3, r3)
    | _ -> (3.5747e10, 20., 2.6810e10, 18., 1.7873e10, 16.)
    (* fallback *)
  in
  {
    name = "Custom Three-Body System";
    description = "User-configured three-body system";
    bodies =
      create_three_body_system ~custom_params:(Some (d1, r1, d2, r2, d3, r3)) ();
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Binary Star System - two stars in stable orbit *)
let binary_star_scenario () =
  let star_density = 5e10 in
  let star1_radius = 25. in
  let star2_radius = 22. in

  let mass1 = calculate_mass ~density:star_density ~radius:star1_radius in
  let mass2 = calculate_mass ~density:star_density ~radius:star2_radius in

  let separation = 150. in
  let r1 = separation *. mass2 /. (mass1 +. mass2) in
  let r2 = separation *. mass1 /. (mass1 +. mass2) in

  let total_mass = mass1 +. mass2 in
  let v_rel = Float.sqrt (g *. total_mass /. separation) in
  let v1 = v_rel *. mass2 /. total_mass in
  let v2 = v_rel *. mass1 /. total_mass in

  let star1 =
    Body.make ~density:star_density ~pos:(Vec3.make 0. (-.r1) 0.)
      ~vel:(Vec3.make v1 0. 0.) ~radius:star1_radius
      ~color:(255., 180., 120., 255.)
    (* Warm gold *)
  in
  let star2 =
    Body.make ~density:star_density ~pos:(Vec3.make 0. r2 0.)
      ~vel:(Vec3.make (-.v2) 0. 0.) ~radius:star2_radius
      ~color:(120., 180., 255., 255.)
    (* Cool blue *)
  in

  {
    name = "Binary Star";
    description = "Two stars in stable circular orbit";
    bodies = [ star1; star2 ];
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Solar System-like - central star with orbiting planets *)
let solar_system_scenario () =
  (* Increased sun density for stronger gravitational pull and stability *)
  let sun_density = 1.2e11 in
  let sun_radius = 30. in
  let sun =
    Body.make ~density:sun_density ~pos:(Vec3.make 0. 0. 0.)
      ~vel:(Vec3.make 0. 0. 0.) ~radius:sun_radius
      ~color:(255., 220., 100., 255.)
    (* Bright yellow sun *)
  in

  let sun_mass = calculate_mass ~density:sun_density ~radius:sun_radius in

  (* Inner planet - orbits in XZ plane *)
  let planet1_radius = 12. in
  let planet1_density = 2e10 in
  let orbit1 = 180. in
  let v1 = Float.sqrt (g *. sun_mass /. orbit1) in
  let planet1 =
    Body.make ~density:planet1_density ~pos:(Vec3.make orbit1 0. 0.)
      ~vel:(Vec3.make 0. 0. v1) ~radius:planet1_radius
      ~color:(180., 100., 150., 255.)
    (* Dusty rose *)
  in

  (* Outer planet - orbits in XY plane (perpendicular) to avoid collision *)
  let planet2_radius = 15. in
  let planet2_density = 1.8e10 in
  let orbit2 = 250. in
  let v2 = Float.sqrt (g *. sun_mass /. orbit2) in
  let planet2 =
    Body.make ~density:planet2_density
      ~pos:(Vec3.make orbit2 0. 0.)
      ~vel:(Vec3.make 0. v2 0.) ~radius:planet2_radius
      ~color:(100., 180., 220., 255.)
    (* Sky blue *)
  in

  {
    name = "Solar System";
    description = "Central star with two orbiting planets";
    bodies = [ sun; planet1; planet2 ];
    recommended_camera = (0.0, 0.0, 500.0);
  }

(** Collision Course - two bodies heading for collision *)
let collision_scenario () =
  let body1_density = 4e10 in
  let body1_radius = 22. in
  let body2_density = 3.5e10 in
  let body2_radius = 20. in

  let body1 =
    Body.make ~density:body1_density ~pos:(Vec3.make (-150.) 0. 0.)
      ~vel:(Vec3.make 2.0 0. 0.) ~radius:body1_radius
      ~color:(255., 120., 120., 255.)
    (* Soft red *)
  in
  let body2 =
    Body.make ~density:body2_density ~pos:(Vec3.make 150. 0. 0.)
      ~vel:(Vec3.make (-2.0) 0. 0.) ~radius:body2_radius
      ~color:(120., 120., 255., 255.)
    (* Soft blue *)
  in

  {
    name = "Collision Course";
    description = "Two bodies on collision trajectory";
    bodies = [ body1; body2 ];
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Get scenario by name *)
let get_scenario_by_name name =
  match name with
  | "Randomized 3-Body" -> randomized_three_body_scenario ()
  | "Binary Star" -> binary_star_scenario ()
  | "Solar System" -> solar_system_scenario ()
  | "Collision Course" -> collision_scenario ()
  | "Three-Body Problem" | _ -> default_scenario ()

(** List of all available scenarios *)
let all_scenarios =
  [
    "Three-Body Problem";
    "Randomized 3-Body";
    "Binary Star";
    "Solar System";
    "Collision Course";
  ]

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

  (* Body 1 - Heavy star orbiting in YZ plane *)
  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make com_x (com_y -. r1) com_z)
      ~vel:(Vec3.make 0. 0. v1) ~radius:radius1
      ~color:(255., 100., 100., 255.)
  in
  (* Body 2 - Medium companion orbiting opposite direction *)
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make com_x (com_y +. r2) com_z)
      ~vel:(Vec3.make 0. 0. (-.v2)) ~radius:radius2
      ~color:(100., 255., 100., 255.)
  in
  (* Body 3 - Interloper approaching at an angle *)
  let body3 =
    Body.make ~density:density3 ~pos:(Vec3.make 180. 60. 100.)
      ~vel:(Vec3.make (-1.0) (-0.4) (-0.6))
      ~radius:radius3
      ~color:(100., 100., 255., 255.)
  in
  [ body1; body2; body3 ]

(** Create randomized three-body system *)
let create_randomized_three_body () =
  let rand_range min max = min +. Random.float (max -. min) in

  let base_mass = 7000. /. g in
  let mass_variation = 0.3 in
  let mass1 =
    base_mass *. rand_range (1. -. mass_variation) (1. +. mass_variation)
  in
  let mass2 =
    base_mass *. rand_range (1. -. mass_variation) (1. +. mass_variation)
  in
  let mass3 =
    base_mass *. rand_range (1. -. mass_variation) (1. +. mass_variation)
  in

  let base_radius = 18. in
  let radius_variation = 0.2 in
  let radius1 =
    base_radius *. rand_range (1. -. radius_variation) (1. +. radius_variation)
  in
  let radius2 =
    base_radius *. rand_range (1. -. radius_variation) (1. +. radius_variation)
  in
  let radius3 =
    base_radius *. rand_range (1. -. radius_variation) (1. +. radius_variation)
  in

  let volume1 = 4.0 /. 3.0 *. Float.pi *. (radius1 ** 3.0) in
  let volume2 = 4.0 /. 3.0 *. Float.pi *. (radius2 ** 3.0) in
  let volume3 = 4.0 /. 3.0 *. Float.pi *. (radius3 ** 3.0) in
  let density1 = mass1 /. volume1 in
  let density2 = mass2 /. volume2 in
  let density3 = mass3 /. volume3 in

  let separation = 150. in
  let offset_x1 = rand_range (-15.) 15. in
  let offset_y1 = rand_range (-15.) 15. in
  let offset_z1 = rand_range (-15.) 15. in
  let offset_x2 = rand_range (-15.) 15. in
  let offset_y2 = rand_range (-15.) 15. in
  let offset_z2 = rand_range (-15.) 15. in
  let offset_x3 = rand_range (-20.) 20. in
  let offset_y3 = rand_range (-20.) 20. in
  let offset_z3 = rand_range (-20.) 20. in

  let speed_range_max = 6.0 in
  let vel1_x = rand_range (-.speed_range_max) speed_range_max in
  let vel1_y = rand_range (-.speed_range_max) speed_range_max in
  let vel1_z = rand_range (-.speed_range_max) speed_range_max in
  let vel2_x = rand_range (-.speed_range_max) speed_range_max in
  let vel2_y = rand_range (-.speed_range_max) speed_range_max in
  let vel2_z = rand_range (-.speed_range_max) speed_range_max in
  let vel3_x = rand_range (-.speed_range_max) speed_range_max in
  let vel3_y = rand_range (-.speed_range_max) speed_range_max in
  let vel3_z = rand_range (-.speed_range_max) speed_range_max in

  let r1 = separation *. mass2 /. (mass1 +. mass2) in
  let r2 = separation *. mass1 /. (mass1 +. mass2) in

  let body1 =
    Body.make ~density:density1
      ~pos:(Vec3.make offset_x1 (-.r1 +. offset_y1) offset_z1)
      ~vel:(Vec3.make vel1_x vel1_y vel1_z)
      ~radius:radius1
      ~color:(255., 150., 100., 255.)
  in
  let body2 =
    Body.make ~density:density2
      ~pos:(Vec3.make offset_x2 (r2 +. offset_y2) offset_z2)
      ~vel:(Vec3.make vel2_x vel2_y vel2_z)
      ~radius:radius2
      ~color:(100., 255., 150., 255.)
  in
  let third_body_distance = rand_range 180. 240. in
  let third_body_angle = rand_range 0. (2. *. Float.pi) in
  let body3 =
    Body.make ~density:density3
      ~pos:
        (Vec3.make
           ((third_body_distance *. Float.cos third_body_angle) +. offset_x3)
           (rand_range 40. 80. +. offset_y3)
           ((third_body_distance *. Float.sin third_body_angle) +. offset_z3))
      ~vel:(Vec3.make vel3_x vel3_y vel3_z)
      ~radius:radius3
      ~color:(150., 100., 255., 255.)
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
      ~color:(255., 200., 100., 255.)
  in
  let star2 =
    Body.make ~density:star_density ~pos:(Vec3.make 0. r2 0.)
      ~vel:(Vec3.make (-.v2) 0. 0.) ~radius:star2_radius
      ~color:(100., 200., 255., 255.)
  in

  {
    name = "Binary Star";
    description = "Two stars in stable circular orbit";
    bodies = [ star1; star2 ];
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Solar System-like - central star with orbiting planets *)
let solar_system_scenario () =
  let sun_density = 8e10 in
  let sun_radius = 30. in
  let sun =
    Body.make ~density:sun_density ~pos:(Vec3.make 0. 0. 0.)
      ~vel:(Vec3.make 0. 0. 0.) ~radius:sun_radius
      ~color:(255., 255., 100., 255.)
  in

  let sun_mass = calculate_mass ~density:sun_density ~radius:sun_radius in

  (* Inner planet *)
  let planet1_radius = 12. in
  let planet1_density = 2e10 in
  let orbit1 = 100. in
  let v1 = Float.sqrt (g *. sun_mass /. orbit1) in
  let planet1 =
    Body.make ~density:planet1_density ~pos:(Vec3.make orbit1 0. 0.)
      ~vel:(Vec3.make 0. 0. v1) ~radius:planet1_radius
      ~color:(150., 100., 200., 255.)
  in

  (* Outer planet *)
  let planet2_radius = 15. in
  let planet2_density = 1.8e10 in
  let orbit2 = 180. in
  let v2 = Float.sqrt (g *. sun_mass /. orbit2) in
  let planet2 =
    Body.make ~density:planet2_density
      ~pos:(Vec3.make (-.orbit2) 0. 0.)
      ~vel:(Vec3.make 0. 0. (-.v2)) ~radius:planet2_radius
      ~color:(100., 150., 255., 255.)
  in

  {
    name = "Solar System";
    description = "Central star with two orbiting planets";
    bodies = [ sun; planet1; planet2 ];
    recommended_camera = (0.0, 0.0, 450.0);
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
      ~color:(255., 100., 100., 255.)
  in
  let body2 =
    Body.make ~density:body2_density ~pos:(Vec3.make 150. 0. 0.)
      ~vel:(Vec3.make (-2.0) 0. 0.) ~radius:body2_radius
      ~color:(100., 100., 255., 255.)
  in

  {
    name = "Collision Course";
    description = "Two bodies on collision trajectory";
    bodies = [ body1; body2 ];
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Figure-8 Orbit - special chaotic three-body configuration *)
let figure_eight_scenario () =
  let body_density = 3e10 in
  let body_radius = 18. in

  (* Figure-8 requires very specific initial conditions *)
  let body1 =
    Body.make ~density:body_density
      ~pos:(Vec3.make 97.0 (-24.3) 0.)
      ~vel:(Vec3.make 0.466 0.433 0.) ~radius:body_radius
      ~color:(255., 100., 100., 255.)
  in
  let body2 =
    Body.make ~density:body_density
      ~pos:(Vec3.make (-97.0) 24.3 0.)
      ~vel:(Vec3.make 0.466 0.433 0.) ~radius:body_radius
      ~color:(100., 255., 100., 255.)
  in
  let body3 =
    Body.make ~density:body_density ~pos:(Vec3.make 0. 0. 0.)
      ~vel:(Vec3.make (-0.932) (-0.866) 0.)
      ~radius:body_radius
      ~color:(100., 100., 255., 255.)
  in

  {
    name = "Figure-8 Orbit";
    description = "Chaotic three-body figure-8 configuration";
    bodies = [ body1; body2; body3 ];
    recommended_camera = (0.0, 0.0, 400.0);
  }

(** Get scenario by name *)
let get_scenario_by_name name =
  match name with
  | "Randomized 3-Body" -> randomized_three_body_scenario ()
  | "Binary Star" -> binary_star_scenario ()
  | "Solar System" -> solar_system_scenario ()
  | "Collision Course" -> collision_scenario ()
  | "Figure-8 Orbit" -> figure_eight_scenario ()
  | "Three-Body Problem" | _ -> default_scenario ()

(** List of all available scenarios *)
let all_scenarios =
  [
    "Three-Body Problem";
    "Randomized 3-Body";
    "Binary Star";
    "Solar System";
    "Collision Course";
    "Figure-8 Orbit";
  ]

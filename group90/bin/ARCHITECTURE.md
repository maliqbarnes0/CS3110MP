# Bin Directory Architecture

This document explains how the different OCaml modules in the `bin/` directory interact to create the 3D gravity simulation.

## Module Overview

```
main.ml (Entry Point)
   ├─> simulation.ml (Physics & Game Loop)
   │   ├─> render.ml (3D Rendering & Visuals)
   │   ├─> ui.ml (2D UI & Controls)
   │   ├─> cameracontrol.ml (Camera Movement)
   │   └─> Group90 (Backend Library Modules)
   │       ├─> Simulation_state (State Management)
   │       ├─> Physics_system (Physics Coordination)
   │       ├─> Scenario (Scenario Definitions)
   │       ├─> Body (Celestial Body Data)
   │       ├─> Vec3 (3D Vector Math)
   │       └─> Engine (Core Physics)
   └─> render.ml (Star Initialization)
```

## Module Responsibilities

### 1. **main.ml** - Application Entry Point
- **Purpose**: Bootstrap the application and initialize the window
- **Key Responsibilities**:
  - Creates the Raylib window (800x600)
  - Initializes the starfield background
  - Sets up the initial 3D camera position (60, 40, 60) for zoomed-in view
  - Calculates initial spherical camera coordinates (radius ~85 units, theta, phi)
  - Loads the default scenario (Three-Body Problem)
  - Creates initial simulation state using `Group90.Simulation_state`
  - Starts the simulation loop
  - Handles the exit screen after simulation ends
- **Dependencies**: Uses `simulation.ml`, `render.ml`, `ui.ml`, and `Group90` library modules

### 2. **simulation.ml** - Physics Engine & Main Loop
- **Purpose**: Core simulation loop that handles physics updates and coordinates all subsystems
- **Key Responsibilities**:
  - Runs the main game loop that processes each frame
  - Updates physics using `Group90.Physics_system` with time scaling
  - Handles user input for:
    - Speed control (Z/X keys: min 0.1x, max 20x)
    - Pause/resume (P key)
    - Scenario switching (1-6 keys for 6 different scenarios)
    - Reset current scenario (R key)
    - Slider interactions for planet density and radius (UI scale 1-20)
    - Planet selection via mouse click with raycasting
  - Manages UI interactions:
    - Sidebar open/close button
    - Planet navigation arrows (left/right)
    - Slider dragging with conversion between UI scale and physics values
  - Coordinates camera updates via `cameracontrol.ml` (disabled when mouse over UI)
  - Delegates rendering to `render.ml` and UI to `ui.ml`
  - Uses `Simulation_state` for all state management (world, trails, animations, parameters)
- **Dependencies**: Uses `render.ml`, `ui.ml`, `cameracontrol.ml`, and `Group90` library modules

### 3. **render.ml** - 3D Rendering System
- **Purpose**: Handles all 3D graphics rendering and visual effects
- **Key Responsibilities**:
  - Converts physics coordinates to visual coordinates (render_scale = 0.1)
  - Generates and draws the starfield background (400 stars)
  - Renders planetary bodies as colored spheres with colors from body data
  - Draws orbital trails with fading effects for orphaned trails
  - Renders collision animations (expanding spheres that fade out over 1 second)
  - Draws 3D starbox background relative to camera position
  - Manages trail state (Active or Orphaned with fade-out)
- **Trail System**:
  - Trails are maintained by `Simulation_state`
  - Active trails follow living bodies
  - Orphaned trails fade out when bodies are removed (collisions)
  - Trail alpha decreases over 3 seconds after orphaning
- **Dependencies**: Uses `Group90` library for physics data structures (Body, Vec3)

### 4. **ui.ml** - User Interface & Controls
- **Purpose**: Renders 2D UI overlay and handles UI interactions
- **Key Responsibilities**:
  - Draws the collapsible planet editor sidebar (560-790px horizontal)
  - Displays planet parameter sliders with UI scale (1-20)
  - Shows simulation status (speed, pause state, collision warnings)
  - Renders bottom-left instructions panel with scenario list and controls
  - Manages color palette for planets and UI elements
  - Handles slider drag interactions with value conversion
  - Provides sidebar navigation (close button, arrow buttons)
  - Provides exit button functionality
  - Detects mouse-over-UI for camera control filtering
  - Converts between UI scale (1-20) and actual physics values
- **Key Functions**:
  - `draw_slider`: Renders interactive slider controls with clean decimal display
  - `check_slider_drag`: Detects and handles slider interactions (returns UI scale 1-20)
  - `density_to_ui_scale` / `ui_scale_to_density`: Convert density between UI and physics scales
  - `radius_to_ui_scale` / `ui_scale_to_radius`: Convert radius between UI and physics scales
  - `draw_sidebar`: Renders planet editor with sliders, planet selector, and info
  - `draw_instructions`: Renders control panel with scenario list and keys
  - `check_exit_button`: Handles exit button clicks
  - `check_sidebar_close_button`: Handles sidebar close (X) button
  - `check_left_arrow` / `check_right_arrow`: Handle planet navigation
  - `mouse_over_ui`: Prevents camera controls when over any UI element
  - `get_body_color_from_body`: Extracts Raylib color from body data
- **UI Scale Conversion**:
  - Density: 1-20 UI scale maps to 1e9-1e11 actual density
  - Radius: 1-20 UI scale maps to 10-40 actual radius
  - Linear interpolation for intuitive control
- **Dependencies**: Uses Raylib for drawing primitives and `Group90.Body` for color extraction

### 5. **cameracontrol.ml** - 3D Camera Management
- **Purpose**: Handles camera movement and positioning in 3D space
- **Key Responsibilities**:
  - Implements spherical coordinate camera system (theta, phi, radius)
  - Processes mouse drag for camera rotation (left mouse button)
  - Handles mouse wheel for zoom in/out (10 to 50,000 units)
  - Implements WASD/QE panning controls relative to camera orientation
  - Clamps phi angle to avoid gimbal lock (-1.5 to 1.5 radians)
  - Converts spherical coordinates to Cartesian for camera position
  - Maintains camera target that can be panned with WASD/QE
- **Input Handling**:
  - Left mouse drag: Rotate camera around target (sensitivity: 0.003)
  - Mouse wheel: Zoom in/out (zoom step: 10 units per scroll)
  - W/S: Pan forward/backward relative to camera direction
  - A/D: Strafe left/right relative to camera direction
  - Q/E: Move camera target up/down (pan speed: 5.0 units/frame)
- **Camera System**:
  - Spherical coordinates for rotation (theta: horizontal, phi: vertical)
  - Radius controls zoom distance from target
  - Target can be moved independently with WASD/QE
  - Forward/right vectors calculated from camera orientation on XZ plane
- **Dependencies**: Uses Raylib for input detection (mouse, keyboard)

## Data Flow

### Initialization Flow
1. **main.ml** creates window (800x600) and initializes Raylib
2. **render.ml** generates static starfield (400 stars)
3. **main.ml** creates initial camera (position: 60, 40, 60; radius: ~85 units)
4. **main.ml** loads default scenario via `Group90.Scenario.default_scenario()`
5. **main.ml** creates initial state via `Group90.Simulation_state.create_initial()`
6. **main.ml** calls **simulation.ml**'s `simulation_loop` with initial state and camera

### Per-Frame Flow
1. **simulation.ml** handles UI button interactions:
   - Sidebar close button check
   - Planet navigation arrows (if sidebar visible)
2. **simulation.ml** handles slider input (if sidebar visible):
   - Checks density slider drag → converts UI scale to actual density
   - Checks radius slider drag → converts UI scale to actual radius
   - Updates state via `Simulation_state.update_planet_*` functions
3. **simulation.ml** handles keyboard input:
   - Scenario switching (1-6 keys) → loads new scenario
   - Reset (R key) → reloads current scenario
   - Time scale (Z/X keys) → adjusts speed
   - Pause (P key) → toggles pause state
4. **simulation.ml** handles planet selection:
   - Mouse click → raycasts to detect planet
   - Opens sidebar with selected planet
5. **simulation.ml** updates physics (if not paused):
   - Calls `Physics_system.update_physics` with time scaling
   - Receives new world state and collision list
   - Updates trails via `Simulation_state.update_trails_with_fading`
   - Adds collision animations for new collisions
   - Prunes expired animations
6. **simulation.ml** updates camera:
   - Calls **cameracontrol.ml** (only if mouse not over UI)
   - Receives new camera state and spherical coordinates
7. **simulation.ml** begins rendering:
   - Starts 3D mode with camera
   - **render.ml** draws starbox background
   - **render.ml** draws trails (with fading for orphaned trails)
   - **render.ml** draws planetary bodies with colors
   - **render.ml** draws collision animations
   - Ends 3D mode
   - **ui.ml** draws 2D overlay (instructions, sidebar if visible, exit button)
8. **simulation.ml** sleeps for frame timing (0.016s ≈ 60 FPS)
9. **simulation.ml** recursively calls itself for next frame with updated state

## Key Interactions

### Camera Control
```
User Input (Mouse/Keyboard) → cameracontrol.ml → Returns new camera state
                                      ↓
                              simulation.ml (stores camera state)
                                      ↓
                              render.ml (uses camera for starbox positioning)
```

### Physics to Rendering
```
Physics_system.update_physics → Returns (new_world, collisions)
                                      ↓
                              simulation.ml (updates state)
                                      ↓
                         Simulation_state (manages trails, animations)
                                      ↓
                         render.ml (converts to visual coordinates)
                                      ↓
                         Screen (Raylib drawing)
```

### Planet Parameter Editing
```
User drags slider → ui.ml (detects drag, returns UI scale 1-20)
                      ↓
              simulation.ml (converts UI scale to actual value)
                      ↓
         Simulation_state.update_planet_* (updates both params and live body)
                      ↓
              Body in world updated with new mass/radius
                      ↓
         Next physics step uses updated values
```

### Scenario Switching
```
User presses number key (1-6) → simulation.ml (detects key)
                                      ↓
                         Scenario.get_scenario_by_name (loads scenario)
                                      ↓
                         Simulation_state.load_scenario (clears trails/anims)
                                      ↓
                         Simulation_state.set_world (loads new bodies)
                                      ↓
                         Resets params to match scenario bodies
```

### Collision Handling
```
Physics_system.update_physics → Returns collision pairs
                                      ↓
         simulation.ml (stores old body colors before update)
                                      ↓
         Simulation_state.add_collision_animations
                                      ↓
         Creates explosion animation at collision point
                                      ↓
         render.ml (draws expanding spheres with fade-out)
                                      ↓
         Simulation_state.prune_expired_animations (after 1 second)
```

### Planet Selection
```
User clicks on planet → simulation.ml (gets mouse position)
                                ↓
                    Raylib.get_screen_to_world_ray (creates ray)
                                ↓
                    For each body: check ray-sphere collision
                                ↓
                    Find closest hit body index
                                ↓
                    Simulation_state.set_selected_planet
                                ↓
                    Simulation_state.set_sidebar_visible true
                                ↓
                    ui.ml draws sidebar with selected planet's params
```

## Important Constants

- **Window Size**: 800x600 pixels
- **Render Scale**: 0.1 (physics units to visual units)
- **Frame Rate**: 60 FPS target (0.016s sleep per frame)
- **Max Trail Length**: 120 positions per body
- **Star Count**: 400 stars in background
- **Camera Settings**:
  - Initial position: (60, 40, 60) units
  - Initial radius: ~85 units (zoomed in)
  - Zoom range: 10 to 50,000 units
  - Rotation sensitivity: 0.003
  - Pan speed: 5.0 units per frame
  - Phi clamp: -1.5 to 1.5 radians (prevents gimbal lock)
  - Field of view: 70 degrees
- **Time Scale**:
  - Min: 0.1x
  - Max: 20x
  - Default: 1.0x
  - Adjustment: 1.5x multiplier/divisor per key press
- **UI Scales**:
  - Density: UI 1-20 → Physics 1e9 to 1e11
  - Radius: UI 1-20 → Physics 10 to 40
- **Collision Animation**: 1 second duration with fade-out
- **Trail Fade**: 3 seconds for orphaned trails
- **Sidebar Dimensions**: 560-790px horizontal, 50-300px vertical

## State Management

The simulation uses `Simulation_state` module (lib/simulation_state.ml) to manage all state in a functional, immutable way. State is updated by creating new state records each frame.

### Simulation State Record
```ocaml
type t = {
  world : Body.b list;                    (* Current list of celestial bodies *)
  trails : trail_state list;              (* Position history for rendering trails *)
  collision_anims : collision_animation list;  (* Active collision animations *)
  time_scale : float;                     (* Simulation speed multiplier *)
  paused : bool;                          (* Whether the simulation is paused *)
  pending_params : planet_params list;    (* Current slider values (UI) *)
  applied_params : planet_params list;    (* Last applied parameter values *)
  current_scenario : string;              (* Name of the current scenario *)
  sidebar_visible : bool;                 (* Whether the planet editor sidebar is visible *)
  selected_planet : int;                  (* Index of the currently selected planet *)
}
```

### Trail State
```ocaml
type trail_state =
  | Active of Vec3.v list            (* Trail for a body that still exists *)
  | Orphaned of {                     (* Trail for a removed body that is fading out *)
      positions : Vec3.v list;
      orphaned_at : float;
    }
```

### Camera State (managed in simulation.ml)
Maintained through recursive function parameters:
- `camera`: Raylib Camera3D object
- `theta`: Horizontal rotation angle (radians)
- `phi`: Vertical rotation angle (radians, clamped)
- `radius`: Distance from target (zoom level)

All camera state is immutable and passed to the next frame.

## Input Controls Summary

### Mouse Controls
| Action | Handler | Effect |
|--------|---------|--------|
| Left Mouse Drag | cameracontrol.ml | Rotate camera around target |
| Mouse Wheel | cameracontrol.ml | Zoom in/out (10-50,000 units) |
| Left Click on Planet | simulation.ml | Select planet, open sidebar |
| Slider Drag | ui.ml + simulation.ml | Adjust planet density/radius (UI scale 1-20) |
| Exit Button Click | ui.ml | Exit simulation |
| Sidebar X Button | ui.ml | Close sidebar |
| Arrow Buttons | ui.ml | Cycle through planets |

### Keyboard Controls
| Key | Handler | Effect |
|-----|---------|--------|
| 1 | simulation.ml | Load Three-Body Problem scenario |
| 2 | simulation.ml | Load Randomized 3-Body scenario (cyan, magenta, yellow) |
| 3 | simulation.ml | Load Binary Star scenario |
| 4 | simulation.ml | Load Solar System scenario |
| 5 | simulation.ml | Load Collision Course scenario |
| 6 | simulation.ml | Load Figure-8 Orbit scenario |
| R | simulation.ml | Reset current scenario |
| P | simulation.ml | Pause/Resume simulation |
| Z | simulation.ml | Increase speed (1.5x, max 20x) |
| X | simulation.ml | Decrease speed (1.5x, min 0.1x) |
| W | cameracontrol.ml | Pan camera forward |
| S | cameracontrol.ml | Pan camera backward |
| A | cameracontrol.ml | Pan camera left |
| D | cameracontrol.ml | Pan camera right |
| Q | cameracontrol.ml | Pan camera down |
| E | cameracontrol.ml | Pan camera up |

## Backend Library Modules (lib/)

The simulation uses several backend modules from the `Group90` library:

### **simulation_state.ml** - State Management
- Manages all simulation state in a functional, immutable way
- Provides functions for updating state (time scale, pause, world, trails, etc.)
- Handles planet parameter updates (density, radius) for both pending and live bodies
- Manages trail fading for orphaned trails (when bodies are removed)
- Tracks sidebar visibility and selected planet
- Scenario loading and parameter reset

### **physics_system.ml** - Physics Engine Coordination
- Coordinates physics updates using the Engine module
- Applies time scaling to physics calculations
- Detects collisions between bodies
- Returns updated world state and collision list

### **scenario.ml** - Scenario Definitions
- Defines 6 pre-configured scenarios:
  1. Three-Body Problem (binary + interloper)
  2. Randomized 3-Body (random params, cyan/magenta/yellow colors)
  3. Binary Star (stable circular orbit)
  4. Solar System (central star + 2 planets)
  5. Collision Course (head-on collision)
  6. Figure-8 Orbit (chaotic figure-8)
- Provides `create_three_body_system` with optional custom parameters
- Calculates orbital velocities and stable configurations

### **body.ml** - Celestial Body Data Structure
- Represents a celestial body with mass, position, velocity, radius, and color
- Provides functions for creating and querying body properties
- Stores color as RGBA float tuple (0-255 range)

### **vec3.ml** - 3D Vector Mathematics
- 3D vector type and operations (add, subtract, scale, dot product, etc.)
- Used throughout for positions, velocities, and physics calculations

### **engine.ml** - Core Physics Calculations
- Implements N-body gravitational physics
- Calculates gravitational forces between all body pairs
- Updates positions and velocities using numerical integration
- Handles collision detection and merging of bodies

# Bin Directory Architecture

This document explains how the different OCaml modules in the `bin/` directory interact to create the 3D gravity simulation.

## Module Overview

```
main.ml (Entry Point)
   ├─> simulation.ml (Physics & Game Loop)
   │   ├─> render.ml (3D Rendering & Visuals)
   │   ├─> ui.ml (2D UI & Controls)
   │   └─> cameracontrol.ml (Camera Movement)
   └─> render.ml (Star Initialization)
```

## Module Responsibilities

### 1. **main.ml** - Application Entry Point
- **Purpose**: Bootstrap the application and initialize the window
- **Key Responsibilities**:
  - Creates the Raylib window (800x600)
  - Initializes the starfield background
  - Sets up the initial 3D camera position and parameters
  - Calculates initial spherical camera coordinates (radius, theta, phi)
  - Defines initial planet parameters (density, radius for 3 bodies)
  - Starts the simulation loop
  - Handles the exit screen after simulation ends
- **Dependencies**: Uses `simulation.ml`, `render.ml`, and `ui.ml`

### 2. **simulation.ml** - Physics Engine & Main Loop
- **Purpose**: Core simulation loop that handles physics updates and coordinates all subsystems
- **Key Responsibilities**:
  - Creates the 3-body gravitational system with configurable parameters
  - Runs the main game loop that processes each frame
  - Updates physics using the `Group90.Engine` module with fixed timesteps
  - Handles user input for:
    - Speed control (Z/X keys for faster/slower)
    - Pause/resume (P key)
    - Parameter application (A key) and reset (R key)
    - Slider interactions for planet density and radius
  - Manages collision detection and response
  - Coordinates camera updates via `cameracontrol.ml`
  - Delegates rendering to `render.ml` and UI to `ui.ml`
  - Maintains simulation state (trails, collision animations, planet parameters)
- **Dependencies**: Uses `render.ml`, `ui.ml`, `cameracontrol.ml`, and `Group90` library

### 3. **render.ml** - 3D Rendering System
- **Purpose**: Handles all 3D graphics rendering and visual effects
- **Key Responsibilities**:
  - Converts physics coordinates to visual coordinates (render_scale = 0.1)
  - Generates and draws the starfield background (400 stars)
  - Renders planetary bodies as colored spheres
  - Draws orbital trails (up to 120 positions per body)
  - Manages collision animations (expanding spheres that fade out)
  - Draws 3D axis indicators and grid planes
  - Updates trail positions based on physics simulation
  - Calculates collision impact points for animations
- **Key Data Types**:
  - `trails`: List of position histories for each body
  - `collision_animation`: Animated explosion effects with position, timing, and color
- **Dependencies**: Uses `Group90` library for physics data structures

### 4. **ui.ml** - User Interface & Controls
- **Purpose**: Renders 2D UI overlay and handles UI interactions
- **Key Responsibilities**:
  - Draws the right sidebar control panel (600-800px horizontal)
  - Displays planet parameter sliders (density and radius)
  - Shows simulation status (speed, pause state, collision warnings)
  - Renders control instructions and key bindings
  - Manages color palette for planets and UI elements
  - Handles slider drag interactions
  - Provides exit button functionality
  - Detects mouse-over-sidebar for camera control filtering
  - Blends colors for collision animations
- **Key Functions**:
  - `draw_slider`: Renders interactive slider controls
  - `check_slider_drag`: Detects and handles slider interactions
  - `check_exit_button`: Handles exit button clicks
  - `mouse_over_sidebar`: Prevents camera controls when over UI
- **Dependencies**: Uses Raylib for drawing primitives

### 5. **cameracontrol.ml** - 3D Camera Management
- **Purpose**: Handles camera movement and positioning in 3D space
- **Key Responsibilities**:
  - Implements spherical coordinate camera system (theta, phi, radius)
  - Processes mouse drag for camera rotation (left mouse button)
  - Handles mouse wheel for zoom in/out
  - Prevents camera control when mouse is over the UI sidebar
  - Clamps camera angles to avoid gimbal lock
  - Converts spherical coordinates to Cartesian for camera position
  - Maintains camera target (always looking at origin)
- **Input Handling**:
  - Left mouse drag: Rotate camera around target
  - Mouse wheel: Zoom in/out (radius: 10 to 50,000 units)
  - Sidebar awareness: Disables controls when mouse over UI
- **Dependencies**: Uses Raylib for input detection

## Data Flow

### Initialization Flow
1. **main.ml** creates window and initializes components
2. **render.ml** generates static starfield
3. **main.ml** creates initial camera and planet parameters
4. **main.ml** calls **simulation.ml**'s `simulation_loop`

### Per-Frame Flow
1. **simulation.ml** receives input and updates camera via **cameracontrol.ml**
2. **simulation.ml** updates physics using `Group90.Engine.step_with_collisions`
3. **simulation.ml** updates trails and collision animations via **render.ml** functions
4. **simulation.ml** handles slider interactions using **ui.ml** helper functions
5. **simulation.ml** begins 3D rendering:
   - **render.ml** draws starfield background
   - **render.ml** draws orbital trails
   - **render.ml** draws planetary bodies
   - **render.ml** draws collision animations
6. **ui.ml** draws 2D overlay (sidebar, controls, warnings)
7. **simulation.ml** recursively calls itself for next frame

## Key Interactions

### Camera Control
```
User Input → cameracontrol.ml → Returns new camera state
                ↓
           simulation.ml (stores camera state)
                ↓
           render.ml (uses camera for starfield positioning)
```

### Physics to Rendering
```
Group90.Engine → simulation.ml (physics state)
                      ↓
                 render.ml (converts to visual coordinates)
                      ↓
                 Screen (Raylib drawing)
```

### User Parameter Changes
```
User drags slider → ui.ml (detects interaction)
                      ↓
                simulation.ml (updates pending_params)
                      ↓
         User presses 'A' → simulation.ml (applies to physics)
                      ↓
               create_system with new parameters
```

### Collision Handling
```
Engine.step_with_collisions → Returns collision pairs
                                      ↓
                              simulation.ml (creates animations)
                                      ↓
                              render.ml (draws expanding spheres)
                                      ↓
                          Fades out over 1 second duration
```

## Important Constants

- **Window Size**: 800x600 (600px for 3D viewport, 200px sidebar)
- **Render Scale**: 0.1 (physics units to visual units)
- **Fixed Physics Timestep**: 0.1 seconds
- **Frame Rate**: 60 FPS target
- **Max Trail Length**: 120 positions
- **Star Count**: 400 stars
- **Camera Zoom Range**: 10 to 50,000 units

## State Management

The simulation maintains state across frames using recursive function calls:
- `world`: Current physics state (list of bodies)
- `trails`: Historical positions for each body
- `time_scale`: Simulation speed multiplier
- `paused`: Boolean pause state
- `camera`, `theta`, `phi`, `radius`: Camera state
- `collision_anims`: Active collision animations
- `pending_params` vs `applied_params`: Tracks UI changes before application

## Input Controls Summary

| Key/Action | Handler | Effect |
|------------|---------|--------|
| Left Mouse Drag | cameracontrol.ml | Rotate camera |
| Mouse Wheel | cameracontrol.ml | Zoom in/out |
| Z | simulation.ml | Increase speed (max 20x) |
| X | simulation.ml | Decrease speed (min 0.1x) |
| P | simulation.ml | Pause/Resume |
| A | simulation.ml | Apply slider changes |
| R | simulation.ml | Reset to defaults |
| Slider Drag | ui.ml + simulation.ml | Adjust planet parameters |
| Exit Button | ui.ml | Exit simulation |

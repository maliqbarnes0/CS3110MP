# 3D Gravity Simulation - Installation & User Guide

This document provides instructions for installing dependencies, building, and using the 3D Gravity Simulation project.

## Prerequisites and Installation

To run the 3D graphical visualization, you need the following libraries:
- **Raylib** - Modern 3D game development library
- **Unix** - System operations (typically included with OCaml)

### macOS Installation

**Install Raylib OCaml library**:

```bash
opam install raylib
```

Note: The `unix` library is typically included with your OCaml installation.

### Linux Installation

**Install Raylib OCaml library**:

```bash
opam install raylib
```

Note: The `unix` library is typically included with your OCaml installation.

## Quick Start (After Installation)

Once dependencies are installed, assuming you are in the root directory of the dune project (where dune-project and INSTALL.md are located), simply run the following:

```bash
dune build
dune exec group90
```

## Controls

### Camera Controls
- **Left Click + Drag** - Rotate camera around the scene
- **Mouse Wheel** - Zoom in/out (range: 10 to 50,000 units)
- **W/A/S/D** - Pan camera (forward/left/backward/right)
- **Q/E** - Move camera down/up

### Simulation Controls
- **P** - Pause/Resume the simulation
- **Z** - Speed up time (1.5x multiplier, max 20x)
- **X** - Slow down time (1.5x divisor, min 0.1x)
- **R** - Reset current scenario

### Scenario Selection
- **1** - Three-Body Problem (binary star system with interloper)
- **2** - Randomized 3-Body (random masses, positions, velocities with cyan, magenta, yellow planets)
- **3** - Binary Star (two stars in stable circular orbit)
- **4** - Solar System (central star with two orbiting planets)
- **5** - Collision Course (two bodies heading for collision)
- **6** - Figure-8 Orbit (chaotic three-body figure-8 configuration)

### Planet Editing
- **Click on a planet** - Select planet and open sidebar editor
- **Drag sliders** - Adjust planet density and radius (scale 1-20 for intuitive control)
- **X button** - Close sidebar
- **Arrow buttons** - Cycle through planets

## Features

### Physics & Simulation
- Real-time N-body gravitational simulation with accurate physics
- Collision detection and merging of bodies
- Configurable simulation speed (0.1x to 20x)
- Multiple pre-configured scenarios
- Interactive planet parameter editing (density and radius)

### 3D Visualization
- Full 3D visualization with orbital mechanics
- Advanced camera controls (rotate, zoom, pan)
- Starfield background (400 stars)
- Orbital trails showing historical paths (up to 120 positions per body)
- Collision animations with expanding explosion effects
- Color-coded planets with distinct visual appearance

### User Interface
- Collapsible sidebar for planet parameter editing
- Bottom-left instructions panel showing:
  - Current scenario
  - Available scenarios (1-6)
  - Speed control display
  - Pause/Resume status
- Real-time parameter adjustment with interactive sliders
- Live body count display
- Mouse-aware UI (camera controls disabled when over UI)

## Architecture

The project is organized into two main directories:

### Frontend (bin/)
- **main.ml** - Entry point, window initialization, camera setup
- **simulation.ml** - Main game loop, physics updates, input handling
- **render.ml** - 3D rendering (bodies, trails, starfield, collisions)
- **ui.ml** - 2D UI overlay (sidebar, instructions, controls)
- **cameracontrol.ml** - Camera movement and positioning

### Backend (lib/)
- **simulation_state.ml** - State management (world, trails, animations, parameters)
- **physics_system.ml** - Physics engine coordination
- **scenario.ml** - Pre-configured scenario definitions
- **body.ml** - Celestial body data structure
- **vec3.ml** - 3D vector mathematics
- **engine.ml** - Core physics calculations

See [bin/ARCHITECTURE.md](bin/ARCHITECTURE.md) for detailed module interaction diagrams.

## Troubleshooting

### "Library raylib not found"

Run: `opam install raylib`

### Window doesn't open or crashes

- Make sure raylib is properly installed
- Try rebuilding: `dune clean && dune build`

### Simulation is too slow/fast

- Use **Z** and **X** keys to adjust simulation speed
- Default speed is 1.0x, adjustable from 0.1x to 20x

### Camera is too far out or too close

- Use **Mouse Wheel** to adjust zoom level
- The initial camera starts zoomed in at ~85 units from origin
- Camera zoom range is 10 to 50,000 units

## Customization

### Modifying Scenarios
Edit [lib/scenario.ml](lib/scenario.ml) to:
- Add new scenarios
- Change planet positions, velocities, and masses
- Modify planet colors (RGBA tuples)
- Adjust orbital parameters

### Adjusting Camera
Edit [bin/main.ml](bin/main.ml) to:
- Change initial camera position (currently 60, 40, 60)
- Modify field of view (currently 70 degrees)
- Adjust initial zoom level

Edit [bin/cameracontrol.ml](bin/cameracontrol.ml) to:
- Change zoom range (currently 10 to 50,000)
- Adjust camera rotation sensitivity
- Modify pan speed

### UI Customization
Edit [bin/ui.ml](bin/ui.ml) to:
- Change slider UI scale (currently 1-20, mapped to density 1e9-1e11 and radius 10-40)
- Modify UI colors and layout
- Adjust sidebar size and position
- Customize conversion functions between UI scale and actual physics values

### Physics Parameters
Edit [lib/physics_system.ml](lib/physics_system.ml) to:
- Adjust gravitational constant
- Modify collision detection thresholds
- Change trail length and behavior

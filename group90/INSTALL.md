# 3-Body Gravity Simulation - 3D Graphics Setup Guide

This document provides instructions for installing dependencies and building the 3-Body Gravity Simulation project.

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

Once the simulation window opens:

- **Left Click + Drag** - Rotate camera
- **Mouse Wheel** - Zoom in/out
- **P** - Pause/Resume the simulation
- **Z** - Speed up time (1.5x, max 100x)
- **X** - Slow down time (1.5x, min 0.1x)
- **R** - Reset simulation
- **Click EXIT button** - Quit the simulation

## Features

- Real-time 3-body gravitational simulation
- Full 3D visualization with orbital mechanics
- Interactive 3D camera controls (rotate and zoom)
- Three orbiting bodies with realistic physics
- Orbital trails showing body paths
- Interactive speed controls and pause/resume
- 3D grid and axis indicators
- Collision detection

## Troubleshooting

### "Library raylib not found"

Run: `opam install raylib`

### Window doesn't open or crashes

- Make sure raylib is properly installed
- Try rebuilding: `dune clean && dune build`

### Simulation is too slow/fast

- Use **Z** and **X** keys to adjust simulation speed
- The default speed is 2.0x

## Customization

You can modify the simulation by editing [bin/main.ml](bin/main.ml):

- Change window size in `init_window 800 600`
- Modify `create_system()` to change masses, positions, and orbital parameters
- Adjust initial `dt` (default 0.5) for different time scales
- Change body colors in the `draw_body` calls
- Modify camera position and field of view
- Adjust trail length by changing `max_trail_length`

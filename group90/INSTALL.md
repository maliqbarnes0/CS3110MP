# N-Body Physics Simulation - Graphics Setup Guide

This document provides instructions for installing dependencies and building the N-Body Physics Simulation project.

## Prerequisites and Installation

To run the graphical visualization, you need the **OCaml Graphics library** and its system dependencies (X11).

### macOS Installation

1. **Install XQuartz** (required for X11 support):

   ```bash
   brew install --cask xquartz
   ```

2. **Log out and log back in** (or restart your Mac) for XQuartz to work properly.

3. **Install the OCaml Graphics library**:

   ```bash
   opam install graphics
   ```

### Linux Installation

1. **Install X11 development libraries**:

   ```bash
   # Ubuntu/Debian
   sudo apt-get install libx11-dev libxft-dev

   # Fedora/RHEL
   sudo dnf install libX11-devel libXft-devel
   ```

2. **Install the OCaml Graphics library**:

   ```bash
   opam install graphics
   ```

## Quick Start (After Installation)

Once dependencies are installed, assuming you are in the root directory of the dune project (where dune-project and INSTALL.md are located), simply run the following:

```bash
dune build
dune exec group90
```

## Controls

Once the simulation window opens:

- **SPACE** - Pause/Resume the simulation
- **+/-** - Speed up/slow down time
- **Z/X** - Zoom in/out
- **Arrow keys** - Pan the camera (not yet implemented)
- **R** - Reset camera view
- **Q** or **ESC** - Quit

## Features

- Real-time N-body gravitational simulation
- 2D visualization of 3D space (top-down view)
- Interactive controls for time, zoom, and camera
- Orbital trails showing body paths
- Pre-configured solar system example (Sun, Mercury, Venus, Earth, Mars)
- Live statistics display

## Troubleshooting

### "Library graphics not found"

- Make sure you've installed XQuartz and logged out/in
- Run: `opam install graphics`

### Window doesn't open

- Make sure XQuartz is running (check Applications > Utilities > XQuartz)
- Try logging out and back in after installing XQuartz

### Simulation is too slow/fast

- Use **+** and **-** keys to adjust simulation speed
- The default speed is 1 day per frame at 60 FPS

## Customization

You can modify the simulation by editing [bin/main.ml](bin/main.ml):

- Change `Config.width` and `Config.height` for window size
- Modify `create_solar_system()` to add/remove bodies
- Adjust `default_dt` for different time scales
- Change colors in `body_colors` array

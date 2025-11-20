# 2-Body Gravity Simulation - Graphics Setup Guide

This document provides instructions for installing dependencies and building the 2-Body Gravity Simulation project.

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

- **P** - Pause/Resume the simulation
- **Z** - Speed up time (1.5x, max 100x)
- **X** - Slow down time (1.5x, min 0.1x)
- **Click EXIT button** - Quit the simulation

## Features

- Real-time 2-body gravitational simulation
- 2D visualization with orbital mechanics
- Interactive speed controls
- Two orbiting bodies with realistic physics
- Live speed display

## Troubleshooting

### "Library graphics not found"

- Make sure you've installed XQuartz and logged out/in
- Run: `opam install graphics`

### Window doesn't open

- Make sure XQuartz is running (check Applications > Utilities > XQuartz)
- Try logging out and back in after installing XQuartz

### Simulation is too slow/fast

- Use **Z** and **X** keys to adjust simulation speed
- The default speed is 2.0x

## Customization

You can modify the simulation by editing [bin/main.ml](bin/main.ml):

- Change window size in `open_graph " 800x600"`
- Modify `create_system()` to change masses and orbital parameters
- Adjust initial `dt` (default 2.0) for different time scales
- Change colors in `draw_body` calls

# OCaml Graphics Library API Reference
## Functions Used in main.ml

This document catalogs all Graphics library APIs and functions used in the N-Body Physics Simulation GUI implementation.

---

## Window Management

### `open_graph : string -> unit`
**Usage:** `open_graph " 1200x900"`
- **Purpose:** Opens a graphics window with specified dimensions
- **Parameters:** Window specification string (format: " WIDTHxHEIGHT")
- **Location in code:** Line 461 - Main entry point
- **Documentation:** https://ocaml.org/api/Graphics.html#VALopen_graph

### `close_graph : unit -> unit`
**Usage:** `close_graph ()`
- **Purpose:** Closes the graphics window and cleans up resources
- **Location in code:** Line 475 - Cleanup after main loop
- **Documentation:** https://ocaml.org/api/Graphics.html#VALclose_graph

### `set_window_title : string -> unit`
**Usage:** `set_window_title "N-Body Physics Simulation"`
- **Purpose:** Sets the title displayed in the window's title bar
- **Location in code:** Line 462 - Window initialization
- **Documentation:** https://ocaml.org/api/Graphics.html#VALset_window_title

---

## Drawing Functions

### `set_color : color -> unit`
**Usage:** `set_color color` or `set_color white` or `set_color black`
- **Purpose:** Sets the current drawing color for subsequent operations
- **Type:** `color` is an int (RGB hex value or predefined color)
- **Locations in code:**
  - Line 105 - Setting body color
  - Line 108 - Setting glow color
  - Line 126 - Setting label color (white)
  - Line 151 - Setting trail fade color
  - Lines 165-172, 179-192 - UI panel colors
- **Documentation:** https://ocaml.org/api/Graphics.html#VALset_color

### `fill_circle : int -> int -> int -> unit`
**Usage:** `fill_circle sx sy radius`
- **Purpose:** Draws a filled circle at position (x, y) with given radius
- **Parameters:** x-coordinate, y-coordinate, radius (all in pixels)
- **Location in code:** Line 106 - Drawing celestial bodies
- **Documentation:** https://ocaml.org/api/Graphics.html#VALfill_circle

### `draw_circle : int -> int -> int -> unit`
**Usage:** `draw_circle sx sy (radius + 1)`
- **Purpose:** Draws an outlined circle at position (x, y) with given radius
- **Parameters:** x-coordinate, y-coordinate, radius (all in pixels)
- **Location in code:** Line 112 - Drawing glow effect around bodies
- **Documentation:** https://ocaml.org/api/Graphics.html#VALdraw_circle

### `fill_rect : int -> int -> int -> int -> unit`
**Usage:** `fill_rect x y width height`
- **Purpose:** Draws a filled rectangle
- **Parameters:** x, y (bottom-left corner), width, height (all in pixels)
- **Locations in code:**
  - Line 165 - UI info panel background
  - Line 179 - Controls help panel background
  - Line 205 - Space background (fills entire screen)
- **Documentation:** https://ocaml.org/api/Graphics.html#VALfill_rect

### `draw_rect : int -> int -> int -> int -> unit`
**Usage:** `draw_rect x y width height`
- **Purpose:** Draws an outlined rectangle
- **Parameters:** x, y (bottom-left corner), width, height (all in pixels)
- **Locations in code:**
  - Line 168 - UI info panel border
  - Line 181 - Controls help panel border
- **Documentation:** https://ocaml.org/api/Graphics.html#VALdraw_rect

### `moveto : int -> int -> unit`
**Usage:** `moveto x y`
- **Purpose:** Moves the current drawing position (cursor) without drawing
- **Parameters:** x, y coordinates in pixels
- **Locations in code:**
  - Line 127 - Before drawing body labels
  - Line 152 - Before drawing trail line segment
  - Lines 170, 172, 175, 177, 180, 183-197 - Before drawing text strings
  - Lines 211, 213, 216, 218 - Drawing grid lines
- **Documentation:** https://ocaml.org/api/Graphics.html#VALmoveto

### `lineto : int -> int -> unit`
**Usage:** `lineto x y`
- **Purpose:** Draws a line from current position to (x, y)
- **Parameters:** x, y coordinates in pixels
- **Locations in code:**
  - Line 153 - Drawing trail segments between body positions
  - Lines 212, 214, 217, 219 - Drawing reference grid
- **Documentation:** https://ocaml.org/api/Graphics.html#VALlineto

### `draw_string : string -> unit`
**Usage:** `draw_string "text"`
- **Purpose:** Draws text at the current drawing position
- **Parameters:** String to display
- **Locations in code:**
  - Line 128 - Drawing planet name labels
  - Lines 171, 173, 176, 178, 180 - Drawing simulation info (bodies, time, speed, zoom, status)
  - Lines 184-198 - Drawing control instructions
- **Documentation:** https://ocaml.org/api/Graphics.html#VALdraw_string

---

## Color Functions

### `Graphics.rgb : int -> int -> int -> color`
**Usage:** `Graphics.rgb r g b`
- **Purpose:** Creates a color value from RGB components (0-255)
- **Parameters:** Red (0-255), Green (0-255), Blue (0-255)
- **Returns:** `color` type (internally an int)
- **Locations in code:**
  - Lines 108-111 - Creating faded glow colors
  - Lines 146-149 - Creating faded trail colors
  - Line 165 - Panel background color (240, 240, 240 - light gray)
  - Line 179 - Panel background color
  - Line 204 - Space background color (10, 10, 25 - dark blue)
  - Line 208 - Grid color (30, 30, 50 - subtle grid)
- **Documentation:** https://ocaml.org/api/Graphics.html#VALrgb

### Predefined Colors
**Usage:** `white`, `black`
- **Purpose:** Built-in color constants
- **Locations in code:**
  - Line 126 - White for text labels
  - Line 168, 181 - Black for panel borders
  - Lines 170-180 - Black for UI text
- **Available colors:** `black`, `white`, `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`
- **Documentation:** https://ocaml.org/api/Graphics.html#colors

---

## Input Handling

### `key_pressed : unit -> bool`
**Usage:** `if key_pressed () then ...`
- **Purpose:** Checks if a keyboard key has been pressed (non-blocking)
- **Returns:** `true` if key is in buffer, `false` otherwise
- **Location in code:** Line 287 - Input handling loop
- **Documentation:** https://ocaml.org/api/Graphics.html#VALkey_pressed

### `read_key : unit -> char`
**Usage:** `let key = read_key () in ...`
- **Purpose:** Reads and removes the next character from keyboard buffer
- **Returns:** Character representing the pressed key
- **Location in code:** Line 289 - Getting the pressed key
- **Special keys returned:**
  - `' '` (space) - Pause/Resume
  - `'+'`, `'='`, `'-'`, `'_'` - Speed control
  - `'z'`, `'Z'`, `'x'`, `'X'` - Zoom control
  - `'w'`, `'W'`, `'s'`, `'S'`, `'a'`, `'A'`, `'d'`, `'D'` - Pan camera
  - `'r'`, `'R'` - Reset simulation
  - `'c'`, `'C'` - Reset camera
  - `'q'`, `'Q'` - Quit
  - `'\027'` (ESC) - Quit
- **Documentation:** https://ocaml.org/api/Graphics.html#VALread_key

---

## Display Control

### `auto_synchronize : bool -> unit`
**Usage:** `auto_synchronize false`
- **Purpose:** Controls automatic screen refresh behavior
- **Parameters:** 
  - `true` - Immediate display of drawing operations
  - `false` - Manual control with `synchronize()` (better performance)
- **Location in code:** Line 463 - Disabled for manual frame control
- **Documentation:** https://ocaml.org/api/Graphics.html#VALauto_synchronize

### `synchronize : unit -> unit`
**Usage:** `synchronize ()`
- **Purpose:** Updates the display with all pending drawing operations
- **Location in code:** Line 236 - End of render function (manual frame buffer swap)
- **Note:** Only needed when `auto_synchronize` is set to `false`
- **Documentation:** https://ocaml.org/api/Graphics.html#VALsynchronize

---

## Summary of Usage Patterns

### Window Setup (Lines 461-463)
```ocaml
open_graph " 1200x900"        (* Create window *)
set_window_title "Title"       (* Set title *)
auto_synchronize false         (* Manual refresh control *)
```

### Rendering Loop Pattern
```ocaml
(* Clear screen *)
set_color background_color
fill_rect 0 0 width height

(* Draw shapes *)
set_color color
fill_circle x y radius
draw_circle x y radius

(* Draw text *)
set_color text_color
moveto x y
draw_string "text"

(* Update display *)
synchronize ()
```

### Input Handling Pattern
```ocaml
if key_pressed () then
  let key = read_key () in
  match key with
  | ' ' -> (* pause/resume *)
  | 'q' -> (* quit *)
  | _ -> (* other keys *)
```

### Color Usage Pattern
```ocaml
(* Hex color constants *)
let gold = 0xFFD700

(* RGB color creation *)
let space_bg = Graphics.rgb 10 10 25

(* Predefined colors *)
set_color white
set_color black
```

---

## Performance Considerations

1. **Frame Rate Control:** Manual `synchronize()` with `auto_synchronize false` provides better control over frame timing (60 FPS target)

2. **Screen Clipping:** Bodies and labels only drawn if visible on screen (lines 100-101, 123-124)

3. **Trail Optimization:** Limited to 100 points per body with optional fading

4. **Buffered Rendering:** All drawing happens off-screen, then displayed with single `synchronize()` call

---

## External Resources

- **Official OCaml Graphics Documentation:** https://ocaml.org/api/Graphics.html
- **Graphics Module API Reference:** https://v2.ocaml.org/api/Graphics.html
- **Installation Guide:** See GRAPHICS_SETUP.md in project root

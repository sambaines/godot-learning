# Godot Learning Recap

A running log of everything covered across all chapters.

---

## Chapter 1 — Simple 3D World + Isometric Camera

**Goal:** A 3D scene with ground, reference geometry, a capsule player with WASD movement, and a fixed isometric camera that follows the player.

### Concepts Covered

#### Node Types
| Node | Purpose |
|---|---| 
| `Node3D` | Base class for anything in 3D space — position, rotation, scale |
| `CharacterBody3D` | Physics body for characters — handles collision, integrates with `move_and_slide()` |
| `StaticBody3D` | Non-moving collision body (e.g. ground, walls) |
| `MeshInstance3D` | Renders a mesh (geometry) in the scene |
| `CollisionShape3D` | Defines the invisible collision boundary for a physics body |
| `Camera3D` | The eye in the scene — position, rotation, projection type |

#### Movement & Physics
- **`_physics_process(delta)`** — runs every physics tick (not every frame); `delta` is time since last tick, used to make movement frame-rate independent
- **`velocity`** — built-in property on `CharacterBody3D`; set X/Z for horizontal movement, Y for vertical
- **`move_and_slide()`** — applies velocity and handles collision resolution automatically
- **`is_on_floor()`** — returns true when the body is grounded; used to gate gravity application
- **Gravity** — manually subtracted from `velocity.y` each tick when airborne: `velocity.y -= GRAVITY * delta`

#### Camera-Relative WASD
Raw input is a 2D vector (`input_dir`). To make movement relative to the camera angle:
1. Extract camera's forward vector: `-camera.global_basis.z`, flatten to XZ plane, normalize
2. Extract camera's right vector: `camera.global_basis.x`, flatten to XZ plane, normalize
3. Combine: `direction = (cam_forward * -input_dir.y + cam_right * input_dir.x).normalized()`

This means W always moves "into the screen" regardless of camera rotation.

#### Input System
- Actions defined in **Project Settings > Input Map** (e.g. `ui_up`, `ui_left`)
- Polled with `Input.is_action_pressed("action_name")` — returns true while held
- Each action maps to one or more keys/buttons

#### Diagonal Movement Normalization
Moving diagonally (e.g. W + D) would produce a vector of length ~1.41 instead of 1.0, making diagonal movement faster. Calling `.normalized()` on the direction vector fixes this — it scales the vector to always have length 1.

#### Camera Setup (Isometric-ish)
- Camera is a **child of the Player** node so it follows automatically 
- Position offset: Z back, Y up (e.g. `position = (0, 8, 6)`)
- X rotation: negative tilt to look downward (~-55°)
- Projection: `PERSPECTIVE` (can switch to `ORTHOGONAL` for true isometric look)

#### Scene Structure (World 1)
```
World (Node3D)
├── StaticBody3D (ground)
│   ├── Ground (MeshInstance3D)
│   └── CollisionShape3D
├── Box1, Box2, Box3 (MeshInstance3D) — reference geometry
├── Player (CharacterBody3D)
│   ├── Mesh (MeshInstance3D) — capsule
│   ├── Collision (CollisionShape3D)
│   └── Camera (Camera3D)
└── CanvasLayer
    └── Fade (ColorRect) — black overlay, starts transparent
```

---

## Chapter 2 — Scene Transitions (Portal)

**Goal:** A portal the player walks into that fades to black, transitions to a new scene, and fades back in — placing the player at the correct entry point.

### Concepts Covered

#### Area3D — Trigger Zones
- `Area3D` is a non-solid detection zone — things can pass through it
- Needs a `CollisionShape3D` child to define its bounds
- Emits a `body_entered` signal when a physics body overlaps it

#### Signals
- Godot's event system — nodes emit signals when things happen
- Connect a signal to a function: `body_entered.connect(_on_body_entered)`
- The connected function runs whenever the signal fires
- **Groups** — nodes can be tagged with group names (e.g. `"Player"`) and checked at runtime: `body.is_in_group("Player")`

#### Tween Animations
- `create_tween()` creates a Tween object for smooth property changes
- `tween.tween_property(node, "property_path", target_value, duration)` animates a property over time
- Example: `tween.tween_property(fade, "color:a", 1.0, 0.8)` fades a ColorRect to black over 0.8 seconds
- `await tween.finished` — pauses execution until the tween completes before moving on

#### await — Async Flow Control
- `await` pauses a function until a signal fires or a coroutine completes
- Used here to sequence: fade out → _then_ change scene
- Without it, the scene would change before the fade finished

#### Scene Transitions
- `get_tree().change_scene_to_file("res://world2.tscn")` — unloads current scene and loads a new one
- `res://` is the project root path prefix in Godot

#### Autoload / Global State
- Some data needs to survive a scene change (e.g. "which portal did I enter from?")
- **Autoloads** are nodes that persist for the entire lifetime of the game
- Defined in **Project Settings > Autoload** — given a name like `GameState`
- Accessible from any script by name: `GameState.entry_point = "south"`
- `game_state.gd` is intentionally minimal — just stores the value:
  ```gdscript
  extends Node
  var entry_point: String = ""
  ```

#### Marker3D — Named Entry Points
- `Marker3D` is a node with no visual representation — just a position in 3D space
- Named descriptively (e.g. `"south"`) to identify where a player should spawn
- World 2 has a `south` marker; the portal in World 1 sets `GameState.entry_point = "south"` before transitioning
- On load, `world2.gd` reads `GameState.entry_point`, finds the matching node, and teleports the player there:
  ```gdscript
  var marker = get_node_or_null(entry)
  if marker:
      player.global_position = marker.global_position
  ```

#### @onready
- Variables declared with `@onready` are assigned after the node's full scene tree is ready
- Prevents null reference errors when accessing child nodes at startup
- Example: `@onready var fade = $CanvasLayer/Fade`

#### Scene Structure (World 2)
```
World2 (Node3D)
├── StaticBody3D (ground)
│   ├── MeshInstance3D
│   └── CollisionShape3D
├── Player (CharacterBody3D)
│   ├── Mesh, Collision, Camera
├── CanvasLayer
│   └── Fade (ColorRect) — starts fully opaque (alpha: 1)
└── south (Marker3D) — entry point for portal transition
```

### Full Transition Flow
1. Player walks into `Portal` (Area3D) in World 1
2. `body_entered` signal fires → `_on_body_entered()` runs
3. Group check confirms it's the player
4. `fade_out()` tweens Fade alpha to 1.0 (black) over 0.8s
5. `await tween.finished` holds until done
6. `GameState.entry_point = "south"` written
7. `get_tree().change_scene_to_file("res://world2.tscn")` loads World 2
8. World 2's `_ready()` runs — reads `GameState.entry_point`
9. Finds `south` Marker3D, teleports player to its position
10. `fade_in()` tweens Fade alpha back to 0.0 (transparent) over 0.8s

---

## Chapter 2 Bonus — Portal Shader

**Goal:** Give the portal a visual effect using a custom GLSL-like shader.

### Shader Concepts

#### What is a Shader?
Code that runs directly on the GPU, once per pixel. Much faster than GDScript for visual effects. Godot uses a GLSL-inspired syntax.

#### Shader Types
- `shader_type spatial` — 3D surface shader (what we used)
- `shader_type canvas_item` — for 2D/UI elements

#### render_mode Flags
```glsl
render_mode unshaded, blend_mix, cull_disabled;
```
- `unshaded` — ignore scene lighting, draw flat colour
- `blend_mix` — enable alpha transparency
- `cull_disabled` — render both sides of the mesh (important for a flat quad viewed from above)

#### The fragment() Function
Runs once per pixel. You set:
- `ALBEDO` — the surface colour (RGB)
- `ALPHA` — transparency (0 = invisible, 1 = solid)

#### Built-in Shader Variables
| Variable | Meaning |
|---|---|
| `UV` | 2D texture coordinate — `(0,0)` to `(1,1)` across the surface |
| `TIME` | Auto-incrementing float, increases each frame — drives animation |

#### Portal Effect Breakdown
1. **Center the UV** — subtract `vec2(0.5)` to make (0,0) the center of the mesh
2. **Distance from center** — `length(center)` gives a float 0→0.5 across the quad
3. **Polar angle** — `atan(center.y, center.x)` gets the angle around the center
4. **Wobbly rings** — modulate `dist` with `sin(angle * N + TIME)` to create a pulsing wave along the angle axis
5. **sin() to rings** — `sin(dist * 48.0 - TIME * 4.8)` creates concentric rings that animate outward
6. **Sharpening** — `pow(abs(raw), 4.0)` pushes small values toward zero, widening the gaps between rings
7. **Soft edge mask** — `smoothstep(0.5, 0.1, dist)` fades the effect to invisible at the edges
8. **Color mixing** — `mix(blue, white, t)` blends between two colours based on the wave value
9. **Alpha** — `ALPHA = rings * 0.6` makes only the bright ring peaks visible; gaps are transparent

#### Key Math Functions
| Function | What it does |
|---|---|
| `sin(x)` | Wave between -1 and +1 |
| `length(v)` | Distance/magnitude of a vector |
| `atan(y, x)` | Angle of a 2D vector in radians |
| `smoothstep(edge0, edge1, x)` | Smooth 0→1 transition between two values |
| `mix(a, b, t)` | Linear blend — `t=0` gives `a`, `t=1` gives `b` |
| `pow(x, n)` | Raises x to the power n — sharpens/rounds curves |
| `abs(x)` | Absolute value — removes negative sign |
| `normalize(v)` | Scales a vector to length 1 |

---

## Particle Tips (Bonus)

- **`fixed_fps`** on `GPUParticles3D` — defaults to 30, which causes visible stepping in-game even at high framerates. Set to `0` to tie simulation to actual framerate.
- **`fract_delta`** — enable this alongside `fixed_fps = 0` for sub-frame interpolation and maximum smoothness.
- **Visibility AABB** — if particles are disappearing unexpectedly, the bounding box may be culling them. Use **Generate AABB** in the inspector.

---

## GDScript Quick Reference

```gdscript
# Variables
var speed = 5.0          # mutable
const GRAVITY = 9.81     # immutable

# @onready — assign after scene tree is ready
@onready var camera = $Camera

# Types
var name: String = "south"
var pos: Vector3 = Vector3(0, 1, 0)
var dir: Vector2 = Vector2.ZERO

# Conditionals
if input_dir != Vector2.ZERO:
    pass

# Functions
func _ready():           # called once when node enters scene tree
func _physics_process(delta):  # called every physics tick

# Signals
signal_name.connect(callback_function)

# Groups
body.is_in_group("Player")  # check membership
# (assigned in Godot editor Node > Groups panel)

# Scene tree
get_tree().change_scene_to_file("res://scene.tscn")
get_node_or_null("NodeName")

# Tween
var tween = create_tween()
tween.tween_property(node, "color:a", 1.0, 0.8)
await tween.finished
```

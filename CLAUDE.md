# Godot Learning Sandbox — CLAUDE.md

## What this is
A permanent 3D learning sandbox for Sam to learn Godot 4 / GDScript through compound, chapter-based building.
This is NOT a real game. It IS a real project that grows over time.

## Learning format
- Claude explains the concept first
- Shows the code
- Sam **types it out** (no copy-pasting)
- Sam explains it back in their own words
- Sam tries to break it to build intuition

## Tech
- Godot 4.x always
- GDScript always (not C#)
- Proper 3D (not 2D isometric or 2.5D)
- Y is the up axis in Godot 3D

## Sam's background
- Web dev background (HTML/CSS/JS) — GDScript will feel familiar
- Key mental shift for Sam: everything is a node in a tree; scenes are reusable chunks of that tree

## Chapter roadmap
| # | Title | Status |
|---|-------|--------|
| 1 | Simple 3D world + isometric camera | In progress |
| 2 | RO-style scene transitions (walk to edge/portal → fade → new scene → fade in → entry point) | Pending |
| 3+ | TBD | — |

## Next session — pick up here
- Sam is experimenting with camera Y rotation (45° diagonal gives classic isometric feel)
- Problem discovered: at Y=45°, WASD movement feels wrong because movement is in world space, not camera-relative
- **Next lesson: Option B — camera-relative movement.** Script calculates forward/right from camera orientation so movement always matches the view regardless of angle. This is the correct approach.
- Sam will settle on final camera values first, then we implement Option B.

## Chapter 1 — Simple 3D world + isometric camera
**Goal:** A 3D scene with ground, some reference geometry, a capsule player with WASD movement,
and a Camera3D set up with a fixed isometric-ish angle that follows the player.

**Godot concepts covered:**
- `Node3D` — base for anything in 3D space
- `CharacterBody3D` — player node with physics/movement
- `Camera3D` — position, rotation, projection (perspective vs orthographic)
- `MeshInstance3D` — ground plane and geometry
- `_physics_process()` — where movement code lives
- Input map — configuring key inputs

**Camera notes:**
- Y = up axis (height/elevation)
- X rotation = tilt angle (how steeply it looks down, ~-30° to -45°)
- X/Z offset = horizontal position relative to player
- Projection type: start with PERSPECTIVE, switch to ORTHOGONAL if preferred
- All values are tweakable — dial them in by feel

## Godot project location
The Godot project lives directly at `06_godot-learning/` — this directory IS the project root.

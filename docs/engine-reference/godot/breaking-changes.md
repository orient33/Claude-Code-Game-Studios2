# Godot — Breaking Changes

Last verified: 2026-05-15

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).
Agents MUST check this before suggesting Godot API calls.

---

## Godot 4.4 (Mid 2025)

### GDScript-Relevant Breaking Changes

| Area | Change | Action |
|------|--------|--------|
| OS | `read_string_from_stdin` gains required `buffer_size` param | Add argument |
| GraphEdit | `frame_rect_changed` signal param `Vector2` → `Rect2` | Update callbacks |
| RenderingDevice | `draw_list_begin` parameters removed/restructured | Update calls |
| @export_file | Paths now stored as `uid://` from Inspector | Be aware of mixed paths |
| Curve | Resource now enforces `min_value`/`max_value` range | Adjust if outside [0,1] |

### FileAccess Return Types

All `store_*` methods now return `bool` (was `void`). GDScript compatible — return value can be ignored.

### Shader Types

- `Shader.get_default_texture_parameter` returns `Texture` (was `Texture2D`)
- `Shader.set_default_texture_parameter` accepts `Texture` (was `Texture2D`)

### Behavior Changes

- Android sensors disabled by default — enable in Project Settings if needed
- CSG nodes now require manifold meshes (switched to Manifold library)
- Jolt Physics available as option (not yet default)

---

## Godot 4.5 (Late 2025)

### Renamed Methods

| Old API | New API | GDScript Compatible |
|---------|---------|---------------------|
| `JSONRPC.set_scope` | `JSONRPC.set_method` | NO |

### Removed Methods

| Method | Notes |
|--------|-------|
| `RenderingServer.instance_reset_physics_interpolation` | Removed entirely |
| `RenderingServer.instance_set_interpolated` | Removed entirely |

### RichTextLabel Breaking Changes

| Method | Change |
|--------|--------|
| `add_image` | `size_in_percent` replaced by `width_in_percent` + `height_in_percent`; new `alt_text` param |
| `update_image` | Same split as above |

### Behavior Changes

- **TileMapLayer**: `get_coords_for_body_rid()` returns different values (physics chunking default). Set `physics_quadrant_size = 1` for old behavior.
- **Resource.duplicate(true)**: Only deep-duplicates internal resources now. Use `Resource.duplicate_deep(DEEP_DUPLICATE_ALL)` for old behavior.
- **Navigation**: Regions update asynchronously by default. Toggle via `navigation/world/region_use_async_iterations`.
- **ProjectSettings.add_property_info()**: Now warns on missing/invalid keys.

### New Features (notable)

- AccessKit integration for accessibility
- Variadic arguments support
- `@abstract` annotation for classes
- Shader baker system
- SMAA anti-aliasing option

---

## Godot 4.6 (January 2026)

### Physics

- **Default 3D engine is now Jolt** (was Godot Physics). Change under `physics/3d/physics_engine`.
- 2D physics unchanged.

### Rendering — Glow Rework (CRITICAL for visual games)

| Property | Old Default | New Default |
|----------|-------------|-------------|
| `glow_blend_mode` | Soft Light (2) | Screen (1) |
| `glow_intensity` | 0.8 | 0.3 |
| `glow_levels/2` | 0.0 | 0.8 |
| `glow_levels/3` | 1.0 | 0.4 |
| `glow_levels/4` | 0.0 | 0.1 |
| `glow_levels/5` | 1.0 | 0.0 |

Screen blend mode is "significantly brighter." Mobile renderer glow completely rewritten — "will look significantly different."

### Rendering — Other

- **Default driver on Windows**: D3D12 (was Vulkan)
- **Volumetric fog**: Appears brighter (more physically accurate blending)
- `rendering/reflections/sky_reflections/roughness_layers`: 8 → 7

### FileAccess

- `get_as_text`: `skip_cr` parameter **removed**
- `create_temp`: `mode_flags` type changed `int` → `FileAccess.ModeFlags`

### AnimationPlayer (GDScript compatible)

Properties changed from `String` to `StringName` (transparent in GDScript):
- `assigned_animation`, `autoplay`, `current_animation`
- `get_queue()` returns `StringName[]`

### GUI Nodes

- `Control.grab_focus()` gains `hide_focus` optional param
- `PopupMenu.submenu_popup_delay`: 0.3 → 0.2

### Networking

- `StreamPeerTCP` methods moved to base class `StreamPeerSocket`
- `TCPServer` methods moved to base class `SocketServer`

### Navigation

- `AStar2D.get_point_path` returns **empty path** for disabled/solid points (was partial path)
- Same for `AStarGrid2D.get_id_path` and `get_point_path`

### Scene Format

- `load_steps` no longer written to `.tscn` files
- Unique node IDs saved to scene files (large VCS diffs on first resave)
- Both changes are backwards/forwards compatible

---

## Summary: What Matters for 星噬 (2D Mobile GDScript)

1. **Glow rework (4.6)** — Heavy glow use planned. Start with 4.6 defaults.
2. **AStar2D changes (4.6)** — Check empty return if using pathfinding.
3. **TileMapLayer (4.5)** — If using tilemaps for backgrounds.
4. **FileAccess.get_as_text (4.6)** — `skip_cr` removed.
5. **Scene format (4.6)** — Large diffs on first resave, cosmetic only.
6. **Mobile glow rewrite (4.6)** — Test on device, not just editor.

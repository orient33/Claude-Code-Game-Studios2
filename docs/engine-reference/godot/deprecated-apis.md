# Godot — Deprecated APIs

Last verified: 2026-05-15

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" equivalent. These are verified against official docs.

---

## Renamed / Moved APIs

| Don't Use | Use Instead | Version | GDScript OK? |
|-----------|-------------|---------|--------------|
| `JSONRPC.set_scope()` | `JSONRPC.set_method()` | 4.5 | NO |
| `RenderingServer.instance_reset_physics_interpolation()` | (removed, no replacement) | 4.5 | — |
| `RenderingServer.instance_set_interpolated()` | (removed, no replacement) | 4.5 | — |
| `RichTextLabel.add_image(..., size_in_percent)` | `add_image(..., width_in_percent, height_in_percent)` | 4.5 | NO |
| `FileAccess.get_as_text(skip_cr)` | `FileAccess.get_as_text()` (no param) | 4.6 | NO |
| `EditorFileDialog.add_side_menu()` | (removed entirely) | 4.6 | — |
| `StreamPeerTCP.disconnect_from_host()` | `StreamPeerSocket.disconnect_from_host()` | 4.6 | YES |
| `StreamPeerTCP.get_status()` | `StreamPeerSocket.get_status()` | 4.6 | YES |
| `StreamPeerTCP.poll()` | `StreamPeerSocket.poll()` | 4.6 | YES |
| `TCPServer.is_connection_available()` | `SocketServer.is_connection_available()` | 4.6 | YES |
| `TCPServer.is_listening()` | `SocketServer.is_listening()` | 4.6 | YES |
| `TCPServer.stop()` | `SocketServer.stop()` | 4.6 | YES |

## Changed Defaults (Don't Assume Old Values)

| Setting/Property | Old Default | New Default | Version |
|------------------|-------------|-------------|---------|
| 3D Physics Engine | Godot Physics | Jolt | 4.6 |
| Glow blend mode | Soft Light (2) | Screen (1) | 4.6 |
| Glow intensity | 0.8 | 0.3 | 4.6 |
| Windows render driver | Vulkan | D3D12 | 4.6 |
| PopupMenu submenu delay | 0.3s | 0.2s | 4.6 |
| MeshInstance3D skeleton | `NodePath("..")` | `NodePath("")` | 4.6 |
| sky_reflections roughness_layers | 8 | 7 | 4.6 |

## Shader Type Changes

| Don't Use | Use Instead | Version |
|-----------|-------------|---------|
| `Texture2D` in `Shader.get_default_texture_parameter` | `Texture` (base type) | 4.4 |
| `Texture2D` in `Shader.set_default_texture_parameter` | `Texture` (base type) | 4.4 |

## Patterns to Avoid

| Don't Do | Do Instead | Why |
|----------|-----------|-----|
| Rely on `@export_file` paths being `res://` | Check for both `uid://` and `res://` | 4.4 changed Inspector behavior |
| Use `Curve` with points outside [0,1] without setting range | Set `min_value`/`max_value` explicitly | 4.4 enforces range |
| Assume `TileMapLayer.get_coords_for_body_rid()` precision | Set `physics_quadrant_size = 1` if needed | 4.5 chunking default |
| Call `AStar2D.get_point_path()` expecting path through disabled points | Check return for empty array | 4.6 behavior change |
| Use `Resource.duplicate(true)` to copy external resources | Use `Resource.duplicate_deep(DEEP_DUPLICATE_ALL)` | 4.5 behavior change |

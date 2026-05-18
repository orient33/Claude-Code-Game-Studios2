# Godot — Current Best Practices

Last verified: 2026-05-15 | Engine: Godot 4.6

Practices that are **new or changed** since the model's training data (~4.3).
Agents MUST follow these over any older patterns they may have learned.

---

## GDScript (4.5+ idioms)

### Static Typing (ENFORCED in this project)

```gdscript
# REQUIRED — fully typed
var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO

func calculate_velocity(delta: float) -> Vector2:
    return direction * speed * delta

# FORBIDDEN — untyped variables and functions
var speed = 100.0
func calculate_velocity(delta):
    return direction * speed * delta
```

### @abstract (4.5+)

```gdscript
@abstract
class_name CelestialBody
extends Area2D
# Cannot be instantiated directly — must subclass
```

### Typed Signals

```gdscript
signal health_changed(new_health: int, max_health: int)
signal evolution_triggered(new_stage: int)

# Connect with typed callables
health_changed.connect(_on_health_changed)
```

### StringName for Performance

```gdscript
# Use StringName for frequent lookups (input actions, animation names)
const ACTION_MOVE := &"move"
const ANIM_IDLE := &"idle"

if Input.is_action_pressed(ACTION_MOVE):
    pass
```

---

## 2D Rendering (Mobile)

### Renderer Selection

- Set `rendering/renderer/rendering_method` to `mobile` for mobile builds
- Mobile renderer uses Forward+ with mobile-specific optimizations
- Vulkan Mobile is the correct backend for iOS/Android

### Glow (4.6 rewrite)

```
# 4.6 defaults — start here and adjust:
glow_blend_mode = Screen (1)
glow_intensity = 0.3
# Mobile glow was completely rewritten — always test on device
```

### Performance Tips

- Use `CanvasGroup` to batch draw calls on complex node trees
- `GPUParticles2D` preferred over `CPUParticles2D` on modern mobile GPUs
- Set `CanvasItem.visibility_layer` to skip processing off-screen nodes
- Use object pooling for frequently spawned/despawned nodes

### Texture Settings for Vector Art

```
# Project Settings for crisp vector graphics:
rendering/textures/canvas_textures/default_texture_filter = Linear
rendering/textures/canvas_textures/default_texture_repeat = Disabled
```

---

## Tooling

- **ripgrep has no `gdscript` type**: `*.gd` is registered under `gap` (GAP programming language).
  `rg --type gdscript` is a hard error — the search never executes.
  Always use `rg --glob "*.gd"` (shell) or `glob: "*.gd"` (Grep tool) to filter GDScript files.

## Platform (4.5+)
## Physics (2D)

### Area2D for Detection (our use case)

```gdscript
# Standard pattern for collision detection in 星噬:
class_name GravityField
extends Area2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
    if body is CelestialBody:
        _process_collision(body)
```

### CollisionShape2D

- Use `CircleShape2D` for celestial bodies (performance optimal for circles)
- Update shape radius when body grows — don't recreate the shape

---

## Scene Organization

### Node Naming

- Root nodes: PascalCase matching scene file
- Child nodes: PascalCase descriptive names
- Signal connections: `_on_<node_name>_<signal_name>` pattern

### Resource Management

- Use `uid://` paths (4.4+ default from Inspector)
- Unique node IDs are auto-generated in 4.6 — don't manually edit `.tscn` files
- `load()` vs `preload()`: use `preload` for always-needed resources, `load` for conditional

---

## Mobile Export Checklist

- Test on actual devices — emulator ≠ device for touch and performance
- Set `display/window/handheld/orientation` in Project Settings
- Minimum touch target: 44x44 dp (physical)
- Handle notch/safe area via `DisplayServer.get_display_safe_area()`
- Test battery drain — disable unnecessary processing when paused

---

## Navigation (if needed later)

- Regions update asynchronously by default (4.5+)
- `get_point_path()` returns empty array for disabled points (4.6)
- Always check return value before using path data

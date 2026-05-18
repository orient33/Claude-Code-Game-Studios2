# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is drag-to-move + gravity + eat/grow + evolve fun for 15+ minutes?
# Date: 2026-05-15
extends Area2D

signal body_consumed(mass_value: float)
signal player_killed()
signal evolution_triggered(new_stage: int)
signal game_won()

var current_stage: int = 1
var stage_progress: float = 0.0
var absolute_mass: float = 50.0

var is_dragging: bool = false
var touch_offset: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var is_invincible: bool = false

const MAX_SPEED: float = 800.0
const SMOOTHING: float = 0.1
const SNAP_THRESHOLD: float = 2.0
const COLLISION_SCALE: float = 0.85
const BASE_RADIUS: float = 28.0
const RADIUS_SCALE: Array = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
const INTRA_STAGE_GROWTH: float = 0.6
const STAGE_THRESHOLDS: Array = [100.0, 300.0, 900.0, 2700.0, 8100.0]
const GRAVITY_RANGE_MULT: float = 3.0
const GRAVITY_STRENGTH: float = 150.0
const STAGE_COLORS: Array = [
	Color(0.5, 0.6, 0.8, 1.0),   # 尘埃: 冷蓝灰
	Color(0.6, 0.45, 0.3, 1.0),  # 陨石: 棕橙岩石
	Color(0.4, 0.4, 0.5, 1.0),   # 小行星: 灰蓝金属
	Color(0.2, 0.5, 0.9, 1.0),   # 行星: 深蓝大气
	Color(1.0, 0.85, 0.3, 1.0),  # 恒星: 金黄炽热
	Color(0.15, 0.0, 0.25, 1.0), # 黑洞: 深紫虚空
]
const STAGE_GLOW_COLORS: Array = [
	Color(0.7, 0.8, 1.0, 0.2),
	Color(0.9, 0.6, 0.3, 0.3),
	Color(0.6, 0.6, 0.8, 0.2),
	Color(0.3, 0.6, 1.0, 0.4),
	Color(1.0, 0.9, 0.5, 0.6),
	Color(0.5, 0.0, 0.8, 0.5),
]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("player")
	target_position = position
	_update_visual()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			touch_offset = event.position - position
			target_position = position
		else:
			is_dragging = false
	elif event is InputEventScreenDrag and is_dragging:
		target_position = event.position - touch_offset

func _physics_process(delta: float) -> void:
	if is_dragging:
		var direction: Vector2 = target_position - position
		var distance: float = direction.length()
		if distance < SNAP_THRESHOLD:
			position = target_position
		else:
			var speed: float = minf(distance / SMOOTHING, MAX_SPEED)
			position += direction.normalized() * speed * delta
	_clamp_to_viewport()
	_apply_gravity(delta)

func _clamp_to_viewport() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var r: float = get_visual_radius() + 10.0
	position.x = clampf(position.x, r, vp_size.x - r)
	position.y = clampf(position.y, r, vp_size.y - r)


func _apply_gravity(delta: float) -> void:
	var gravity_radius: float = get_visual_radius() * GRAVITY_RANGE_MULT
	var bodies: Array = get_tree().get_nodes_in_group("celestial_bodies")
	for body in bodies:
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		if body.mass_value >= absolute_mass:
			continue
		var dist: float = position.distance_to(body.position)
		if dist > gravity_radius:
			continue
		var effective_dist: float = maxf(dist - get_visual_radius(), 10.0)
		var force: float = GRAVITY_STRENGTH / effective_dist
		var dir: Vector2 = (position - body.position).normalized()
		body.velocity += dir * force * delta

func get_visual_radius() -> float:
	var scale_idx: int = clampi(current_stage - 1, 0, RADIUS_SCALE.size() - 1)
	# Cap stage_progress contribution to prevent infinite growth at stage 6
	var effective_progress: float = minf(stage_progress, 1.0)
	var radius: float = BASE_RADIUS * RADIUS_SCALE[scale_idx] * (1.0 + effective_progress * INTRA_STAGE_GROWTH)
	return minf(radius, 55.0)  # Absolute max: never bigger than 55px

func get_gravity_radius() -> float:
	return get_visual_radius() * GRAVITY_RANGE_MULT

func add_mass(value: float) -> void:
	if value <= 0.0:
		return
	var threshold_idx: int = clampi(current_stage - 1, 0, STAGE_THRESHOLDS.size() - 1)
	stage_progress += value / STAGE_THRESHOLDS[threshold_idx]
	absolute_mass += value
	if stage_progress >= 1.0 and current_stage < 6:
		var overflow: float = stage_progress - 1.0
		current_stage += 1
		stage_progress = overflow
		if current_stage >= 6:
			game_won.emit()
		_do_evolution()
	_update_visual()

func _do_evolution() -> void:
	is_invincible = true
	evolution_triggered.emit(current_stage)
	# Flash white briefly
	modulate = Color.WHITE
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_callback(_end_evolution)

func _end_evolution() -> void:
	modulate = Color.WHITE
	_update_visual()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.5)
	tween.tween_callback(func(): is_invincible = false)

func _update_visual() -> void:
	var radius: float = get_visual_radius()
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = radius * COLLISION_SCALE
	queue_redraw()


func _draw() -> void:
	var radius: float = get_visual_radius()
	var idx: int = clampi(current_stage - 1, 0, STAGE_COLORS.size() - 1)
	var color: Color = STAGE_COLORS[idx]
	var glow: Color = STAGE_GLOW_COLORS[idx]

	# Gravity field indicator (very faint)
	draw_arc(Vector2.ZERO, get_gravity_radius(), 0, TAU, 48, Color(1, 1, 1, 0.04), 1.0)

	match current_stage:
		1:  # 尘埃 — 单层模糊圆
			draw_circle(Vector2.ZERO, radius, color * Color(1, 1, 1, 0.7))
		2:  # 陨石 — 实心 + 表面纹理线
			draw_circle(Vector2.ZERO, radius, color)
			for i in range(3):
				var angle: float = TAU * i / 3.0 + 0.5
				var start: Vector2 = Vector2.from_angle(angle) * radius * 0.3
				var end: Vector2 = Vector2.from_angle(angle + 0.4) * radius * 0.8
				draw_line(start, end, color * Color(0.7, 0.7, 0.7, 0.5), 1.5)
		3:  # 小行星 — 实心 + 密度环
			draw_circle(Vector2.ZERO, radius, color)
			draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 24, glow, 2.0)
		4:  # 行星 — 实心 + 大气光晕
			draw_circle(Vector2.ZERO, radius * 1.15, glow)
			draw_circle(Vector2.ZERO, radius, color)
			draw_arc(Vector2.ZERO, radius * 1.1, 0, TAU, 32, glow * Color(1,1,1,0.8), 3.0)
		5:  # 恒星 — 发光核心 + 光芒
			draw_circle(Vector2.ZERO, radius * 1.3, glow * Color(1,1,1,0.3))
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE * Color(1,1,1,0.8))
			for i in range(6):
				var angle: float = TAU * i / 6.0
				var tip: Vector2 = Vector2.from_angle(angle) * radius * 1.5
				draw_line(Vector2.ZERO, tip, glow * Color(1,1,1,0.4), 1.5)
		6:  # 黑洞 — 黑核 + 吸积盘
			draw_arc(Vector2.ZERO, radius * 1.4, 0, TAU, 32, Color(0.6, 0.2, 0.9, 0.3), 4.0)
			draw_arc(Vector2.ZERO, radius * 1.1, 0, TAU, 32, Color(0.8, 0.4, 1.0, 0.5), 2.5)
			draw_circle(Vector2.ZERO, radius, Color(0.02, 0.0, 0.05, 1.0))
			draw_arc(Vector2.ZERO, radius * 0.9, 0, TAU, 24, Color(0.4, 0.0, 0.6, 0.3), 1.5)

func on_area_entered(area: Area2D) -> void:
	if is_invincible:
		return
	if not area.is_in_group("celestial_bodies"):
		return
	var body_mass: float = area.mass_value
	if absolute_mass > body_mass:
		# Consume
		body_consumed.emit(body_mass)
		add_mass(body_mass)
		area.queue_free()
	else:
		# Death
		player_killed.emit()
		_die()

func _die() -> void:
	is_invincible = true
	modulate = Color(1, 0.3, 0.3)
	player_killed.emit()

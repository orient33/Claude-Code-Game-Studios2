# PROTOTYPE - NOT FOR PRODUCTION
extends Node2D

@export var player: Area2D
var wave_timer: float = 0.0
const WAVE_INTERVAL: float = 2.0
const WAVE_SIZE: int = 5
const MAX_ACTIVE: int = 20
const FOOD_RATIO: float = 0.85
const BODY_SCENE: PackedScene = preload("res://celestial_body.tscn")

func _physics_process(delta: float) -> void:
	if not player:
		return
	wave_timer += delta
	if wave_timer >= WAVE_INTERVAL:
		wave_timer = 0.0
		_spawn_wave()

func _spawn_wave() -> void:
	var active_count: int = get_tree().get_nodes_in_group("celestial_bodies").size()
	if active_count >= MAX_ACTIVE:
		return

	var player_mass: float = player.absolute_mass if player.absolute_mass > 0 else 50.0

	# At stage 6 (black hole), almost everything is food — you're the apex predator
	var effective_food_ratio: float = FOOD_RATIO
	if player.current_stage >= 6:
		effective_food_ratio = 0.95

	for i in range(WAVE_SIZE):
		if active_count + i >= MAX_ACTIVE:
			break
		var is_food: bool = randf() < effective_food_ratio
		_spawn_body(player_mass, is_food)

func _spawn_body(player_mass: float, is_food: bool) -> void:
	var body: Area2D = BODY_SCENE.instantiate()
	var vp: Vector2 = get_viewport_rect().size

	# Spawn from screen edges
	var edge: int = randi() % 4
	var spawn_pos: Vector2
	var margin: float = 80.0
	match edge:
		0: spawn_pos = Vector2(randf_range(0, vp.x), -margin)
		1: spawn_pos = Vector2(randf_range(0, vp.x), vp.y + margin)
		2: spawn_pos = Vector2(-margin, randf_range(0, vp.y))
		3: spawn_pos = Vector2(vp.x + margin, randf_range(0, vp.y))

	# Direction: toward player with jitter
	var direction: Vector2 = (player.position - spawn_pos).normalized()
	direction = direction.rotated(randf_range(-0.4, 0.4))

	var mass: float
	var color: Color
	var radius: float
	var speed: float

	# Stage-based color palettes for food
	var food_palettes: Array = [
		[Color(0.5, 0.6, 0.9), Color(0.4, 0.5, 0.7), Color(0.6, 0.7, 1.0)],   # 尘埃阶段: 冷蓝
		[Color(0.7, 0.5, 0.3), Color(0.6, 0.4, 0.2), Color(0.8, 0.6, 0.4)],   # 陨石阶段: 棕橙
		[Color(0.5, 0.5, 0.7), Color(0.4, 0.4, 0.6), Color(0.6, 0.6, 0.8)],   # 小行星: 灰蓝
		[Color(0.3, 0.6, 0.9), Color(0.2, 0.5, 0.8), Color(0.4, 0.7, 1.0)],   # 行星: 蓝绿
		[Color(1.0, 0.8, 0.3), Color(0.9, 0.7, 0.2), Color(1.0, 0.9, 0.5)],   # 恒星: 金色
		[Color(0.5, 0.2, 0.8), Color(0.4, 0.1, 0.7), Color(0.6, 0.3, 0.9)],   # 黑洞: 紫
	]
	var threat_palettes: Array = [
		Color(0.9, 0.3, 0.3),  # 各阶段威胁色略有变化
		Color(0.9, 0.4, 0.2),
		Color(0.8, 0.2, 0.3),
		Color(0.7, 0.1, 0.2),
		Color(0.9, 0.2, 0.1),
		Color(0.6, 0.0, 0.4),
	]
	var stage_idx: int = clampi(player.current_stage - 1, 0, 5)

	if is_food:
		var ratio: float = randf_range(0.02, 0.5)
		ratio = ratio * ratio  # bias small
		mass = maxf(player_mass * ratio, 5.0)
		var player_r: float = player.get_visual_radius()
		radius = clampf(player_r * randf_range(0.2, 0.7), 4.0, player_r * 0.7)
		var palette: Array = food_palettes[stage_idx]
		color = palette[randi() % palette.size()]
		color = color * Color(randf_range(0.85, 1.15), randf_range(0.85, 1.15), randf_range(0.85, 1.15))
		speed = randf_range(40.0, 100.0)
		body.setup(mass, color, radius, false, direction, speed)
	else:
		var ratio: float = randf_range(1.2, 2.0)
		mass = player_mass * ratio
		var player_r: float = player.get_visual_radius()
		radius = clampf(player_r * randf_range(1.1, 1.4), 20.0, 70.0)  # Absolute cap 70px
		color = threat_palettes[stage_idx]
		color = color * Color(randf_range(0.9, 1.1), randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		speed = randf_range(25.0, 55.0)
		body.setup(mass, color, radius, true, direction, speed)

	body.position = spawn_pos
	add_child(body)

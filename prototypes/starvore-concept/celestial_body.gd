# PROTOTYPE - NOT FOR PRODUCTION
extends Area2D

var mass_value: float = 10.0
var velocity: Vector2 = Vector2.ZERO
var drift_speed: float = 80.0
var visual_radius: float = 12.0
var body_color: Color = Color.WHITE
var is_threat: bool = false

func _ready() -> void:
	add_to_group("celestial_bodies")
	_update_shape()

func _physics_process(delta: float) -> void:
	position += (velocity + drift_speed * velocity.normalized()) * delta if velocity.length() > 0 else Vector2.ZERO
	# Basic drift if no velocity set yet
	if velocity.length() < 1.0:
		position += Vector2.from_angle(rotation) * drift_speed * delta
	else:
		position += velocity * delta
	_check_offscreen()

func setup(p_mass: float, p_color: Color, p_radius: float, p_is_threat: bool, direction: Vector2, speed: float) -> void:
	mass_value = p_mass
	body_color = p_color
	visual_radius = p_radius
	is_threat = p_is_threat
	drift_speed = speed
	velocity = direction * speed
	_update_shape()
	queue_redraw()

func _update_shape() -> void:
	if $CollisionShape2D and $CollisionShape2D.shape:
		$CollisionShape2D.shape.radius = visual_radius

func _draw() -> void:
	if is_threat:
		# Draw with spikes (danger indicator)
		draw_circle(Vector2.ZERO, visual_radius, body_color)
		var spike_count: int = clampi(int(mass_value / 100.0) + 3, 3, 8)
		for i in range(spike_count):
			var angle: float = TAU * i / spike_count
			var spike_base: Vector2 = Vector2.from_angle(angle) * visual_radius
			var spike_tip: Vector2 = Vector2.from_angle(angle) * (visual_radius * 1.4)
			draw_line(spike_base, spike_tip, body_color * Color(1, 1, 1, 0.8), 2.0)
	else:
		# Draw smooth circle (food)
		draw_circle(Vector2.ZERO, visual_radius, body_color)
		# Subtle inner glow
		draw_circle(Vector2.ZERO, visual_radius * 0.4, body_color * Color(1.3, 1.3, 1.3, 0.5))

func _check_offscreen() -> void:
	# Remove if too far from any player (camera-independent)
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_pos: Vector2 = players[0].position
		if position.distance_to(player_pos) > 2000.0:
			queue_free()
	else:
		var vp: Vector2 = get_viewport_rect().size
		if position.x < -200 or position.x > vp.x + 200 or \
		   position.y < -200 or position.y > vp.y + 200:
			queue_free()

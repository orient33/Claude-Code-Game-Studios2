# PROTOTYPE - NOT FOR PRODUCTION
extends Node2D

@onready var player: Area2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var stage_label: Label = $UI/StageLabel
@onready var progress_label: Label = $UI/ProgressLabel
@onready var win_panel: ColorRect = $UI/WinPanel
@onready var win_label: Label = $UI/WinPanel/WinLabel
@onready var restart_button: Button = $UI/WinPanel/RestartButton
@onready var death_panel: ColorRect = $UI/DeathPanel
@onready var death_label: Label = $UI/DeathPanel/DeathLabel
@onready var death_restart: Button = $UI/DeathPanel/DeathRestart

var game_over: bool = false

func _ready() -> void:
	spawner.player = player
	player.evolution_triggered.connect(_on_evolution)
	player.player_killed.connect(_on_death)
	player.body_consumed.connect(_on_consume)
	player.game_won.connect(_on_win)
	win_panel.visible = false
	death_panel.visible = false

func _process(_delta: float) -> void:
	if game_over:
		return
	if stage_label:
		var stage_names: Array = ["尘埃", "陨石", "小行星", "行星", "恒星", "黑洞"]
		var idx: int = clampi(player.current_stage - 1, 0, 5)
		stage_label.text = stage_names[idx]
	if progress_label:
		progress_label.text = "%d%%" % int(player.stage_progress * 100)

func _on_evolution(new_stage: int) -> void:
	print("EVOLUTION! Now stage: ", new_stage)

func _on_death() -> void:
	game_over = true
	get_tree().paused = true
	var stage_names: Array = ["尘埃", "陨石", "小行星", "行星", "恒星", "黑洞"]
	var idx: int = clampi(player.current_stage - 1, 0, 5)
	death_label.text = "被吞噬了...\n最高形态: %s\n进度: %d%%" % [stage_names[idx], int(player.stage_progress * 100)]
	death_panel.visible = true

func _on_consume(_mass: float) -> void:
	pass

func _on_win() -> void:
	game_over = true
	get_tree().paused = true
	win_panel.visible = true

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

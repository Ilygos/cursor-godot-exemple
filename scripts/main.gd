extends Node2D

## Main scene that manages the game state and connects player to HUD

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const ENEMY_SPAWN_INTERVAL: float = 3.0
const ENEMY_SPAWN_DISTANCE: float = 500.0

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var world: Node2D = $World

var enemy_spawn_timer: float = 0.0
var is_gameover: bool = false

func _ready() -> void:
	# Add to main group for enemy to find
	add_to_group("main")
	
	# Connect player signals to HUD
	if player and hud:
		player.health_changed.connect(_on_player_health_changed)
		player.score_changed.connect(_on_player_score_changed)
		player.player_died.connect(_on_player_died)
	
	# Connect HUD signals
	if hud:
		hud.pause_requested.connect(_on_pause_requested)
		hud.restart_requested.connect(_on_restart_requested)
		hud.quit_requested.connect(_on_quit_requested)

func _on_player_health_changed(new_health: int) -> void:
	if hud:
		hud.update_health(new_health)

func _on_player_score_changed(new_score: int) -> void:
	if hud:
		hud.update_score(new_score)

func _process(delta: float) -> void:
	if is_gameover:
		return
	
	# Spawn enemies periodically
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= ENEMY_SPAWN_INTERVAL:
		enemy_spawn_timer = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	if not player or not ENEMY_SCENE:
		return
	
	# Spawn enemy at a distance from player
	var spawn_angle: float = randf() * TAU
	var spawn_offset: Vector2 = Vector2(cos(spawn_angle), sin(spawn_angle)) * ENEMY_SPAWN_DISTANCE
	var spawn_position: Vector2 = player.global_position + spawn_offset
	
	var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	if enemy:
		enemy.global_position = spawn_position
		add_child(enemy)
		
		# Connect enemy killed signal
		if enemy.has_signal("enemy_killed"):
			enemy.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed() -> void:
	if player:
		player.add_score(10)

func _on_player_died() -> void:
	is_gameover = true
	if hud:
		hud.show_gameover()

func _on_restart_requested() -> void:
	# Reset game state
	is_gameover = false
	
	# Remove all enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Reset player
	if player:
		player.reset()
		player.global_position = Vector2(100, 700)
	
	# Hide gameover popup
	if hud:
		hud.hide_gameover()
	
	# Reset spawn timer
	enemy_spawn_timer = 0.0

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_pause_requested() -> void:
	if not is_gameover:
		get_tree().paused = not get_tree().paused


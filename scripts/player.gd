extends CharacterBody2D

## Player character with gravity and movement

const GRAVITY: float = 980.0
const SPEED: float = 200.0
const JUMP_VELOCITY: float = -400.0

const MAX_HEALTH: int = 3
const INITIAL_SCORE: int = 0
const ATTACK_RANGE: float = 100.0
const ATTACK_COOLDOWN: float = 0.5
const ATTACK_SLOWDOWN_SCALE: float = 0.3
const ATTACK_SLOWDOWN_DURATION: float = 0.1

signal health_changed(new_health: int)
signal score_changed(new_score: int)
signal player_died

var can_double_jump: bool = false
var health: int = MAX_HEALTH
var score: int = INITIAL_SCORE
var _attack_cooldown: float = 0.0
var _is_playing_hurt: bool = false
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Add to player group for enemy to find
	add_to_group("player")
	
	# Make sure the camera is current
	var camera: Camera2D = $Camera2D
	if camera:
		camera.make_current()
	
	# Initialize health and score
	health = MAX_HEALTH
	score = INITIAL_SCORE
	health_changed.emit(health)
	score_changed.emit(score)

func _physics_process(delta: float) -> void:
	# Don't process movement if dead
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Reset double jump when landing on the floor
		can_double_jump = false
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			# Regular jump from the ground
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
		elif can_double_jump:
			# Double jump in the air
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
	
	# Handle horizontal movement
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		# Flip sprite based on movement direction
		_update_sprite_direction(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle attack cooldown
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	
	# Handle attack (x key)
	if Input.is_key_pressed(KEY_X) and _attack_cooldown <= 0.0:
		_attack()
		_attack_cooldown = ATTACK_COOLDOWN
	
	move_and_slide()

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	
	health = max(0, health - amount)
	health_changed.emit(health)
	
	if health <= 0:
		# Player is dying, play die animation
		is_dead = true
		if sprite:
			sprite.play("die")
		# Stop movement
		velocity = Vector2.ZERO
		player_died.emit()
	else:
		# Play hurt animation if not dead
		if sprite and not _is_playing_hurt:
			_is_playing_hurt = true
			sprite.play("hurt")
			# Calculate animation duration and return to idle after
			var hurt_animation_duration: float = _get_animation_duration("hurt")
			if hurt_animation_duration > 0.0:
				await get_tree().create_timer(hurt_animation_duration).timeout
				_is_playing_hurt = false
				if sprite and sprite.animation == "hurt" and not is_dead:
					sprite.play("idle")

func _attack() -> void:
	# Find all enemies in attack range
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var hit_enemy: bool = false
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var enemy_pos: Vector2 = enemy.global_position
		var distance: float = global_position.distance_to(enemy_pos)
		
		if distance <= ATTACK_RANGE:
			if enemy.has_method("take_damage"):
				enemy.take_damage()
				hit_enemy = true
	
	# Apply slowdown effect only if an enemy was hit
	if hit_enemy:
		_apply_attack_slowdown()

func _apply_attack_slowdown() -> void:
	# Apply brief slowdown effect for impact (hit stop)
	Engine.time_scale = ATTACK_SLOWDOWN_SCALE
	await get_tree().create_timer(ATTACK_SLOWDOWN_DURATION / ATTACK_SLOWDOWN_SCALE).timeout
	Engine.time_scale = 1.0

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func _update_sprite_direction(direction: float) -> void:
	# Flip sprite based on horizontal direction
	if sprite:
		if direction > 0:
			# Moving right, flip horizontally (facing right)
			sprite.flip_h = false
		elif direction < 0:
			# Moving left, flip horizontally (facing left)
			sprite.flip_h = true

func _get_animation_duration(anim_name: String) -> float:
	# Calculate total duration of an animation
	if not sprite or not sprite.sprite_frames:
		return 0.0
	
	if not sprite.sprite_frames.has_animation(anim_name):
		return 0.0
	
	var frame_count: int = sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count == 0:
		return 0.0
	
	# Get duration of first frame and speed to calculate total duration
	# Each frame has duration 1.0, and speed is 5.0, so total = frame_count / speed
	var speed: float = sprite.sprite_frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		speed = 1.0
	
	# Assuming each frame has duration 1.0 (default)
	return frame_count / speed

func reset() -> void:
	health = MAX_HEALTH
	score = INITIAL_SCORE
	_attack_cooldown = 0.0
	_is_playing_hurt = false
	is_dead = false
	if sprite:
		sprite.play("idle")
	health_changed.emit(health)
	score_changed.emit(score)


extends CharacterBody2D

## Enemy that moves towards the player and damages them on contact

const GRAVITY: float = 980.0
const SPEED: float = 100.0
const JUMP_VELOCITY: float = -350.0
const DAMAGE: int = 1
const DAMAGE_COOLDOWN: float = 1.0
const WALL_DETECTION_DISTANCE: float = 20.0
const WALL_JUMP_COOLDOWN: float = 0.3

signal enemy_killed

var player: Node2D = null
var is_dead: bool = false
var _is_playing_hurt: bool = false
var _damage_cooldown: float = 0.0
var _wall_jump_cooldown: float = 0.0
var _last_wall_direction: int = 0

@onready var damage_area: Area2D = $DamageArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Add to enemies group for attack detection
	add_to_group("enemies")
	
	# Connect damage area signal for collision detection
	if damage_area:
		damage_area.body_entered.connect(_on_body_entered)
	
	# Find player in the scene tree
	_find_player()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update cooldowns
	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta
	if _wall_jump_cooldown > 0.0:
		_wall_jump_cooldown -= delta
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Find player if not already found
	if not player:
		_find_player()
	
	# Move towards player
	if player:
		_move_towards_player()
	
	move_and_slide()

func _move_towards_player() -> void:
	var player_pos: Vector2 = player.global_position
	var enemy_pos: Vector2 = global_position
	
	# Determine horizontal direction
	var horizontal_direction: float = sign(player_pos.x - enemy_pos.x)
	
	# Check for walls using both raycast and is_on_wall()
	var wall_ahead: bool = _check_wall_ahead(horizontal_direction) or (is_on_wall() and abs(velocity.x) < 10.0)
	
	# Move horizontally
	if not wall_ahead:
		velocity.x = horizontal_direction * SPEED
		_last_wall_direction = 0
	else:
		# Hit a wall, try to jump
		if _wall_jump_cooldown <= 0.0 and is_on_floor():
			velocity.y = JUMP_VELOCITY
			_wall_jump_cooldown = WALL_JUMP_COOLDOWN
			_last_wall_direction = int(horizontal_direction)
		# Still try to move in the direction, but slower when hitting wall
		velocity.x = horizontal_direction * SPEED * 0.3
	
	# Flip sprite based on movement direction
	_update_sprite_direction(horizontal_direction)
	
	# Jump if player is above and we're on the ground
	if is_on_floor() and player_pos.y < enemy_pos.y - 30.0:
		# Player is above, try to jump
		if _wall_jump_cooldown <= 0.0:
			velocity.y = JUMP_VELOCITY
			_wall_jump_cooldown = WALL_JUMP_COOLDOWN

func _update_sprite_direction(direction: float) -> void:
	# Flip sprite based on horizontal direction
	if sprite:
		if direction > 0:
			# Moving right, flip horizontally (facing right)
			sprite.flip_h = false
		elif direction < 0:
			# Moving left, flip horizontally (facing left)
			sprite.flip_h = true

func _check_wall_ahead(direction: float) -> bool:
	# Cast a ray to check for walls
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(direction * WALL_DETECTION_DISTANCE, 0)
	)
	query.exclude = [self]
	query.collision_mask = 1  # Collision layer 1 (ground)
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result.size() > 0

func _find_player() -> void:
	# Search for player in the scene tree
	var main: Node2D = get_tree().get_first_node_in_group("main") as Node2D
	if main:
		player = main.get_node_or_null("Player") as Node2D
	
	# Alternative: search by node name or group
	if not player:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		player = get_tree().get_first_node_in_group("Player") as Node2D

func _on_body_entered(body: Node2D) -> void:
	if is_dead or _is_playing_hurt or _damage_cooldown > 0.0:
		return
	
	# Check if the body is the player
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		_damage_cooldown = DAMAGE_COOLDOWN

func take_damage() -> void:
	if is_dead:
		return
	
	is_dead = true
	_is_playing_hurt = true
	
	# Play hurt animation before disappearing
	if sprite:
		sprite.play("hurt")
		# Stop movement
		velocity = Vector2.ZERO
		# Calculate animation duration and remove enemy after
		var hurt_animation_duration: float = _get_animation_duration("hurt")
		if hurt_animation_duration > 0.0:
			await get_tree().create_timer(hurt_animation_duration).timeout
			enemy_killed.emit()
			queue_free()
		else:
			# If duration calculation fails, use a default duration
			await get_tree().create_timer(0.8).timeout
			enemy_killed.emit()
			queue_free()
	else:
		# If no sprite, just disappear immediately
		enemy_killed.emit()
		queue_free()

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


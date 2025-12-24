extends Node2D

## World scene that procedurally generates a level with collision and sprites

const TILE_SIZE := 16  # Based on credits, world_tileset is 16x16
const LEVEL_WIDTH := 100
const LEVEL_HEIGHT := 50

@onready var tile_map: TileMap = $TileMap

func _ready() -> void:
	_generate_level()

func _generate_level() -> void:
	# Generate a continuous level with no holes
	# Create terrain with varying heights but always connected
	var ground_level: int = LEVEL_HEIGHT - 1
	var previous_height: int = ground_level
	
	# Generate continuous terrain
	for x in range(LEVEL_WIDTH):
		# Vary height slightly but ensure continuity
		var height_variation: int = randi_range(-2, 2)
		var current_height: int = clamp(previous_height + height_variation, ground_level - 5, ground_level)
		
		# Ensure we don't create too steep slopes
		if abs(current_height - previous_height) > 1:
			current_height = previous_height + sign(current_height - previous_height) as int
		
		# Fill from ground level up to current height to prevent holes
		for y in range(current_height, LEVEL_HEIGHT):
			_set_tile(x, y, Vector2i(0, 0))
		
		previous_height = current_height
	
	# Add some elevated platforms that connect to the terrain
	_add_connected_platform(15, ground_level - 4, 8)
	_add_connected_platform(30, ground_level - 6, 10)
	_add_connected_platform(50, ground_level - 5, 8)
	_add_connected_platform(70, ground_level - 7, 12)
	_add_connected_platform(85, ground_level - 4, 8)

func _add_connected_platform(start_x: int, y: int, length: int) -> void:
	# Add platform tiles
	for i in range(length):
		var x: int = start_x + i
		if x >= 0 and x < LEVEL_WIDTH:
			_set_tile(x, y, Vector2i(0, 0))
			
			# Fill vertical gap below platform to ground to prevent holes
			var ground_y: int = LEVEL_HEIGHT - 1
			for fill_y in range(y + 1, ground_y + 1):
				_set_tile(x, fill_y, Vector2i(0, 0))

func _set_tile(x: int, y: int, atlas_coords: Vector2i) -> void:
	var layer: int = 0
	var coords: Vector2i = Vector2i(x, y)
	var source_id: int = 0
	
	# Set the tile with source and atlas coordinates
	# Using set_cell which will replace any existing tile at this position
	tile_map.set_cell(layer, coords, source_id, atlas_coords)


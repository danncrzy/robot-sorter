extends ColorRect

@onready var tile_vector: Label = $TileVector

const HINT_SIZE := 16.0

func setup(grid_pos: Vector2, tilemap: Node = null) -> void:
	tile_vector.text = "(%d,%d)" % [int(grid_pos.x), int(grid_pos.y)]
	size             = Vector2(HINT_SIZE, HINT_SIZE)

	if tilemap and tilemap.has_method("map_to_local"):
		# map_to_local returns center of tile in tilemap local space
		var local_pos: Vector2 = tilemap.map_to_local(
			Vector2i(int(grid_pos.x), int(grid_pos.y))
		)
		# Convert to global, then offset by half hint size to center it
		global_position = tilemap.to_global(local_pos) - Vector2(HINT_SIZE * 0.5, HINT_SIZE * 0.5)
	else:
		global_position = grid_pos * 32.0 - Vector2(HINT_SIZE * 0.5, HINT_SIZE * 0.5)

	# Label fits inside 16x16
	tile_vector.position = Vector2(0, 2)
	tile_vector.size     = Vector2(HINT_SIZE, HINT_SIZE - 2)
	tile_vector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile_vector.add_theme_font_size_override("font_size", 6)

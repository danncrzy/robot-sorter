extends ColorRect

@onready var tile_vector: Label = $TileVector

const TILE_SIZE := 32.0

func setup(grid_pos: Vector2) -> void:
	tile_vector.text     = "(%d, %d)" % [int(grid_pos.x), int(grid_pos.y)]
	global_position      = grid_pos * TILE_SIZE
	size                 = Vector2(TILE_SIZE, TILE_SIZE)
	tile_vector.position = Vector2(0, TILE_SIZE * 0.3)
	tile_vector.size     = Vector2(TILE_SIZE, TILE_SIZE * 0.4)
	tile_vector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile_vector.add_theme_font_size_override("font_size", 8)

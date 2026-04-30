extends ColorRect
class_name TileHint

signal tile_entered(tile_id: String)

## Grid position (0-based internally, but we'll make it match target_pos)
var grid_col: int = 0
var grid_row: int = 0
const HINT_SIZE := 16.0
## Computed tile ID (format: "col.row" matching objective target_pos)
var tile_id: String:
	get:
		# Convert to 1-based to match your target_pos format!
		return "%d.%d" % [grid_col + 1, grid_row + 1]

@onready var tile_vector_label: Label = $TileVector
@onready var tile_area: Area2D = $TileArea
@onready var tile_collision: CollisionShape2D = $TileArea/TileCol

func _ready() -> void:
	# Setup Area2D for detection
	if tile_area:
		tile_area.monitoring = true
		tile_area.body_entered.connect(_on_body_entered)
		
		# Setup collision shape to match tile size
		if tile_collision:
			var shape := RectangleShape2D.new()
			shape.size = size  # Should be 16x16 from HintContainer
			tile_collision.shape = shape
	
	# Set label text to our coordinates
	if tile_vector_label:
		tile_vector_label.text = "(%d,%d)" % [grid_col + 1, grid_row + 1]

func _on_body_entered(body: Node) -> void:
	# Only care about player (check group or name)
	if not body.is_in_group("player"):
		return
	
	print("📍 Tile %s entered by player!" % tile_id)
	tile_entered.emit(tile_id)

func set_grid_position(col: int, row: int) -> void:
	grid_col = col
	grid_row = row
	if tile_vector_label:
		tile_vector_label.text = "(%d,%d)" % [grid_col + 1, grid_row + 1]

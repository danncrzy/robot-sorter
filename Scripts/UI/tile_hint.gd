extends ColorRect
class_name TileHint

signal tile_entered(tile_id: String)

var grid_col: int = 0
var grid_row: int = 0

var tile_id: String:
	get: return "%d.%d" % [grid_col, grid_row]

@onready var tile_vector_label: Label           = $TileVector
@onready var tile_area:         Area2D          = $TileArea
@onready var tile_collision:    CollisionShape2D = $TileArea/TileCol

func _ready() -> void:
	add_to_group("tile_hint")
	if tile_area:
		tile_area.monitoring = true
		tile_area.body_entered.connect(_on_body_entered)
	# Wait for Container layout so size and global_position are real values.
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_collision()

func _setup_collision() -> void:
	var tile_size := size
	if tile_size.x <= 0.0 or tile_size.y <= 0.0:
		tile_size = custom_minimum_size
	if tile_size.x <= 0.0 or tile_size.y <= 0.0:
		push_warning("TileHint (%d,%d): size zero after layout." % [grid_col, grid_row])
		return

	if tile_vector_label:
		tile_vector_label.text = "(%d,%d)" % [grid_col, grid_row]

	# Move the Area2D to the tile's world position so body_entered fires correctly.
	# global_position on a Control is screen/UI position — assign it to the Node2D
	# so both live in the same coordinate space.
	if tile_area:
		tile_area.global_position = global_position

	if tile_collision:
		var shape       := RectangleShape2D.new()
		shape.size       = tile_size
		tile_collision.shape    = shape
		# Shape is centered on the Area2D origin; offset by half to cover full tile.
		tile_collision.position = tile_size * 0.5

func set_grid_position(col: int, row: int) -> void:
	grid_col = col
	grid_row = row
	if tile_vector_label:
		tile_vector_label.text = "(%d,%d)" % [grid_col, grid_row]

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"): return
	tile_entered.emit(tile_id)

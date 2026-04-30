extends Control

@onready var grid: GridContainer = $Grid

const TILE_HINT_SCENE := preload("res://Scenes/UI/tile_hint.tscn")
const COLS      := 20
const ROWS      := 10
const CELL_SIZE := 16.0

# _hints[row][col] → TileHint node
var _hints: Array = []

func _ready() -> void:
	add_to_group("hint_container")
	grid.columns  = COLS
	grid.position = Vector2.ZERO
	grid.mouse_filter = MOUSE_FILTER_IGNORE
	mouse_filter      = MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)

	# Fill entire grid
	for row in ROWS:
		var row_arr := []
		for col in COLS:
			var hint := TILE_HINT_SCENE.instantiate()
			grid.add_child(hint)
			hint.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			hint.size                = Vector2(CELL_SIZE, CELL_SIZE)
			hint.mouse_filter        = MOUSE_FILTER_IGNORE
			
			# 👇 SET GRID POSITION ON EACH TILE!
			hint.set_grid_position(col, row)
			
			# Duplicate material so each tile has its own instance
			var original_mat = hint.material
			if original_mat:
				hint.material = original_mat.duplicate()
			
			# Setup label
			var lbl: Label = hint.get_node_or_null("TileVector")
			if lbl:
				lbl.text = "(%d,%d)" % [col + 1, row + 1]
				lbl.add_theme_font_size_override("font_size", 4)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				lbl.mouse_filter         = MOUSE_FILTER_IGNORE
			
			_set_intensity(hint, 0.0)  # Start inactive
			row_arr.append(hint)
		_hints.append(row_arr)

	size      = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	grid.size = size
	
	# Connect ALL tile signals to ObjectiveTracker!
	_connect_all_tiles_to_tracker()

## ════════════════════════════════════════════════════════════
##  CONNECT TILES TO TRACKER
## ════════════════════════════════════════════════════════════
func _connect_all_tiles_to_tracker() -> void:
	var tracker = get_tree().get_first_node_in_group("objective_tracker")
	if not tracker:
		push_warning("HintContainer: ObjectiveTracker not found!")
		return
	
	for row_arr in _hints:
		for hint in row_arr:
			# Connect tile's signal to tracker's handler
			if not hint.tile_entered.is_connected(tracker._on_tile_stepped_on):
				hint.tile_entered.connect(tracker._on_tile_stepped_on)
	
	print("✅ Connected %d tiles to ObjectiveTracker!" % [COLS * ROWS])

# ── Public API ─────────────────────────────────────────────────

func show_objective_hints(objectives: Array) -> void:
	deactivate_all()
	for obj in objectives:
		if not obj.show_marker: continue
		if obj.type != LevelObjective.Type.MOVE_TO_POINT: continue
		
		# obj.target_pos is 1-based (e.g., Vector2(10,4))
		# Our hints array is 0-based, so subtract 1
		var col := int(obj.target_pos.x) - 1
		var row := int(obj.target_pos.y) - 1
		activate_hint(col + 1, row + 1)  # Keep 1-based for API consistency

func activate_hint(col: int, row: int) -> void:
	# Convert 1-based to 0-based for array access
	var r := row - 1
	var c := col - 1
	if r < 0 or r >= ROWS or c < 0 or c >= COLS:
		push_warning("activate_hint out of bounds: col=%d row=%d" % [col, row])
		return
	_set_intensity(_hints[r][c], 0.5)
	print("✨ HINT ACTIVATED — row=%d col=%d (tile_id: %s)" % [row, col, _hints[r][c].tile_id])

func deactivate_hint(col: int, row: int) -> void:
	var r := row - 1
	var c := col - 1
	if r < 0 or r >= ROWS or c < 0 or c >= COLS: return
	_set_intensity(_hints[r][c], 0.0)

func deactivate_all() -> void:
	for row_arr in _hints:
		for hint in row_arr:
			_set_intensity(hint, 0.0)

## ════════════════════════════════════════════════════════════
##  GRID BTN INTEGRATION (Toggle Labels)
## ════════════════════════════════════════════════════════════
func set_all_labels_visible(visible: bool) -> void:
	for row_arr in _hints:
		for hint in row_arr:
			var lbl = hint.get_node_or_null("TileVector")
			if lbl:
				lbl.visible = visible

# ── Shader helper ──────────────────────────────────────────────
func _set_intensity(hint: Node, value: float) -> void:
	var mat := (hint as ColorRect).material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", value)

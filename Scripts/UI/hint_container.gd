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
			hint.mouse_filter        = MOUSE_FILTER_IGNORE
			

			hint.set_grid_position(col, row)  # col=0..19, row=0..9
			
			# Duplicate material so each tile has its own instance
			var original_mat = hint.material
			if original_mat:
				hint.material = original_mat.duplicate()
			
			# Setup label (shows 0-based coords)
			var lbl: Label = hint.get_node_or_null("TileVector")
			if lbl:
				lbl.text = "(%d,%d)" % [col, row]  # 0-BASED!
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
	
	# Connect ALL tiles to ObjectiveTracker!
	_connect_all_tiles_to_tracker()

## ════════════════════════════════════════════════════════════
##  CONNECT TILES TO TRACKER
## ════════════════════════════════════════════════════════════
func _connect_all_tiles_to_tracker() -> void:
	var tracker = get_tree().get_first_node_in_group("objective_tracker")
	if not tracker:
		return
	
	for row_arr in _hints:
		for hint in row_arr:
			if not hint.tile_entered.is_connected(tracker._on_tile_stepped_on):
				hint.tile_entered.connect(tracker._on_tile_stepped_on)
	

# ── Public API (ALL 0-BASED NOW!) ─────────────────────────────────

func show_objective_hints(objectives: Array) -> void:
	deactivate_all()
	for obj in objectives:
		if not obj.show_marker: continue
		if obj.type != LevelObjective.Type.MOVE_TO_POINT: continue
		
		# obj.target_pos is NOW 0-BASED! Use directly!
		var col := int(obj.target_pos.x)  # Already 0-based, no -1 needed
		var row := int(obj.target_pos.y)  # Already 0-based, no -1 needed
		activate_hint(col, row)

func activate_hint(col: int, row: int) -> void:
	# Now 0-based! No conversion needed!
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return
	_set_intensity(_hints[row][col], 0.5)

func deactivate_hint(col: int, row: int) -> void:
	# 0-based!
	if row < 0 or row >= ROWS or col < 0 or col >= COLS: return
	_set_intensity(_hints[row][col], 0.0)

func deactivate_all() -> void:
	for row_arr in _hints:
		for hint in row_arr:
			_set_intensity(hint, 0.0)

## ════════════════════════════════════════════════════════════
##  GRID BTN INTEGRATION
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
		

extends Control

var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO
var _enabled:     bool    = false
var _game_node:   Node2D  = null

func _ready() -> void:
	# Dragger is now a sibling of GameNodes, both under the root scene
	_game_node = get_parent().get_node_or_null("GameNodes")
	if not _game_node:
		push_warning("Dragger: GameNodes not found!")

	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var btn := get_tree().get_first_node_in_group("move_toggle_btn")
	if btn:
		btn.move_toggled.connect(_on_move_toggled)
	else:
		push_warning("Dragger: No node found in group 'move_toggle_btn'")

func _on_move_toggled(enabled: bool) -> void:
	_enabled  = enabled
	_dragging = false
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _get_touch_screen_pos(event: InputEvent) -> Vector2:
	# Convert event position to global screen coords consistently
	return get_viewport().get_screen_transform().affine_inverse() * \
		get_viewport().get_canvas_transform().affine_inverse() * event.position if \
		event.position else Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if not _enabled or not _game_node: return

	# ── Mouse (Desktop) ──────────────────────────────
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging    = true
			_drag_offset = _game_node.global_position - get_global_mouse_position()
		else:
			_dragging = false
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragging:
		_game_node.global_position = get_global_mouse_position() + _drag_offset
		get_viewport().set_input_as_handled()

	# ── Touch (Mobile) ───────────────────────────────
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging    = true
			_drag_offset = _game_node.global_position - event.position
		else:
			_dragging = false
		get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag and _dragging:
		_game_node.global_position = event.position + _drag_offset
		get_viewport().set_input_as_handled()

# res://Scripts/dragger.gd
extends Control

var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO
var _enabled:     bool    = false

func _ready() -> void:
	# Fill the entire viewport so any click/touch is caught
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # start ignored until enabled

	# Connect to the button's signal
	var btn := get_tree().get_first_node_in_group("move_toggle_btn")
	if btn:
		btn.move_toggled.connect(_on_move_toggled)
	else:
		push_warning("Dragger: No node found in group 'move_toggle_btn'")

func _on_move_toggled(enabled: bool) -> void:
	_enabled      = enabled
	_dragging     = false
	mouse_filter  = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if not _enabled: return
	var game_node := get_parent() as Node2D  # GameNodes

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging    = true
			_drag_offset = game_node.global_position - get_global_mouse_position()
		else:
			_dragging = false

	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging    = true
			_drag_offset = game_node.global_position - event.position
		else:
			_dragging = false

	elif _dragging:
		if event is InputEventMouseMotion:
			game_node.global_position = get_global_mouse_position() + _drag_offset
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenDrag:
			game_node.global_position = event.position + _drag_offset
			get_viewport().set_input_as_handled()

# res://Scripts/UI/scene_tree_panel.gd
extends Control
class_name SceneTreePanel

@export_group("Window Sizing")
@export var min_width := 110.0
@export var min_height := 200.0
@export var max_width := 400.0
@export var max_height := 800.0

@export var dock_btn_width := 32.0

@onready var bg: NinePatchRect = $SceneTreeBg
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var tab_container: Control = $ScrollContainer/SceneTabContainer
@onready var dock_btn: TextureButton = $DockBtn
@onready var resize_handles: Control = $ResizeHandles

# Drag State
var _is_dragging: bool = false
var _potential_drag: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_panel_start_y: float = 0.0
var _drag_threshold: float = 5.0
var _initial_x: float = 0.0

# Resize State
var _is_resizing: bool = false
var _resize_dir: Vector2i = Vector2i.ZERO
var _resize_mouse_orig: Vector2 = Vector2.ZERO
var _resize_rect_orig: Rect2 = Rect2()

var is_docked: bool = true
var _dock_tween: Tween = null # FIX: Changed 'nil' to 'null'

# Handles
var _rh_e: Control
var _rh_ne: Control
var _rh_se: Control

const SCENE_TAB_SCENE: PackedScene = preload("res://Scenes/UI/scene_tab.tscn")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	if size.x < min_width: size.x = min_width
	if size.y < min_height: size.y = min_height
	custom_minimum_size = Vector2(min_width, min_height)
	
	_initial_x = global_position.x
	
	add_to_group("scene_tree_panel")
	
	_create_resize_handles()
	_connect_signals()
	
	dock_btn.flip_h = false 
	_update_layout()

func _input(event: InputEvent) -> void:
	if not visible: return

	# --- Smart Dragging (Y-axis only) ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.global_position):
				_potential_drag = true
				_drag_start_pos = event.global_position
				_drag_panel_start_y = global_position.y
		else:
			if _is_dragging:
				_is_dragging = false
			_potential_drag = false

	elif event is InputEventMouseMotion:
		if _potential_drag and not _is_dragging:
			if abs(event.global_position.y - _drag_start_pos.y) > _drag_threshold:
				_is_dragging = true
				_potential_drag = false
				scroll_container.release_focus()
		
		if _is_dragging:
			var delta_y = event.global_position.y - _drag_start_pos.y
			global_position.y = _drag_panel_start_y + delta_y
			global_position.x = _initial_x
			get_viewport().set_input_as_handled()

	# --- Resizing ---
	if _is_resizing:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_resizing = false
		elif event is InputEventMouseMotion:
			_apply_resize(get_global_mouse_position())
			
	if event.is_action_pressed("dock"):
		_toggle_dock()

func _connect_signals() -> void:
	dock_btn.pressed.connect(_toggle_dock)

# ────────────────────── Layout ──────────────────────
func _update_layout() -> void:
	if not is_node_ready(): return
	
	var w: float = size.x
	var h: float = size.y
	var m: float = 8
	
	
	bg.position = Vector2.ZERO
	bg.size = Vector2(w, h)
	
	scroll_container.position = Vector2(m, m)
	scroll_container.size = Vector2(w - m * 2.0, h - m * 2.0)
	
	tab_container.size.x = scroll_container.size.x
	tab_container.custom_minimum_size.x = scroll_container.size.x
	
	dock_btn.position = Vector2(w - dock_btn_width + 25.0, 24.0)
	dock_btn.size = Vector2(dock_btn_width, dock_btn_width)
	
	var e: float = 6.0
	_rh_e.position = Vector2(w - e, 16.0);      _rh_e.size = Vector2(e, h - 32.0)
	_rh_ne.position = Vector2(w - 16.0, 0.0);    _rh_ne.size = Vector2(16.0, 16.0)
	_rh_se.position = Vector2(w - 16.0, h - 16.0);_rh_se.size = Vector2(16.0, 16.0)

func _create_resize_handles() -> void:
	_rh_e = _make_handle("ResizeE", Control.CURSOR_HSIZE)
	_rh_ne = _make_handle("ResizeNE", Control.CURSOR_FDIAGSIZE)
	_rh_se = _make_handle("ResizeSE", Control.CURSOR_BDIAGSIZE)

	for h in [_rh_e, _rh_ne, _rh_se]:
		resize_handles.add_child(h)
		h.gui_input.connect(_on_handle_input.bind(h))

	resize_handles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_handles.z_index = 10

func _make_handle(name: String, cursor: Control.CursorShape) -> Control:
	var c := Control.new()
	c.name = name
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = cursor
	return c

# ────────────────────── Resizing ──────────────────────
func _on_handle_input(event: InputEvent, handle: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_is_resizing = true
		_resize_mouse_orig = get_global_mouse_position()
		_resize_rect_orig = Rect2(global_position, size)
		
		var n: String = handle.name
		_resize_dir = Vector2i(
			(1 if "E" in n else 0),
			(1 if "S" in n else (-1 if "N" in n else 0))
		)

func _apply_resize(mouse_pos: Vector2) -> void:
	var delta := mouse_pos - _resize_mouse_orig
	var n_left   := _resize_rect_orig.position.x
	var n_top    := _resize_rect_orig.position.y
	var n_right  := _resize_rect_orig.end.x + delta.x
	var n_bottom := _resize_rect_orig.end.y

	if _resize_dir.y == 1:  n_bottom += delta.y
	elif _resize_dir.y == -1: n_top += delta.y

	var current_w := n_right - n_left
	var current_h := n_bottom - n_top

	if current_w < min_width: n_right = n_left + min_width
	if current_h < min_height:
		if _resize_dir.y == -1: n_top = n_bottom - min_height
		else: n_bottom = n_top + min_height

	if current_w > max_width: n_right = n_left + max_width
	if current_h > max_height:
		if _resize_dir.y == 1: n_bottom = n_top + max_height
		elif _resize_dir.y == -1: n_top = n_bottom - max_height

	offset_left = n_left
	offset_right = n_right
	offset_top = n_top
	offset_bottom = n_bottom
	_update_layout()

# ────────────────────── Docking ──────────────────────
func _toggle_dock() -> void:
	is_docked = !is_docked
	
	dock_btn.flip_h = !is_docked 
	
	if is_instance_valid(_dock_tween):
		_dock_tween.kill()
		
	_dock_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if is_docked:
		var target_x = _initial_x - size.x + dock_btn_width + 16.0 
		_dock_tween.tween_property(self, "global_position:x", target_x, 0.3)
	else:
		_dock_tween.tween_property(self, "global_position:x", _initial_x, 0.3)

# ────────────────────── Tabs ──────────────────────
func clear_tabs() -> void:
	if not is_node_ready() or not tab_container: return
	for child in tab_container.get_children():
		child.queue_free()

func add_scene_tab(node_name: String, data: Dictionary) -> void:
	if not is_node_ready() or not tab_container: return
	
	var tab_instance := SCENE_TAB_SCENE.instantiate()
	tab_container.add_child(tab_instance)
	
	tab_instance.set_node_name(node_name)
	tab_instance.set_data(data)
	
	# VBoxContainer handles the Y position automatically.
	# We just ensure it stretches horizontally.
	tab_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	tab_instance.script_requested.connect(_on_tab_script_requested)


func _update_tab_container_bounds() -> void:
	# Calculate the total height of all tabs so ScrollContainer knows when to scroll
	var max_y: float = 0.0
	for child in tab_container.get_children():
		# FIX: Cast to Control so Godot knows it has size/position
		var ctrl: Control = child as Control
		if ctrl:
			var b_y: float = ctrl.position.y + maxf(ctrl.size.y, ctrl.custom_minimum_size.y)
			if b_y > max_y:
				max_y = b_y
	
	# Set the custom minimum size so the scrollbar works correctly
	tab_container.custom_minimum_size.y = max_y
	tab_container.size.y = maxf(max_y, scroll_container.size.y)

func _on_tab_script_requested(data: Dictionary) -> void:
	LevelManager.open_script_for_node(data)

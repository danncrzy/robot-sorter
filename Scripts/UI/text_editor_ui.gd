# res://Scripts/UI/text_editor_ui.gd
extends Control
class_name TextEditorUI

## ────────────────────── Exports ──────────────────────
@export_group("Window Sizing")
@export var min_window_size := Vector2(336.0, 140.0) 
@export var script_panel_hide_width := 480.0         
@export var script_panel_width      := 180.0
@export var title_bar_height        := 16.0          
@export var script_panel_overlap    := 4.0           

@export_group("Resize Handles")
@export var edge_thickness  := 6.0
@export var corner_size     := 14.0
@export var top_resize_extension := 6.0 

@export_group("Padding")
@export var nine_slice_margin := 16.0
@export var inner_pad         := 6.0                 
@export var code_edit_margin  := 4.0                 

@export_group("Filter Customization")
@export var filter_bg_size_offset := Vector2(0.0, 0.0) 
@export var filter_bg_pos_offset := Vector2(0.0, 0.0)  

@export_group("Title Bar Customization")
@export var title_label_offset := Vector2(-10.0, 5.0)

## ────────────────────── Scene References ──────────────────────
@onready var title_bar:               Control        = $TitleBar
@onready var title_bar_bg:            NinePatchRect  = $TitleBar/TitleBarBg
@onready var title_label:             Label          = $TitleBar/TitleLabel
@onready var close_btn:               TextureButton  = $TitleBar/CloseBtn
@onready var nav_btn:                 TextureButton  = $TitleBar/NavBarBtn 

@onready var script_selection_panel:  Control        = $ScriptSelectionUI
@onready var sel_bg:                  NinePatchRect  = $ScriptSelectionUI/SelBG
@onready var filter_bg:               NinePatchRect  = $ScriptSelectionUI/FilterBG
@onready var filter_edit:             LineEdit       = $ScriptSelectionUI/FilterBG/FilterEdit
@onready var script_tab_list:         VBoxContainer  = $ScriptSelectionUI/ScriptTabList

@onready var code_panel:              Control        = $TextEditorPanel
@onready var code_bg:                 NinePatchRect  = $TextEditorPanel/CodeBG
@onready var code_edit:               CodeEdit       = $TextEditorPanel/CodeEdit

@onready var tab_btn:                 TextureButton  = $TabBtn

@onready var resize_handles:          Control        = $ResizeHandles

@onready var error_control:           Control        = $TextEditorPanel/ErrorControl

# Resize handle nodes
var _rh_n:  Control
var _rh_s:  Control
var _rh_e:  Control
var _rh_w:  Control
var _rh_ne: Control
var _rh_nw: Control
var _rh_se: Control
var _rh_sw: Control

## ────────────────────── State ──────────────────────
var _is_dragging:       bool     = false
var _drag_offset:       Vector2  = Vector2.ZERO

var _is_resizing:       bool     = false
var _resize_dir:        Vector2i = Vector2i.ZERO
var _resize_mouse_orig: Vector2  = Vector2.ZERO
var _resize_rect_orig:  Rect2    = Rect2()

var _current_script:    String   = ""
var _scripts:           Dictionary = {}
var _editor_open:       bool     = false
var _force_show_panel:  bool     = false

const SCRIPT_BTN_SCENE: String = "res://Scenes/UI/script_btn.tscn"

## ────────────────────── Signals ──────────────────────
signal script_content_changed(script_name: String, new_content: String)
signal editor_opened
signal editor_closed

## ═══════════════════════════════════════════════════════════════
##  LIFECYCLE
## ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_configure_nine_patches()
	_configure_styles()
	_create_resize_handles()
	_connect_internal_signals()
	
	error_control.init(code_edit)
	ErrorHandler.init(self, error_control)

	if resize_handles.get_index() < get_child_count() - 1:
		move_child(resize_handles, get_child_count() - 1)

	# Reset ALL child anchors
	for node in [
		title_bar, title_bar_bg, title_label, close_btn,
		script_selection_panel, sel_bg, filter_bg, filter_edit, script_tab_list,
		code_panel, code_bg, code_edit, resize_handles
	]:
		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	custom_minimum_size = min_window_size

	if size.x < min_window_size.x or size.y < min_window_size.y:
		size = Vector2(maxf(size.x, min_window_size.x), maxf(size.y, min_window_size.y))

	_update_layout()
	visible = false
	
	tab_btn.pressed.connect(func() -> void:
		code_edit.insert_text_at_caret("\t")
		code_edit.grab_focus()
	)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if _is_dragging:
		if event is InputEventMouseButton \
		   and event.button_index == MOUSE_BUTTON_LEFT \
		   and not event.pressed:
			_is_dragging = false
		elif event is InputEventMouseMotion:
			global_position = get_global_mouse_position() - _drag_offset

	if _is_resizing:
		if event is InputEventMouseButton \
		   and event.button_index == MOUSE_BUTTON_LEFT \
		   and not event.pressed:
			_is_resizing = false
		elif event is InputEventMouseMotion:
			_apply_resize(get_global_mouse_position())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

## ═══════════════════════════════════════════════════════════════
##  SETUP HELPERS
## ═══════════════════════════════════════════════════════════════
func _configure_nine_patches() -> void:
	if title_bar_bg.texture == null:
		title_bar_bg.texture = _try_load("res://Assets/UI/TitleBarUI.png")
	title_bar_bg.patch_margin_left  = 16
	title_bar_bg.patch_margin_right = 16
	title_bar_bg.patch_margin_top   = 0
	title_bar_bg.patch_margin_bottom = 0
	title_bar_bg.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	title_bar_bg.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	title_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if sel_bg.texture == null:
		sel_bg.texture = _try_load("res://Assets/UI/ScriptSelectionUI.png")
	sel_bg.patch_margin_left  = 16
	sel_bg.patch_margin_right = 16
	sel_bg.patch_margin_top   = 16
	sel_bg.patch_margin_bottom = 16
	sel_bg.mouse_filter       = Control.MOUSE_FILTER_IGNORE

	if filter_bg.texture == null:
		filter_bg.texture = _try_load("res://Assets/UI/FilterScriptUI.png")
	filter_bg.patch_margin_left  = 16
	filter_bg.patch_margin_right = 16
	filter_bg.patch_margin_top   = 0
	filter_bg.patch_margin_bottom = 0
	filter_bg.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	filter_bg.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	filter_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if code_bg.texture == null:
		code_bg.texture = _try_load("res://Assets/UI/TextEditorUI.png")
	code_bg.patch_margin_left  = 16
	code_bg.patch_margin_right = 16
	code_bg.patch_margin_top   = 16
	code_bg.patch_margin_bottom = 16
	code_bg.mouse_filter       = Control.MOUSE_FILTER_IGNORE


func _configure_styles() -> void:
	var empty_style = StyleBoxEmpty.new()
	code_edit.add_theme_stylebox_override("normal", empty_style)
	code_edit.add_theme_stylebox_override("focus", empty_style)
	code_edit.add_theme_stylebox_override("read_only", empty_style)
	
	filter_edit.add_theme_stylebox_override("normal", empty_style)
	filter_edit.add_theme_stylebox_override("focus", empty_style)

	code_edit.syntax_highlighter = _create_highlighter()


func _create_resize_handles() -> void:
	_rh_n  = _make_handle("ResizeN",  Control.CURSOR_VSIZE)
	_rh_s  = _make_handle("ResizeS",  Control.CURSOR_VSIZE)
	_rh_e  = _make_handle("ResizeE",  Control.CURSOR_HSIZE)
	_rh_w  = _make_handle("ResizeW",  Control.CURSOR_HSIZE)
	_rh_ne = _make_handle("ResizeNE", Control.CURSOR_FDIAGSIZE)
	_rh_nw = _make_handle("ResizeNW", Control.CURSOR_BDIAGSIZE)
	_rh_se = _make_handle("ResizeSE", Control.CURSOR_FDIAGSIZE)
	_rh_sw = _make_handle("ResizeSW", Control.CURSOR_BDIAGSIZE)

	for h: Control in [_rh_n, _rh_s, _rh_e, _rh_w,
					   _rh_ne, _rh_nw, _rh_se, _rh_sw]:
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


func _connect_internal_signals() -> void:
	filter_edit.text_changed.connect(_on_filter_text_changed)
	code_edit.text_changed.connect(_on_code_edit_text_changed)
	title_bar.gui_input.connect(_on_title_bar_gui_input)
	close_btn.pressed.connect(close_editor)
	if nav_btn:
		nav_btn.pressed.connect(_on_nav_bar_btn_pressed)


func _on_nav_bar_btn_pressed() -> void:
	_force_show_panel = !_force_show_panel
	_update_layout()
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_6.ogg"))

## ═══════════════════════════════════════════════════════════════
##  LAYOUT
## ═══════════════════════════════════════════════════════════════
func _update_layout() -> void:
	if not is_node_ready():
		return

	var w: float = size.x
	var h: float = size.y
	var p: float = inner_pad

	# ── Title Bar ──
	title_bar.position = Vector2.ZERO
	title_bar.size     = Vector2(w, title_bar_height)
	
	title_bar_bg.position = Vector2.ZERO
	title_bar_bg.size     = title_bar.size
	
	title_label.position = title_label_offset
	title_label.size     = Vector2(w - 36.0, title_bar_height - 10)
	
	close_btn.position = Vector2(w - 16.0, 5.0)
	close_btn.size     = Vector2(16.0, title_bar_height)

	var below_y: float = title_bar_height
	var below_h: float = h - title_bar_height

	var show_panel: bool = (w >= script_panel_hide_width) or _force_show_panel

	# NavBarBtn visible ONLY if window width is too narrow for natural spawn
	if nav_btn:
		nav_btn.visible = (w < script_panel_hide_width)

	script_selection_panel.visible = show_panel

	if show_panel:
		# ── Script Selection Panel ──
		script_selection_panel.position = Vector2(0.0, below_y)
		script_selection_panel.size     = Vector2(script_panel_width, below_h)
		
		sel_bg.position = Vector2.ZERO
		sel_bg.size     = script_selection_panel.size

		var panel_inner_w := script_panel_width - p * 2.0
		
		# FilterBG
		filter_bg.position = Vector2(p, p + 3) + filter_bg_pos_offset
		filter_bg.size     = Vector2(panel_inner_w, 16) + filter_bg_size_offset
		
		# FilterEdit
		filter_edit.position = Vector2(p, p - 5)
		filter_edit.size     = Vector2(filter_bg.size.x - p * 2.0, filter_bg.size.y - p * 2.0)

		# Tab List
		var list_y: float = filter_bg.position.y + filter_bg.size.y + p
		script_tab_list.position = Vector2(p, list_y)
		script_tab_list.size     = Vector2(panel_inner_w, below_h - list_y - p)

		# ── Text Editor Panel (Shrinks to fit) ──
		code_panel.position = Vector2(script_panel_width - script_panel_overlap, below_y)
		code_panel.size     = Vector2(w - script_panel_width + script_panel_overlap, below_h)
	else:
		# ── Text Editor Panel (Full Width) ──
		code_panel.position = Vector2(0.0, below_y)
		code_panel.size     = Vector2(w, below_h)

	# ── Text Editor Background & Code Edit ──
	code_bg.position = Vector2.ZERO
	code_bg.size     = code_panel.size
	
	code_edit.position = Vector2(code_edit_margin, code_edit_margin)
	code_edit.size     = Vector2(code_panel.size.x - code_edit_margin * 2.0, code_panel.size.y - code_edit_margin * 2.0)

	# ── Resize handles ──
	_position_handles(w, h)


func _position_handles(w: float, h: float) -> void:
	if not is_instance_valid(_rh_n):
		return

	var e: float = edge_thickness
	var c: float = corner_size
	var top_ext: float = top_resize_extension # Uses the export variable

	_rh_n.position  = Vector2(c, -top_ext);       _rh_n.size  = Vector2(w - c * 2.0, e + top_ext)
	_rh_s.position  = Vector2(c, h - e);          _rh_s.size  = Vector2(w - c * 2.0, e)
	_rh_e.position  = Vector2(w - e, c);          _rh_e.size  = Vector2(e, h - c * 2.0)
	_rh_w.position  = Vector2(0.0, c);            _rh_w.size  = Vector2(e, h - c * 2.0)
	_rh_ne.position = Vector2(w - c, -top_ext);   _rh_ne.size = Vector2(c, c + top_ext)
	_rh_nw.position = Vector2(0.0, -top_ext);     _rh_nw.size = Vector2(c, c + top_ext)
	_rh_se.position = Vector2(w - c, h - c);      _rh_se.size = Vector2(c, c)
	_rh_sw.position = Vector2(0.0, h - c);        _rh_sw.size = Vector2(c, c)

## ═══════════════════════════════════════════════════════════════
##  TITLE BAR DRAG & CLOSE
## ═══════════════════════════════════════════════════════════════
func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	   and event.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = event.pressed
		if event.pressed:
			_drag_offset = get_global_mouse_position() - global_position

## ═══════════════════════════════════════════════════════════════
##  RESIZE (Jitter-Free Offset Math)
## ═══════════════════════════════════════════════════════════════
func _on_handle_input(event: InputEvent, handle: Control) -> void:
	if event is InputEventMouseButton \
	   and event.button_index == MOUSE_BUTTON_LEFT \
	   and event.pressed:
		_is_resizing       = true
		_resize_mouse_orig = get_global_mouse_position()
		_resize_rect_orig  = Rect2(global_position, size)
		
		var n: String = handle.name
		_resize_dir = Vector2i(
			(1 if "E" in n else (-1 if "W" in n else 0)),
			(1 if "S" in n else (-1 if "N" in n else 0))
		)
		get_viewport().set_input_as_handled()


func _apply_resize(mouse_pos: Vector2) -> void:
	var delta := mouse_pos - _resize_mouse_orig
	
	var n_left   := _resize_rect_orig.position.x
	var n_top    := _resize_rect_orig.position.y
	var n_right  := _resize_rect_orig.end.x
	var n_bottom := _resize_rect_orig.end.y

	if _resize_dir.x == 1:    n_right  += delta.x
	elif _resize_dir.x == -1: n_left   += delta.x

	if _resize_dir.y == 1:    n_bottom += delta.y
	elif _resize_dir.y == -1: n_top    += delta.y

	if (n_right - n_left) < min_window_size.x:
		if _resize_dir.x == -1: n_left  = n_right  - min_window_size.x
		else:                    n_right = n_left   + min_window_size.x

	if (n_bottom - n_top) < min_window_size.y:
		if _resize_dir.y == -1: n_top   = n_bottom - min_window_size.y
		else:                    n_bottom = n_top    + min_window_size.y

	offset_left   = n_left
	offset_right  = n_right
	offset_top    = n_top
	offset_bottom = n_bottom

	_update_layout()

## ═══════════════════════════════════════════════════════════════
##  SCRIPT MANAGEMENT
## ═══════════════════════════════════════════════════════════════
func add_script(script_name: String, content: String = "") -> void:
	print("ADD SCRIPT: ", script_name, " content_len=", content.length())
	_scripts[script_name] = content
	for child in script_tab_list.get_children():
		if _get_tab_name(child) == script_name:
			return
	_spawn_script_tab(script_name)

func remove_script(script_name: String) -> void:
	_scripts.erase(script_name)
	for child in script_tab_list.get_children():
		if _get_tab_name(child) == script_name:
			child.queue_free()
			break
	if _current_script == script_name:
		_current_script = ""
		title_label.text = "No Script Open"
		code_edit.text   = ""




func _spawn_script_tab(script_name: String) -> void:
	for child in script_tab_list.get_children():
		if _get_tab_name(child) == script_name:
			child.queue_free()
			break

	var tab: Control
	if ResourceLoader.exists(SCRIPT_BTN_SCENE):
		tab = load(SCRIPT_BTN_SCENE).instantiate()
		tab.setup(script_name)
		tab.tab_pressed.connect(_on_tab_pressed)
	else:
		# Fallback plain button if scene missing
		var btn := Button.new()
		btn.text      = script_name
		btn.flat      = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.set_meta("script_name", script_name)
		btn.pressed.connect(_on_tab_pressed.bind(script_name))
		tab = btn

	tab.custom_minimum_size = Vector2(0, 28)
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	script_tab_list.add_child(tab)


func _get_tab_name(tab: Control) -> String:
	if tab.has_meta("script_name"):
		return tab.get_meta("script_name")
	return ""


func _highlight_active_tab() -> void:
	for child in script_tab_list.get_children():
		if child.has_method("set_active"):
			child.set_active(_get_tab_name(child) == _current_script)
		elif child is Button:
			child.button_pressed = (_get_tab_name(child) == _current_script)



func _on_tab_pressed(script_name: String) -> void:
	open_script(script_name)
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_6.ogg"))


func open_script(script_name: String) -> void:
	if not _scripts.has(script_name):
		return
	_current_script   = script_name
	title_label.text  = script_name
	code_edit.text    = _scripts[script_name]
	_highlight_active_tab()
	_update_layout()


## ═══════════════════════════════════════════════════════════════
##  FILTER
## ═══════════════════════════════════════════════════════════════
func _on_filter_text_changed(new_text: String) -> void:
	var filter := new_text.to_lower().strip_edges()
	for child in script_tab_list.get_children():
		var sname := _get_tab_name(child).to_lower()
		child.visible = (filter == "") or sname.contains(filter)

## ═══════════════════════════════════════════════════════════════
##  CODE EDITING
## ═══════════════════════════════════════════════════════════════
func _on_code_edit_text_changed() -> void:
	if _current_script != "":
		_scripts[_current_script] = code_edit.text
		ScriptManager.update_content(_current_script, code_edit.text)
		script_content_changed.emit(_current_script, code_edit.text)

## ═══════════════════════════════════════════════════════════════
##  VISIBILITY
## ═══════════════════════════════════════════════════════════════
func toggle_editor() -> void:

	if _editor_open:
		close_editor()
	else:
		open_editor()

func open_editor() -> void:
	_editor_open = true
	visible      = true
	editor_opened.emit()

func close_editor() -> void:
	_editor_open = false
	visible      = false
	editor_closed.emit()
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_6.ogg"))

func is_editor_open() -> bool:
	return _editor_open

## ═══════════════════════════════════════════════════════════════
##  PUBLIC API
## ═══════════════════════════════════════════════════════════════
func get_script_content(script_name: String) -> String:
	return _scripts.get(script_name, "")

func get_current_script_name() -> String:
	return _current_script

func get_current_script_content() -> String:
	return code_edit.text

func get_all_script_names() -> PackedStringArray:
	return PackedStringArray(_scripts.keys())
	
func update_script_content(script_name: String, new_content: String) -> void:
	if _scripts.has(script_name):
		_scripts[script_name] = new_content
		if _current_script == script_name:
			code_edit.text = new_content

## ═══════════════════════════════════════════════════════════════
##  UTILITY
## ═══════════════════════════════════════════════════════════════
func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null
	
## ═══════════════════════════════════════════════════════════════
##  CODE HIGHLIGHT
## ═══════════════════════════════════════════════════════════════
	
	
func _create_highlighter() -> CodeHighlighter:
	var hl := CodeHighlighter.new()

	# ── Control flow — pink/magenta ────────────────────────────
	var control_flow_color := Color("ff7085ff")
	for kw in ["if", "elif", "else", "for", "while", "match",
			   "break", "continue", "return", "pass", "await"]:
		hl.add_keyword_color(kw, control_flow_color)

	# ── Declarations — light pink ──────────────────────────────
	var declaration_color := Color("FD6E85")
	for kw in ["func", "var", "const", "class", "class_name",
			   "extends", "signal", "enum", "static", "in", "not",
			   "and", "or", "as", "is", "new"]:
		hl.add_keyword_color(kw, declaration_color)

	# ── Built-in types — mint green ────────────────────────────
	var base_type_color := Color(0.26, 1.0, 0.76)
	for kw in ["int", "float", "bool", "String", "void",
			   "Vector2", "Vector2i", "Vector3", "Vector3i",
			   "Vector4", "Rect2", "Rect2i", "Color", "Plane",
			   "Quaternion", "AABB", "Basis", "Transform2D",
			   "Transform3D", "Array", "Dictionary", "Object",
			   "Node", "PackedScene", "Resource", "Callable",
			   "StringName", "NodePath", "RID"]:
		hl.add_keyword_color(kw, base_type_color)

	# ── Literals — same mint, slightly dimmer ──────────────────
	var literal_color := Color("#FD6E85")
	for kw in ["true", "false", "null", "self", "super",
			   "PI", "TAU", "INF", "NAN"]:
		hl.add_keyword_color(kw, literal_color)

	# ── Annotations — light yellow-green ──────────────────────
	var annotation_color := Color("#E19E67")
	for kw in ["export", "onready", "tool", "static_unload",
			   "export_group", "export_subgroup", "export_range",
			   "export_enum", "warning_ignore"]:
		hl.add_keyword_color(kw, annotation_color)

	# ── Token colors ───────────────────────────────────────────
	hl.number_color          = Color(0.63, 1.00, 0.88)   # mint 
	hl.symbol_color = Color(0.67, 0.85, 1.00)   # blue — default operators
	hl.function_color        = Color(0.34, 0.70, 1.00)   # blue
	hl.member_variable_color = Color(0.90, 0.93, 1.00)   # near white/light lavender
	
	# ── Per-symbol colors via single-char regions ──────────────
	# symbol_color handles everything else (operators: = + - * / etc.)

	# @ — orange
	hl.add_color_region("@", " ", Color(1.00, 0.60, 0.20), false)

	# $ — green
	hl.add_color_region("$", " ", Color(0.40, 1.00, 0.50), false)

	# ── Color regions ──────────────────────────────────────────
	var string_color := Color(1.00, 0.93, 0.63)           # warm yellow
	hl.add_color_region('"',   '"',   string_color)
	hl.add_color_region("'",   "'",   string_color)
	hl.add_color_region('"""', '"""', string_color)
	hl.add_color_region("'''", "'''", string_color)

	# Comments — blue-gray
	hl.add_color_region("#", "", Color(0.50, 0.60, 0.70), true)

	return hl

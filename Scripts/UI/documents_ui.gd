# res://Scripts/UI/documents_ui.gd
extends Control
class_name DocumentsUI

## ────────────────────── Exports ──────────────────────
@export_group("Window Sizing")
@export var min_window_size := Vector2(400.0, 300.0)

@export_group("Book Margins")
@export var outer_margin := 16.0      # The edges of the book covers
@export var spine_margin := 8.0       # The inside binding (smaller so it doesn't stretch weirdly)

@export_group("Corner Resize")
@export var corner_size := 16.0
@export var corner_texture: Texture2D # Drag your corner texture here in the inspector

## ────────────────────── Scene References ──────────────────────
@onready var left_page:      NinePatchRect  = $LeftPage
@onready var left_content:   RichTextLabel  = $LeftPage/LeftContent
@onready var right_page:     NinePatchRect  = $RightPage
@onready var right_content:  RichTextLabel  = $RightPage/RightContent

@onready var back_btn:       TextureButton  = $BackPageBtn
@onready var next_btn:       TextureButton  = $NextPageBtn
@onready var toc_btn:        TextureButton  = $TableOfContentsBtn
@onready var marker_btn:     TextureButton  = $MarkerBtn

@onready var resize_handles: Control        = $ResizeHandles

# Resize handle nodes
var _rh_nw: TextureButton
var _rh_ne: TextureButton
var _rh_sw: TextureButton
var _rh_se: TextureButton

## ────────────────────── State ──────────────────────
var _is_resizing:       bool     = false
var _resize_dir:        Vector2i = Vector2i.ZERO
var _resize_mouse_orig: Vector2  = Vector2.ZERO
var _resize_rect_orig:  Rect2    = Rect2()
var _is_dragging:       bool     = false
var _drag_offset:       Vector2  = Vector2.ZERO

var current_spread: int = 0
var marked_page: int = -1

# Safe reference to the Autoload
var game_docs: Node = null

## ────────────────────── Lifecycle ──────────────────────
func _ready() -> void:
	game_docs = get_node_or_null("/root/GameDocs")
	
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	custom_minimum_size = min_window_size
	
	# Force pages to top-left anchors so they don't stretch wildly
	left_page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	right_page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	right_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Allow dragging the book by clicking the pages
	left_page.mouse_filter = Control.MOUSE_FILTER_STOP
	right_page.mouse_filter = Control.MOUSE_FILTER_STOP
	left_content.mouse_filter = Control.MOUSE_FILTER_PASS
	right_content.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# FIX: Apply symmetric 9-slice margins so the right page scales identically to the left
	left_page.patch_margin_left = int(outer_margin)
	left_page.patch_margin_right = int(spine_margin)
	left_page.patch_margin_top = int(outer_margin)
	left_page.patch_margin_bottom = int(outer_margin)
	
	right_page.patch_margin_left = int(spine_margin)
	right_page.patch_margin_right = int(outer_margin)
	right_page.patch_margin_top = int(outer_margin)
	right_page.patch_margin_bottom = int(outer_margin)
	
	_create_resize_handles()
	_connect_signals()
	
	if size.x < min_window_size.x or size.y < min_window_size.y:
		size = Vector2(maxf(size.x, min_window_size.x), maxf(size.y, min_window_size.y))
	
	_update_layout()
	_update_pages()
	visible = false

func _input(event: InputEvent) -> void:
	if not visible: return

	if _is_dragging:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_dragging = false
		elif event is InputEventMouseMotion:
			global_position = get_global_mouse_position() - _drag_offset

	if _is_resizing:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_resizing = false
		elif event is InputEventMouseMotion:
			_apply_resize(get_global_mouse_position())

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

## ────────────────────── Setup ──────────────────────
func _create_resize_handles() -> void:
	_rh_nw = _make_corner("ResizeNW", Control.CURSOR_BDIAGSIZE)
	_rh_ne = _make_corner("ResizeNE", Control.CURSOR_FDIAGSIZE)
	_rh_sw = _make_corner("ResizeSW", Control.CURSOR_BDIAGSIZE)
	_rh_se = _make_corner("ResizeSE", Control.CURSOR_FDIAGSIZE)

	for h in [_rh_nw, _rh_ne, _rh_sw, _rh_se]:
		resize_handles.add_child(h)
		h.gui_input.connect(_on_handle_input.bind(h))

	resize_handles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_handles.z_index = 10

func _make_corner(name: String, cursor: Control.CursorShape) -> TextureButton:
	var c := TextureButton.new()
	c.name = name
	c.texture_normal = corner_texture
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = cursor
	c.ignore_texture_size = true
	c.stretch_mode = TextureButton.STRETCH_SCALE
	c.custom_minimum_size = Vector2(corner_size, corner_size)
	return c

func _connect_signals() -> void:
	next_btn.pressed.connect(_on_next_page)
	back_btn.pressed.connect(_on_back_page)
	toc_btn.pressed.connect(_go_to_toc)
	marker_btn.pressed.connect(_on_marker_pressed)
	
	left_content.meta_clicked.connect(_on_meta_clicked)
	right_content.meta_clicked.connect(_on_meta_clicked)
	
	left_page.gui_input.connect(_on_page_gui_input)
	right_page.gui_input.connect(_on_page_gui_input)

## ┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐
##  LAYOUT & MATH
## ┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘
func _update_layout() -> void:
	if not is_node_ready(): return
	
	var w: float = size.x
	var h: float = size.y
	var half_w: float = w / 2.0
	var m_out: float = outer_margin
	var m_spine: float = spine_margin
	var btn_m: float = 8.0

	# Pages (Symmetric dimensions)
	left_page.position = Vector2.ZERO
	left_page.size = Vector2(half_w, h)
	
	right_page.position = Vector2(half_w, 0.0)
	right_page.size = Vector2(half_w, h)

	# Content (Accounting for spine vs outer margins)
	left_content.position = Vector2(m_out, m_out)
	left_content.size = Vector2(half_w - m_out - m_spine, h - m_out * 2.0)

	right_content.position = Vector2(m_spine, m_out)
	right_content.size = Vector2(half_w - m_spine - m_out, h - m_out * 2.0)

	# Buttons
	back_btn.position = Vector2(btn_m, h - 32.0 - btn_m)
	next_btn.position = Vector2(w - 64.0 - btn_m, h - 32.0 - btn_m)
	toc_btn.position = Vector2(btn_m, btn_m)
	marker_btn.position = Vector2(w - 64.0 - btn_m, btn_m)

	# Resize Handles (Corners)
	_rh_nw.position = Vector2(0.0, 0.0);       _rh_nw.size = Vector2(corner_size, corner_size)
	_rh_ne.position = Vector2(w - corner_size, 0.0);  _rh_ne.size = Vector2(corner_size, corner_size)
	_rh_sw.position = Vector2(0.0, h - corner_size);  _rh_sw.size = Vector2(corner_size, corner_size)
	_rh_se.position = Vector2(w - corner_size, h - corner_size); _rh_se.size = Vector2(corner_size, corner_size)

## ────────────────────── Dragging ──────────────────────
func _on_page_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = event.pressed
		if event.pressed:
			_drag_offset = get_global_mouse_position() - global_position

## ────────────────────── Resizing ──────────────────────
func _on_handle_input(event: InputEvent, handle: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_is_resizing = true
		_resize_mouse_orig = get_global_mouse_position()
		_resize_rect_orig = Rect2(global_position, size)
		
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

	if _resize_dir.x == 1:  n_right  += delta.x
	elif _resize_dir.x == -1: n_left += delta.x
	if _resize_dir.y == 1:  n_bottom += delta.y
	elif _resize_dir.y == -1: n_top  += delta.y

	if (n_right - n_left) < min_window_size.x:
		if _resize_dir.x == -1: n_left = n_right - min_window_size.x
		else: n_right = n_left + min_window_size.x
	if (n_bottom - n_top) < min_window_size.y:
		if _resize_dir.y == -1: n_top = n_bottom - min_window_size.y
		else: n_bottom = n_top + min_window_size.y

	offset_left   = n_left
	offset_right  = n_right
	offset_top    = n_top
	offset_bottom = n_bottom
	_update_layout()

## ┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐┐
##  PAGINATION & LOGIC
## ┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘┘
func _update_pages() -> void:
	if not is_instance_valid(game_docs) or not game_docs.has_method("get_page"): 
		left_content.text = "Error: GameDocs Autoload missing!"
		right_content.text = ""
		return
	
	var left_idx = current_spread * 2
	var right_idx = current_spread * 2 + 1
	
	if left_idx < game_docs.pages.size():
		var p_data = game_docs.pages[left_idx]
		if p_data.get("is_toc", false):
			left_content.text = _build_toc_bbcode(left_idx)
		else:
			left_content.text = "[b]" + p_data["title"] + "[/b]\n\n" + p_data["content"]
	else:
		left_content.text = ""

	if right_idx < game_docs.pages.size():
		var p_data = game_docs.pages[right_idx]
		if p_data.get("is_toc", false):
			right_content.text = _build_toc_bbcode(right_idx)
		else:
			right_content.text = "[b]" + p_data["title"] + "[/b]\n\n" + p_data["content"]
	else:
		right_content.text = ""

func _build_toc_bbcode(exclude_index: int) -> String:
	var toc_string := "[b]Table of Contents[/b]\n\n"
	for i in range(game_docs.pages.size()):
		if i == exclude_index: continue
		var p = game_docs.pages[i]
		if p.get("toc_visible", false):
			var indent_str = "    " if p.get("toc_indent", 0) == 1 else ""
			toc_string += indent_str + "• [url=" + str(i) + "]" + p["title"] + "[/url]\n"
	return toc_string

func _on_meta_clicked(meta: Variant) -> void:
	var page_idx = int(str(meta))
	_go_to_page(page_idx)

func _go_to_page(index: int) -> void:
	if index % 2 != 0: index -= 1
	current_spread = index / 2
	_update_pages()

func _go_to_toc() -> void:
	_go_to_page(0)

func _on_next_page() -> void:
	var next_spread = current_spread + 1
	var left_idx = next_spread * 2
	if left_idx < game_docs.pages.size():
		current_spread = next_spread
		_update_pages()

func _on_back_page() -> void:
	if current_spread > 0:
		current_spread -= 1
		_update_pages()

func _on_marker_pressed() -> void:
	var current_left_index = current_spread * 2
	
	if marked_page == current_left_index:
		marked_page = -1
		marker_btn.self_modulate = Color(1, 1, 1, 0.5) 
	else:
		marked_page = current_left_index
		marker_btn.self_modulate = Color(1, 1, 1, 1) 

## ────────────────────── Visibility ──────────────────────
func toggle_ui() -> void:
	visible = !visible

func open_ui() -> void:
	visible = true

func close_ui() -> void:
	visible = false

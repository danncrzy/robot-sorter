# res://Scripts/UI/scene_tab.gd
extends Control

# --- Preloaded Icons ---
const ICON_NODE2D = preload("res://Assets/Icons/IconNode2D.png")
const ICON_CONTROL = preload("res://Assets/Icons/IconControl.png")
const ICON_DEFAULT = preload("res://Assets/Icons/IconNode.png")

const BASE_INDENT: float = 10.0 # Pixels to indent per depth level

@onready var bg: NinePatchRect = $SceneTabBg
@onready var layout: Control = $Layout
@onready var node_icon: TextureRect = $Layout/NodeIcon
@onready var node_name_label: Label = $Layout/NodeName
@onready var script_btn: TextureButton = $Layout/ScriptBtn
@onready var vision_control: Control = $Layout/VisionControl
@onready var invisible_btn: TextureButton = $Layout/VisionControl/InvisibleBtn
@onready var visible_btn: TextureButton = $Layout/VisionControl/VisibleBtn

var _script_data: Dictionary = {}
var _current_indent: float = 0.0

signal script_requested(data: Dictionary)
signal visibility_toggled(is_visible)

func _ready() -> void:
	# Force internal nodes to fill the root Control
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# --- Lower the margins on each side of the tab ---
	bg.patch_margin_left = 4
	bg.patch_margin_right = 4
	bg.patch_margin_top = 4
	bg.patch_margin_bottom = 4
	# -------------------------------------------------------
	
	invisible_btn.pressed.connect(_toggle_visibility)
	visible_btn.pressed.connect(_toggle_visibility)
	script_btn.pressed.connect(_on_script_pressed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_manual_layout()

# ────────────────────── MANUAL LAYOUT ──────────────────────
func _update_manual_layout() -> void:
	if not is_node_ready() or size == Vector2.ZERO: return
	
	var full_w: float = size.x
	var h: float = size.y
	
	# --- INDENT LOGIC ---
	# Offset the Background and Layout to create the tree indentation
	bg.position.x = _current_indent
	bg.size.x = full_w - _current_indent
	
	layout.position.x = _current_indent
	layout.size.x = full_w - _current_indent
	# --------------------
	
	# Use layout's width for internal math so nothing spills off the right edge
	var w: float = layout.size.x
	var pad: float = 4.0
	var icon_sz: float = 24.0
	var btn_sz: float = 24.0
	var vision_w: float = 48.0
	
	# --- Absolute Positions (Inside the indented layout) ---
	
	# NodeIcon (Left)
	node_icon.position = Vector2(pad, (h - icon_sz) * (-0.5)) 
	node_icon.size = Vector2(7, 7)
	
	# VisionControl (Far Right)
	vision_control.position = Vector2(w - pad - vision_w * (0.20), (h - btn_sz) * (-0.6))
	vision_control.size = Vector2(40, 40)
	
	# NodeName
	var name_x: float = node_icon.position.x + icon_sz + pad
	node_name_label.position = Vector2(name_x / 2.2, (h - btn_sz) * (-0.56))
	
	# ScriptBtn
	script_btn.position = Vector2(w - pad - vision_w - pad - btn_sz * (-1.15), (h - btn_sz) * (-0.5))
	script_btn.size = Vector2(40, 40)

# ────────────────────── Data & Logic ──────────────────────
func set_node_name(new_name: String) -> void:
	node_name_label.text = new_name

func set_data(data: Dictionary) -> void:
	_script_data = data
	
	# --- Calculate Indent based on Structure ---
	# "Main" -> 1 segment -> depth 0 -> 0px indent
	# "Main/UI" -> 2 segments -> depth 1 -> 10px indent
	# "Main/UI/Button" -> 3 segments -> depth 2 -> 20px indent
	var structure = data.get("structure", "")
	var segments = structure.split("/")
	var depth = segments.size() - 1
	_current_indent = BASE_INDENT * depth
	# --------------------------------------------
	
	var node_type = data.get("node_type", "Node")
	match node_type:
		"Node2D", "CharacterBody2D", "RigidBody2D", "StaticBody2D", "Area2D":
			node_icon.texture = ICON_NODE2D
		"Control", "Button", "Panel", "Label":
			node_icon.texture = ICON_CONTROL
		_:
			node_icon.texture = ICON_DEFAULT

	# --- Force ScriptBtn to be visible and add debug square ---
	if _script_data.get("script_state") == "enabled":
		script_btn.visible = true
		script_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if not script_btn.texture_normal:
			var debug_style := StyleBoxFlat.new()
			debug_style.bg_color = Color(0, 1, 0, 0.7)
			debug_style.border_color = Color(1, 1, 1, 1)
			debug_style.border_width_bottom = 2
			debug_style.border_width_top = 2
			debug_style.border_width_left = 2
			debug_style.border_width_right = 2
			script_btn.add_theme_stylebox_override("normal", debug_style)
			script_btn.add_theme_stylebox_override("pressed", debug_style)
			script_btn.add_theme_stylebox_override("hover", debug_style)
	else:
		script_btn.visible = false
		script_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_script_pressed() -> void:
	script_requested.emit(_script_data)

func _toggle_visibility() -> void:
	var is_now_visible = !visible_btn.visible
	visible_btn.visible = is_now_visible
	invisible_btn.visible = !is_now_visible
	visibility_toggled.emit(is_now_visible)

func _on_mouse_entered() -> void:
	if _script_data.get("script_state") == "enabled":
		script_btn.visible = true

func _on_mouse_exited() -> void:
	pass

# res://Scripts/UI/scene_tab.gd
extends Control

@onready var node_icon: TextureRect = $Layout/NodeIcon
@onready var node_name_label: Label = $Layout/NodeName
@onready var script_btn: TextureButton = $Layout/ScriptBtn
@onready var invisible_btn: TextureButton = $Layout/VisionControl/InvisibleBtn
@onready var visible_btn: TextureButton = $Layout/VisionControl/VisibleBtn

signal script_requested
signal visibility_toggled(is_visible)

func _ready() -> void:
	script_btn.visible = false
	invisible_btn.pressed.connect(_toggle_visibility)
	visible_btn.pressed.connect(_toggle_visibility)
	script_btn.pressed.connect(func(): script_requested.emit())

func set_icon(texture: Texture2D) -> void:
	node_icon.texture = texture

# --- FIX: Renamed from set_name to set_node_name ---
func set_node_name(new_name: String) -> void:
	node_name_label.text = new_name
# ---------------------------------------------------

func _toggle_visibility() -> void:
	var is_now_visible = !visible_btn.visible
	visible_btn.visible = is_now_visible
	invisible_btn.visible = !is_now_visible
	visibility_toggled.emit(is_now_visible)

# Optional: Show script button only when mouse hovers over the tab
func _on_mouse_entered() -> void:
	script_btn.visible = true

func _on_mouse_exited() -> void:
	script_btn.visible = false

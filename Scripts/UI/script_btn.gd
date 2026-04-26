extends Control

@onready var script_bg:        NinePatchRect = $ScriptBg
@onready var gear_icon:        TextureRect   = $Container/GearIcon
@onready var script_name_lbl:  Label         = $Container/ScriptName
@onready var script_btn:       Button        = $ScriptBtn

signal tab_pressed(script_name: String)

var _script_name: String = ""
var _is_active:   bool   = false

func _ready() -> void:
	script_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	script_btn.flat = true
	script_btn.text = ""
	script_btn.pressed.connect(_on_pressed)
	script_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	script_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Apply stored name NOW that onready vars are valid
	if _script_name != "":
		script_name_lbl.text = _script_name
		set_meta("script_name", _script_name)

	_sync_active()
	_update_layout()

func setup(sname: String) -> void:
	_script_name = sname  # just store it — don't touch @onready nodes here
	# If already in tree (called after _ready), apply immediately
	if is_node_ready():
		script_name_lbl.text = _script_name
		set_meta("script_name", _script_name)

func set_active(active: bool) -> void:
	_is_active = active
	_sync_active()

func _sync_active() -> void:
	if not is_node_ready(): return
	script_bg.modulate = Color(1, 1, 1, 0.8) if _is_active else Color(1, 1, 1, 1)

func _on_pressed() -> void:
	tab_pressed.emit(_script_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _update_layout() -> void:
	if not is_node_ready(): return
	var w := size.x
	var h := size.y
	var pad := 4.0
	var icon_sz := 16.0

	script_bg.size = Vector2(size.x * (1.065), 16)
	script_bg.position     = Vector2(w * (-0.03), h * (-0.1))
	# Container holds icon + label
	var container: Control = $Container
	container.position = Vector2(pad * 1.1, pad * (-2.2))

	gear_icon.position = Vector2(0, (h - icon_sz) * 0.5)
	gear_icon.size     = Vector2(icon_sz, icon_sz)

	script_name_lbl.position = Vector2(icon_sz + pad, pad / 4)
	script_name_lbl.size     = Vector2(w - icon_sz - pad * 3, h)
	script_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

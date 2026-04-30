# res://Scripts/UI/objective_ui.gd
extends Control

@onready var objective_bg:  NinePatchRect  = $ObjectiveBg
@onready var mission_text:  RichTextLabel  = $MissionText
@onready var title_label:   Label          = $TitleLabel
@onready var hint_label:    Label          = $HintLabel
@onready var hint_btn:      TextureButton  = $HintBtn
@onready var control_btn:   Control        = $ControlBtn
@onready var minimize_btn:  TextureButton  = $ControlBtn/MinimizeBtn
@onready var maximize_btn:  TextureButton  = $ControlBtn/MaximizeBtn

const PAD      := 10.0
const MIN_W    := 180.0
const LINE_H   := 22.0
const TITLE_H  := 28.0
const HINT_BTN_H := 20.0

var _minimized:    bool    = false
var _normal_size:  Vector2 = Vector2.ZERO

var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO
var _completed_indices: Array[int] = []

func _ready() -> void:
	add_to_group("objective_ui")
	for node in [objective_bg, mission_text, title_label, hint_label, hint_btn]:
		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

	mission_text.bbcode_enabled  = true
	mission_text.fit_content     = true
	mission_text.scroll_active   = false
	hint_label.visible           = false
	hint_btn.pressed.connect(_toggle_hint)

	ObjectiveTracker.objective_changed.connect(_on_objective_changed)
	ObjectiveTracker.objective_completed.connect(_on_objective_completed)
	ObjectiveTracker.progress_updated.connect(_on_progress_updated)
	ObjectiveTracker.mission_completed.connect(_on_mission_completed)

	minimize_btn.pressed.connect(_on_minimize)
	maximize_btn.pressed.connect(_on_maximize)
	maximize_btn.visible = false

	control_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)


	await get_tree().process_frame
	if ObjectiveTracker.current_mission:
		title_label.text = ObjectiveTracker.current_mission.mission_title
		_rebuild_all()

# ── Drag ───────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging    = true
			_drag_offset = get_global_mouse_position() - position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		position = get_global_mouse_position() - _drag_offset
		get_viewport().set_input_as_handled()

# ── Build ──────────────────────────────────────────────────────
func _rebuild_all() -> void:
	if not ObjectiveTracker.current_mission: return
	var objectives := ObjectiveTracker.current_mission.objectives
	var bb         := ""

	for i in objectives.size():
		var obj: LevelObjective = objectives[i]
		var progress := obj.get_progress()
		var line     := "%d. %s%s" % [i + 1, obj.description,
			" " + progress if progress != "" else ""]

		if _completed_indices.has(i):
			# Strikethrough + green
			bb += "[color=#44ff88][s]%s[/s][/color]\n" % line
		else:
			bb += "%s\n" % line

	mission_text.text = bb.strip_edges()
	_fit_size()

func _fit_size() -> void:
	await get_tree().process_frame
	# Width follows title text width
	var font       := title_label.get_theme_font("font")
	var font_size  := title_label.get_theme_font_size("font_size")
	var title_w    := font.get_string_size(
		title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var target_w   := maxf(title_w + PAD * 3, MIN_W)

	# Height = title + lines + hint btn + padding
	var obj_count  := ObjectiveTracker.current_mission.objectives.size()
	var target_h   := TITLE_H + (obj_count * LINE_H) + HINT_BTN_H + PAD * 3
	if hint_label.visible:
		target_h += hint_label.size.y + PAD

	size = Vector2(target_w, target_h)
	_update_layout()

func _on_minimize() -> void:
	_minimized   = true
	_normal_size = size
	minimize_btn.visible = false
	maximize_btn.visible = true
	mission_text.visible = false
	hint_btn.visible     = false
	hint_label.visible   = false
	# Shrink to title only
	size = Vector2(size.x, TITLE_H + PAD * 2)
	_update_layout()

func _on_maximize() -> void:
	_minimized   = false
	maximize_btn.visible = false
	minimize_btn.visible = true
	mission_text.visible = true
	hint_btn.visible     = true
	size = _normal_size if _normal_size != Vector2.ZERO else size
	_update_layout()

# Update _update_layout to position ControlBtn:
func _update_layout() -> void:
	if not is_node_ready(): return
	var w := size.x
	var h := size.y

	objective_bg.position  = Vector2.ZERO
	objective_bg.size      = size

	title_label.position   = Vector2(PAD, PAD)
	title_label.size       = Vector2(w - PAD * 3 - 20, TITLE_H)

	# ControlBtn top-right of title
	control_btn.position   = Vector2(w - PAD - 20, PAD + (TITLE_H - 20) * 0.5)
	control_btn.size       = Vector2(20, 20)
	minimize_btn.size      = Vector2(20, 20)
	maximize_btn.size      = Vector2(20, 20)

	if not _minimized:
		mission_text.position = Vector2(PAD, PAD + TITLE_H + 4)
		mission_text.size     = Vector2(w - PAD * 2,
			h - TITLE_H - HINT_BTN_H - PAD * 3)
		hint_btn.position     = Vector2(PAD, h - HINT_BTN_H - PAD)
		hint_btn.size         = Vector2(w - PAD * 2, HINT_BTN_H)
		hint_label.position   = Vector2(PAD, h - HINT_BTN_H - PAD)
		hint_label.size       = Vector2(w - PAD * 2, 60)

# ── Signals ────────────────────────────────────────────────────
func _on_objective_changed(_obj: LevelObjective) -> void:
	title_label.text = ObjectiveTracker.current_mission.mission_title
	_rebuild_all()

func _on_objective_completed(_obj: LevelObjective) -> void:
	# Find completed index
	var objectives := ObjectiveTracker.current_mission.objectives
	for i in objectives.size():
		if objectives[i] == _obj and not _completed_indices.has(i):
			_completed_indices.append(i)
			break
	_rebuild_all()

func _on_progress_updated(_obj: LevelObjective) -> void:
	_rebuild_all()

func _on_mission_completed(_m) -> void:
	mission_text.text = "[color=#ffdd44][b]🎉 Semua misi selesai![/b][/color]"
	_fit_size()

func _toggle_hint() -> void:
	hint_label.visible = !hint_label.visible
	var obj := ObjectiveTracker.current_mission.get_current_objective() \
		if ObjectiveTracker.current_mission else null
	if obj: hint_label.text = obj.hint
	_fit_size()

## Called externally on reset
func reset_display() -> void:
	_completed_indices.clear()
	_rebuild_all()

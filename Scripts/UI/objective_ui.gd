extends Control

@onready var objective_bg:   NinePatchRect  = $ObjectiveBg
@onready var mission_text:   RichTextLabel  = $MissionText
@onready var title_label:    Label          = $TitleLabel
@onready var hint_label:     Label          = $HintLabel
@onready var hint_btn:       TextureButton  = $HintBtn

const PAD := 8.0

var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	for node in [objective_bg, mission_text, title_label, hint_label, hint_btn]:
		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

	mission_text.bbcode_enabled = true
	hint_label.visible          = false

	hint_btn.pressed.connect(_toggle_hint)

	# Connect ObjectiveTracker signals
	ObjectiveTracker.objective_changed.connect(_on_objective_changed)
	ObjectiveTracker.objective_completed.connect(_on_objective_completed)
	ObjectiveTracker.progress_updated.connect(_on_progress_updated)
	ObjectiveTracker.mission_completed.connect(_on_mission_completed)

	_update_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _update_layout() -> void:
	if not is_node_ready(): return
	var w := size.x
	var h := size.y

	objective_bg.position = Vector2.ZERO
	objective_bg.size     = size

	title_label.position  = Vector2(PAD, PAD)
	title_label.size      = Vector2(w - PAD * 2, 20)

	mission_text.position = Vector2(PAD, PAD + 24)
	mission_text.size     = Vector2(w - PAD * 2, 40)

	hint_btn.position     = Vector2(PAD, PAD + 68)
	hint_btn.size         = Vector2(w - PAD * 2, 20)

	hint_label.position   = Vector2(PAD, PAD + 92)
	hint_label.size       = Vector2(w - PAD * 2, h - PAD * 2 - 92)

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

# ── Signals ────────────────────────────────────────────────────
func _on_objective_changed(obj: LevelObjective) -> void:
	title_label.text    = ObjectiveTracker.current_mission.mission_title \
		if ObjectiveTracker.current_mission else "Misi"
	mission_text.text   = "[b]%s[/b] %s" % [obj.description, obj.get_progress()]
	hint_label.text     = obj.hint
	hint_label.visible  = false

func _on_objective_completed(obj: LevelObjective) -> void:
	mission_text.text = "[color=#44ff88][b]✓ %s[/b][/color]" % obj.description
	await get_tree().create_timer(0.8).timeout
	var next := ObjectiveTracker.current_mission.get_current_objective() \
		if ObjectiveTracker.current_mission else null
	if next:
		_on_objective_changed(next)

func _on_progress_updated(obj: LevelObjective) -> void:
	mission_text.text = "[b]%s[/b] %s" % [obj.description, obj.get_progress()]

func _on_mission_completed(_m) -> void:
	mission_text.text  = "[color=#ffdd44][b]🎉 Misi Selesai![/b][/color]"
	hint_label.visible = false

func _toggle_hint() -> void:
	hint_label.visible = !hint_label.visible
	_update_layout()

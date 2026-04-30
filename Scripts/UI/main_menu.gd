extends Control

# ── Node refs ──────────────────────────────────────────────────
@onready var bg           := $Bg
@onready var godray       := $GodRay
@onready var sun          := $Sun
@onready var icons_node   := $Icons
@onready var icon1        := $Icons/Icon1
@onready var icon2        := $Icons/Icon2
@onready var icon3        := $Icons/Icon3
@onready var icon4        := $Icons/Icon4
@onready var levels_btn   := $LevelsBtn
@onready var exit_btn     := $ExitBtn
@onready var levels_cont  := $LevelsContainer
@onready var back_btn     := $LevelsContainer/BackBtn
@onready var grid         := $LevelsContainer/GridContainer
@onready var camera       := $Camera2D
@onready var fade_overlay := $FadeOverlay  # 👈 NEW!

@export var hover_sound:  AudioStream = null
@export var press_sound:  AudioStream = null

@export var random_textures: Array[Texture2D] = []
@export var level_resources: Array[LevelData] = []

var _in_levels_view := false
var _transitioning  := false
var _level_buttons:  Array = []

## ════════════════════════════════════════════════════════════
##  READY
## ════════════════════════════════════════════════════════════
func _ready() -> void:
	# 👇 FADE OVERLAY STARTS INVISIBLE!
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	levels_cont.visible = false

	levels_btn.pressed.connect(_on_levels_btn)
	exit_btn.pressed.connect(_on_exit_btn)
	back_btn.pressed.connect(_on_back_btn)
	
	icon1.pressed.connect(_roll_random_icon)
	icon2.pressed.connect(_roll_random_icon)
	icon3.pressed.connect(_roll_random_icon)
	icon4.pressed.connect(_roll_random_icon)

	for btn in [levels_btn, exit_btn, back_btn]:
		(btn as TextureButton).mouse_entered.connect(_play_sound.bind(hover_sound))
	
	_build_level_buttons()

## ════════════════════════════════════════════════════════════
##  BUILD LEVEL BUTTONS
## ════════════════════════════════════════════════════════════
func _build_level_buttons() -> void:
	for btn in _level_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_level_buttons.clear()
	
	for i in range(level_resources.size()):
		var level_data: LevelData = level_resources[i]
		
		var btn := TextureButton.new()
		btn.name = "LevelBtn_%s" % level_data.level_id
		btn.custom_minimum_size = Vector2(150, 80)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var lbl := Label.new()
		lbl.text = level_data.level_id.replace("_", " ").capitalize()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(lbl)
		
		var idx := i
		btn.pressed.connect(_on_level_pressed.bind(idx))
		btn.mouse_entered.connect(_play_sound.bind(hover_sound))
		
		grid.add_child(btn)
		_level_buttons.append(btn)

## ════════════════════════════════════════════════════════════
##  RANDOM ICON
## ════════════════════════════════════════════════════════════
func _roll_random_icon() -> void:
	if random_textures.is_empty():
		return
	
	_play_sound(press_sound)
	var picked_texture := random_textures[randi() % random_textures.size()]
	
	icon1.texture_normal = picked_texture
	icon2.texture_normal = picked_texture
	icon3.texture_normal = picked_texture
	icon4.texture_normal = picked_texture

## ════════════════════════════════════════════════════════════
##  LEVELS OPEN / CLOSE
## ════════════════════════════════════════════════════════════
func _on_levels_btn() -> void:
	if _transitioning or _in_levels_view: return
	_transitioning = true
	_play_sound(press_sound)

	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2(1.3, 1.3), 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tw.finished
	
	icon1.visible = false
	icon2.visible = false
	icon3.visible = false
	icon4.visible = false
	levels_btn.visible = false
	exit_btn.visible = false
	
	levels_cont.visible = true
	_in_levels_view   = true
	_transitioning = false

func _on_back_btn() -> void:
	if _transitioning or not _in_levels_view: return
	_transitioning = true
	_play_sound(press_sound)

	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tw.finished
	
	levels_cont.visible = false
	icon1.visible = true
	icon2.visible = true
	icon3.visible = true
	icon4.visible = true
	levels_btn.visible = true
	exit_btn.visible = true
	
	_in_levels_view   = false
	_transitioning = false

## ════════════════════════════════════════════════════════════
##  LEVEL PRESSED → ZOOM + FADE TRANSITION! 🎬
## ════════════════════════════════════════════════════════════
func _on_level_pressed(index: int) -> void:
	if index < 0 or index >= level_resources.size():
		return
	
	_play_sound(press_sound)
	
	var level_data: LevelData = level_resources[index]
	LevelManager.load_level(level_data)
	
	# ══════════════════════════════════════
	# 🎬 ZOOM + FADE COMBO TRANSITION!
	# ══════════════════════════════════════
	var tw := create_tween()
	tw.set_parallel(true)
	
	# Zoom camera IN (FIXED: was "tween", now "tw")
	tw.tween_property(camera, "zoom", Vector2(3.0, 3.0), 0.6)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Fade overlay TO black
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tw.finished
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")




## ════════════════════════════════════════════════════════════
##  EXIT (with fade too!)
## ════════════════════════════════════════════════════════════
func _on_exit_btn() -> void:
	_play_sound(press_sound)
	
	var tw := create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)  # FIXED: was TWEEN, now Tween
	
	await tw.finished
	get_tree().quit()

## ════════════════════════════════════════════════════════════
##  SOUND
## ════════════════════════════════════════════════════════════
func _play_sound(stream: AudioStream) -> void:
	AudioManager.play_music(preload("res://Assets/Sfx/start_menu.ogg"))
## ════════════════════════════════════════════════════════════
##  PUBLIC: Re-open menu
## ════════════════════════════════════════════════════════════
func open_menu() -> void:
	visible = true
	modulate.a = 1.0
	camera.zoom = Vector2(1.0, 1.0)
	fade_overlay.modulate.a = 0.0  # Reset fade!
	_in_levels_view = false
	levels_cont.visible = false
	
	icon1.visible = true
	icon2.visible = true
	icon3.visible = true
	icon4.visible = true
	levels_btn.visible = true
	exit_btn.visible = true

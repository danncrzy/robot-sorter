extends Control

# ── Node refs ──────────────────────────────────────────────────
@onready var bg           := $Bg
@onready var godray       := $GodRay
@onready var sun          := $Sun
@onready var title        := $Letter
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
@onready var fade_overlay := $FadeOverlay

@onready var level1_btn   := $LevelsContainer/GridContainer/Level1
@onready var level2_btn   := $LevelsContainer/GridContainer/Level2

@export var hover_sound:  AudioStream = null
@export var press_sound:  AudioStream = null

@export var random_textures: Array[Texture2D] = []
@export var level_resources: Array[LevelData] = []  # [level_01, level_02]

var _in_levels_view := false
var _transitioning  := false

## ════════════════════════════════════════════════════════════
##  READY
## ════════════════════════════════════════════════════════════
func _ready() -> void:
	AudioManager.play_music(preload("res://Assets/Sfx/start_menu.ogg"))
	# Fade overlay starts invisible!
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	levels_cont.visible = false
	
	# Wire main menu buttons
	levels_btn.pressed.connect(_on_levels_btn)
	exit_btn.pressed.connect(_on_exit_btn)
	back_btn.pressed.connect(_on_back_btn)
	
	# Icon clicks → random texture
	icon1.pressed.connect(_roll_random_icon)
	icon2.pressed.connect(_roll_random_icon)
	icon3.pressed.connect(_roll_random_icon)
	icon4.pressed.connect(_roll_random_icon)
	
	# 👇 WIRE YOUR EXISTING LEVEL BUTTONS TO ARRAY INDEX!
	level1_btn.pressed.connect(_on_level_pressed.bind(0))  # Index 0 = first resource
	level2_btn.pressed.connect(_on_level_pressed.bind(1))  # Index 1 = second resource
	
	# Hover sounds for all clickable things
	for btn in [levels_btn, exit_btn, back_btn, level1_btn, level2_btn]:
		(btn as TextureButton).mouse_entered.connect(AudioManager.play_sfx)

## ════════════════════════════════════════════════════════════
##  RANDOM ICON
## ════════════════════════════════════════════════════════════
func _roll_random_icon() -> void:
	if random_textures.is_empty():
		return
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_7.ogg"))
	
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
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_7.ogg"))

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
	title.visible = false

	
	levels_cont.visible = true
	_in_levels_view   = true
	_transitioning = false

func _on_back_btn() -> void:
	if _transitioning or not _in_levels_view: return
	_transitioning = true

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
##  LEVEL PRESSED → Load by Index from Array! 🎯
## ════════════════════════════════════════════════════════════
func _on_level_pressed(index: int) -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_7.ogg"))
	if index < 0 or index >= level_resources.size():
		push_error("Level index %d out of range" % index)
		return

	var level_data: LevelData = level_resources[index]
	print("Queuing level: ", level_data.level_id)

	# Store only — do NOT call load_level here
	LevelManager.current_level = level_data

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(camera, "zoom", Vector2(3.0, 3.0), 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished

	get_tree().change_scene_to_file("res://Scenes/main.tscn")

## ════════════════════════════════════════════════════════════
##  EXIT
## ════════════════════════════════════════════════════════════
func _on_exit_btn() -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_7.ogg"))
	var tw := create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tw.finished
	get_tree().quit()



## ════════════════════════════════════════════════════════════
##  PUBLIC
## ════════════════════════════════════════════════════════════
func open_menu() -> void:
	visible = true
	modulate.a = 1.0
	camera.zoom = Vector2(1.0, 1.0)
	fade_overlay.modulate.a = 0.0
	_in_levels_view = false
	levels_cont.visible = false
	
	icon1.visible = true
	icon2.visible = true
	icon3.visible = true
	icon4.visible = true
	levels_btn.visible = true
	exit_btn.visible = true
	title.visible = true

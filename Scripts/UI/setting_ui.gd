# res://Scripts/UI/setting_ui.gd
extends Control

@onready var setting_texture:   TextureRect   = $SettingUITexture
@onready var setting_label:     Label         = $SettingLabel
@onready var setting_container: VBoxContainer = $SettingContainer
@onready var master_slider:     HSlider       = $SettingContainer/MasterVolume/VolumeSlider
@onready var music_slider:      HSlider       = $SettingContainer/MusicVolume/MusicSlider
@onready var btn_container:     HBoxContainer = $ButtonContainer
@onready var home_btn:          TextureButton = $ButtonContainer/HomeBtn
@onready var back_btn:          TextureButton = $ButtonContainer/BackBtn

@export var slider_width_ratio: float = 0.65
@export var slider_height:      float = 16.0

var _open: bool = false

func _ready() -> void:
	_setup_slider(master_slider)
	_setup_slider(music_slider)

	# Make the parent HBoxContainers (MasterVolume / MusicVolume)
	# also expand horizontally inside the VBoxContainer
	for volume_row in setting_container.get_children():
		if volume_row is HBoxContainer:
			volume_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step      = 0.01
	master_slider.value     = 1.0

	music_slider.min_value  = 0.0
	music_slider.max_value  = 1.0
	music_slider.step       = 0.01
	music_slider.value      = 1.0

	master_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_master_volume(v)
	)
	music_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_music_volume(v)
	)

	home_btn.pressed.connect(_on_home_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	visible = false
	_update_layout()

func _setup_slider(slider: HSlider) -> void:
	# ── These two lines are the key fix ──
	# 1) Expand + fill tells the container to stretch this slider
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 2) custom_minimum_size is the ONLY size property containers respect
	slider.custom_minimum_size = Vector2(0, slider_height)

	# Optional: make the grabber easier to tap
	slider.custom_minimum_size.y = maxf(slider_height, 32.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _update_layout() -> void:
	if not is_node_ready(): return
	var w := size.x
	# The slider width is now handled by SIZE_EXPAND_FILL,
	# but we can set a minimum so it never shrinks below this
	var min_slider_w := w * slider_width_ratio
	master_slider.custom_minimum_size.x = min_slider_w
	music_slider.custom_minimum_size.x  = min_slider_w

func toggle() -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_8.ogg"))
	if _open: close()
	else:     open()

func open() -> void:
	_open   = true
	visible = true

func close() -> void:
	_open   = false
	visible = false

func _on_home_pressed() -> void:
	close()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_back_pressed() -> void:
	close()

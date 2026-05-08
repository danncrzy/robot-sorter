# res://Scripts/UI/move_toggle_btn.gd
extends TextureButton

signal move_toggled(enabled: bool)

var _move_enabled: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_8.ogg"))
	_move_enabled = !_move_enabled
	modulate = Color(1.0, 0.6, 0.2) if _move_enabled else Color.WHITE
	move_toggled.emit(_move_enabled)

# res://Scripts/UI/setting_ui.gd
extends Control

@onready var setting_texture:   TextureRect  = $SettingUITexture
@onready var setting_label:     Label        = $SettingLabel
@onready var master_slider:     HSlider      = $SettingContainer/MasterVolume/VolumeSlider
@onready var music_slider:      HSlider      = $SettingContainer/MusicVolume/MusicSlider
@onready var gray_overlay:      ColorRect    = get_parent().get_node("GrayOverlay")

const TWEEN_DUR := 0.35

# Shader param targets
const PARAMS_ACTIVE := {
	"fog_strength":      0.2,
	"vignette_strength": 0.058,
}
const PARAMS_INACTIVE := {
	"fog_strength":      0.0,
	"vignette_strength": 0.0,
}

var _open:  bool  = false
var _tween: Tween = null

func _ready() -> void:
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

	visible = false
	_set_shader_params(PARAMS_INACTIVE, false)

# ── Toggle ─────────────────────────────────────────────────────
func toggle() -> void:
	if _open: close()
	else:     open()

func open() -> void:
	_open   = true
	visible = true
	_animate_shader(PARAMS_ACTIVE)

func close() -> void:
	_open = false
	_animate_shader(PARAMS_INACTIVE)
	# Hide after tween finishes
	if is_instance_valid(_tween):
		_tween.finished.connect(func() -> void:
			visible = false
		, CONNECT_ONE_SHOT)

# ── Shader animation ───────────────────────────────────────────
func _animate_shader(target_params: Dictionary) -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var mat := gray_overlay.material as ShaderMaterial
	if not mat: return
	for param in target_params:
		var from: float = mat.get_shader_parameter(param)
		var to:   float = target_params[param]
		_tween.parallel().tween_method(
			func(v: float) -> void: mat.set_shader_parameter(param, v),
			from, to, TWEEN_DUR
		)

func _set_shader_params(params: Dictionary, animated: bool) -> void:
	var mat := gray_overlay.material as ShaderMaterial
	if not mat: return
	if animated:
		_animate_shader(params)
	else:
		for param in params:
			mat.set_shader_parameter(param, params[param])

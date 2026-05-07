extends Control

const SAVE_PATH         := "user://text_editor_settings.cfg"
const FONT_SIZE_MIN     := 9
const FONT_SIZE_MAX     := 32
const FONT_SIZE_DEFAULT := 9

@onready var setting_bg:        NinePatchRect = $TextEditorSetting
@onready var font_label:        Label         = $ElementContainer/FontLabel
@onready var plus_btn:          TextureButton = $ElementContainer/PlusBtn
@onready var minus_btn:         TextureButton = $ElementContainer/MinusBtn
@onready var text_editor_panel: Control       = get_parent().get_node("TextEditorPanel")
@onready var code_edit:         CodeEdit      = get_parent().get_node("TextEditorPanel/CodeEdit")

var _font_size: int = FONT_SIZE_DEFAULT

func _ready() -> void:
	visible = false

	var setting_btn := get_parent().get_node_or_null("TitleBar/SettingBtn")
	if setting_btn:
		setting_btn.pressed.connect(toggle)
	else:
		push_warning("SettingUI: SettingBtn not found in TitleBar!")

	plus_btn.pressed.connect(_on_font_increase_pressed)
	minus_btn.pressed.connect(_on_font_decrease_pressed)

	_load_settings()
	_apply_font_size()
	_match_panel_size()

func toggle() -> void:
	visible = !visible
	if visible:
		_match_panel_size()
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_5.ogg"))

func _match_panel_size() -> void:
	var panel := get_parent().get_node_or_null("TextEditorPanel")
	if not panel: return
	position        = panel.position
	size            = panel.size
	setting_bg.size = panel.size
	
	
func _on_font_increase_pressed() -> void:
	if _font_size >= FONT_SIZE_MAX: return
	_font_size += 1
	_apply_font_size()
	_save_settings()

func _on_font_decrease_pressed() -> void:
	if _font_size <= FONT_SIZE_MIN: return
	_font_size -= 1
	_apply_font_size()
	_save_settings()

func _apply_font_size() -> void:
	if code_edit:
		code_edit.add_theme_font_size_override("font_size", _font_size)
	font_label.text = str(_font_size)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("editor", "font_size", _font_size)
	cfg.save(SAVE_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK: return
	_font_size = cfg.get_value("editor", "font_size", FONT_SIZE_DEFAULT)

extends CanvasLayer

@onready var scene_tree_panel: Control        = $SceneTreePanel
@onready var text_editor:      Control        = $TextEditorUI
@onready var documents:        Control        = $DocumentsUI
@onready var script_btn:       TextureButton  = $ScriptBtn
@onready var documents_btn:    TextureButton  = $DocumentsBtn
@onready var setting_btn:      TextureButton  = $SettingBtn
@onready var setting_ui:       Control        = $SettingUI
@onready var grid_btn:         TextureButton  = $GridBtn 
@onready var visibility_btn:   TextureButton  = $VisibilityBtn
@onready var scene_tree:       Control        = $SceneTreePanel
@onready var documents_ui:     Control        = $DocumentsUI
@onready var move_btn:         TextureButton  = $MoveBtn
@onready var gray_overlay:     ColorRect      = $GrayOverlay
@onready var objective_ui:     Control        = $ObjectiveUI

var _ui_hidden := false
var _toggleable: Array[Node] = []
var _saved_states: Dictionary = {}

var _tile_labels_visible: bool = false 
func _ready() -> void:
	script_btn.pressed.connect(_toggle_editor)
	documents_btn.pressed.connect(_toggle_docs)
	text_editor.visible = false
	documents.visible   = false
	setting_btn.pressed.connect(setting_ui.toggle)
	AudioManager.play_music(preload("res://Assets/Sfx/rainy_day_bgm.ogg"))

	grid_btn.pressed.connect(_on_grid_btn_pressed)
	
	_set_tile_labels_visible(false)
	
	_toggleable = [
		scene_tree, setting_ui,
		grid_btn, script_btn, documents_btn, setting_btn,
		move_btn, gray_overlay, objective_ui
	]
	visibility_btn.pressed.connect(_toggle_ui)
func _toggle_editor() -> void:
	text_editor.visible = !text_editor.visible
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/script_btn_open.ogg"))

func _toggle_docs() -> void:
	documents.visible = !documents.visible
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/book_open.ogg"))

func open_script_in_editor(script_name: String, content: String) -> void:
	text_editor.open_script(script_name, content)

func populate_scene_tree(node_data: Array) -> void:
	scene_tree_panel.populate(node_data)

func _on_grid_btn_pressed() -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_8.ogg"))
	# Toggle state
	_tile_labels_visible = !_tile_labels_visible
	_set_tile_labels_visible(_tile_labels_visible)
	
	# Optional: Visual feedback on button

func _set_tile_labels_visible(visible: bool) -> void:
	# Find the HintContainer (it's in group "hint_container")
	var hint_container = get_tree().get_first_node_in_group("hint_container")
	
	if not hint_container:
		return
	
	# Get the Grid container inside it
	var grid = hint_container.get_node_or_null("Grid")
	if not grid:
		push_warning("GridBtn: Grid not found in HintContainer!")
		return
	
	# Loop through ALL tile hints and toggle their TileVector label
	for tile_hint in grid.get_children():
		var label = tile_hint.get_node_or_null("TileVector")
		if label:
			label.visible = visible
			
func _toggle_ui() -> void:
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_8.ogg"))
	if not _ui_hidden:
		# Save current visible state of each node, then hide all
		_saved_states.clear()
		for node in _toggleable:
			if is_instance_valid(node):
				_saved_states[node] = node.visible
				node.visible = false
		_ui_hidden = true
	else:
		# Restore exact previous state
		for node in _toggleable:
			if is_instance_valid(node) and _saved_states.has(node):
				node.visible = _saved_states[node]
		_ui_hidden = false

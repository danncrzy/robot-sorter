extends CanvasLayer

@onready var scene_tree_panel: Control      = $SceneTreePanel
@onready var text_editor:      Control      = $TextEditorUI
@onready var documents:        Control      = $DocumentsUI
@onready var script_btn:       TextureButton = $ScriptBtn
@onready var documents_btn:    TextureButton = $DocumentsBtn

func _ready() -> void:
	script_btn.pressed.connect(_toggle_editor)
	documents_btn.pressed.connect(_toggle_docs)
	text_editor.visible = false
	documents.visible   = false

func _toggle_editor() -> void:
	text_editor.visible = !text_editor.visible

func _toggle_docs() -> void:
	documents.visible = !documents.visible

func open_script_in_editor(script_name: String, content: String) -> void:
	text_editor.open_script(script_name, content)

func populate_scene_tree(node_data: Array) -> void:
	scene_tree_panel.populate(node_data)

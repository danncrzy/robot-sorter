extends TextureButton

@onready var code_edit: CodeEdit = $TextEditorUI/TextEditorPanel/CodeEdit

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not code_edit: return
	code_edit.insert_text_at_caret("\t")
	code_edit.grab_focus()

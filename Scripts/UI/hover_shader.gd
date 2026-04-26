# res://Scripts/UI/hover_shader.gd
extends TextureButton

# Preload your shader
const OUTLINE_SHADER = preload("res://Resources/Shader/2d_outline.tres")

var _outline_material: ShaderMaterial

func _ready() -> void:
	_outline_material = OUTLINE_SHADER

	
	# Connect the hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	material = _outline_material

func _on_mouse_exited() -> void:
	material = null

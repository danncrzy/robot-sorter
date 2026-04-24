# res://Scripts/UI/sticky_note.gd
extends Control
class_name StickyNote

enum NoteColor { RED, PINK, YELLOW, GREEN }

@onready var clear_btn: TextureButton = $ClearBtn
@onready var overlapping_btn: TextureButton = $OverlappingBtn

var note_color: NoteColor = NoteColor.RED
var linked_spread: int = 0
var documents_ui: Node = null 

signal navigate_to_spread(spread_index: int)
signal request_delete(note_node: Control)

var textures = {
	NoteColor.RED: {
		"clear": preload("res://Assets/UI/RedStickyNotes.png"),
		"clear_pressed": preload("res://Assets/UI/RedStickyNotes_Pressed.png"),
		"visible": preload("res://Assets/UI/RedStickyNotes_Visible.png"),
		"visible_pressed": preload("res://Assets/UI/RedStickyNotes_Visible_Pressed.png")
	},
	NoteColor.PINK: {
		"clear": preload("res://Assets/UI/PinkStickyNotes.png"),
		"clear_pressed": preload("res://Assets/UI/PinkStickyNotes_Pressed.png"),
		"visible": preload("res://Assets/UI/PinkStickyNotes_Visible.png"),
		"visible_pressed": preload("res://Assets/UI/PinkStickyNotes_Visible_Pressed.png")
	},
	NoteColor.YELLOW: {
		"clear": preload("res://Assets/UI/YellowStickyNotes.png"),
		"clear_pressed": preload("res://Assets/UI/YellowStickyNotes_Pressed.png"),
		"visible": preload("res://Assets/UI/YellowStickyNotes_Visible.png"),
		"visible_pressed": preload("res://Assets/UI/YellowStickyNotes_Visible_Pressed.png")
	},
	NoteColor.GREEN: {
		"clear": preload("res://Assets/UI/GreenStickyNotes.png"),
		"clear_pressed": preload("res://Assets/UI/GreenStickyNotes_Pressed.png"),
		"visible": preload("res://Assets/UI/GreenStickyNotes_Visible.png"),
		"visible_pressed": preload("res://Assets/UI/GreenStickyNotes_Visible_Pressed.png")
	}
}

func _ready() -> void:
	clear_btn.pressed.connect(_on_clear_pressed)
	overlapping_btn.pressed.connect(_on_overlap_pressed)

func setup(color: NoteColor, spread: int, ui_ref: Node) -> void:
	note_color = color
	linked_spread = spread
	documents_ui = ui_ref
	
	clear_btn.texture_normal = textures[color]["visible"]           
	clear_btn.texture_pressed = textures[color]["visible_pressed"]  
	
	overlapping_btn.texture_normal = textures[color]["clear"]           
	overlapping_btn.texture_pressed = textures[color]["clear_pressed"]  
	
	# Force shrink to texture size
	custom_minimum_size = Vector2.ZERO 
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	update_phase(spread)

func update_phase(current_spread: int) -> void:
	if current_spread == linked_spread:
		clear_btn.visible = true
		overlapping_btn.visible = false
	else:
		clear_btn.visible = false
		overlapping_btn.visible = true

func _on_clear_pressed() -> void:
	# If the delete tool is active, delete the note. Otherwise do nothing.
	if documents_ui and documents_ui.is_delete_mode:
		request_delete.emit(self)

func _on_overlap_pressed() -> void:
	# If the delete tool is active, delete the note. Otherwise navigate to the page.
	if documents_ui and documents_ui.is_delete_mode:
		request_delete.emit(self)
	else:
		navigate_to_spread.emit(linked_spread)

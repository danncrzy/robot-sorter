# res://Scripts/UI/sticky_note.gd
extends Control
class_name StickyNote

enum NoteColor { RED, PINK, YELLOW, GREEN }

@onready var clear_btn: TextureButton = $ClearBtn
@onready var overlapping_btn: TextureButton = $OverlappingBtn

var note_color: NoteColor = NoteColor.RED
var linked_page: int = 0 # CHANGED: Now tracks exact page index (0=Left1, 1=Right1, 2=Left2, etc.)
var documents_ui: Node = null 

signal navigate_to_page(page_index: int) # CHANGED
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

func setup(color: NoteColor, page_idx: int, ui_ref: Node) -> void:
	note_color = color
	linked_page = page_idx
	documents_ui = ui_ref
	
	clear_btn.texture_normal = textures[color]["visible"]           
	clear_btn.texture_pressed = textures[color]["visible_pressed"]  
	overlapping_btn.texture_normal = textures[color]["clear"]           
	overlapping_btn.texture_pressed = textures[color]["clear_pressed"]  
	
	custom_minimum_size = Vector2.ZERO 
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Pass the correct initial spread based on the page index
	update_phase(page_idx / 2)

func update_phase(current_spread: int) -> void:
	# Check if the currently viewed spread contains our linked page
	var is_on_spread = (current_spread == linked_page / 2)
	
	if is_on_spread:
		# We are looking at the spread with the note
		clear_btn.visible = true
		overlapping_btn.visible = false
	else:
		# We are on a different spread
		clear_btn.visible = false
		overlapping_btn.visible = true

func _on_clear_pressed() -> void:
	# If delete tool is active, delete the note. Otherwise do nothing 
	# (you are already viewing the page the note is on!)
	if documents_ui and documents_ui.is_delete_mode:
		request_delete.emit(self)

func _on_overlap_pressed() -> void:
	if documents_ui and documents_ui.is_delete_mode:
		request_delete.emit(self)
	else:
		# Navigate to the exact page index this note is linked to
		navigate_to_page.emit(linked_page)

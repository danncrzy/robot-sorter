# res://Scripts/UI/draggable_button.gd
extends TextureButton

@export var note_color: StickyNote.NoteColor = StickyNote.NoteColor.RED
var documents_ui: DocumentsUI

var is_dragging = false
var drag_ghost: TextureButton = null
var drag_offset = Vector2.ZERO

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Find the Documents UI automatically
	var current_node = get_parent()
	while current_node:
		if current_node is DocumentsUI:
			documents_ui = current_node
			break
		current_node = current_node.get_parent()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			
			# Create a ghost copy
			drag_ghost = TextureButton.new()
			drag_ghost.texture_normal = texture_normal
			drag_ghost.ignore_texture_size = true
			drag_ghost.stretch_mode = TextureButton.STRETCH_SCALE
			drag_ghost.size = size
			drag_ghost.z_index = 100
			drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			drag_ghost.modulate.a = 0.8 # Slight transparency so you know you're dragging
			
			if documents_ui:
				documents_ui.add_child(drag_ghost) 
			drag_ghost.global_position = global_position
			
		else:
			if is_dragging:
				is_dragging = false
				_check_drop()
				# Delete the ghost copy safely
				if is_instance_valid(drag_ghost):
					drag_ghost.queue_free()
					drag_ghost = null

func _process(_delta):
	# Move the ghost, NOT the original button!
	if is_dragging and is_instance_valid(drag_ghost):
		drag_ghost.global_position = get_global_mouse_position() - drag_offset

func _check_drop():
	if not is_instance_valid(documents_ui):
		return

	var mouse_pos = get_global_mouse_position()
	var target_container: HBoxContainer = null # <--- CHANGED FROM VBoxContainer TO HBoxContainer
	
	# Check if dropped on Left Page "Zone"
	if documents_ui.left_page.get_global_rect().has_point(mouse_pos):
		target_container = documents_ui.left_sticky_container
	# Check if dropped on Right Page "Zone"
	elif documents_ui.right_page.get_global_rect().has_point(mouse_pos):
		target_container = documents_ui.right_sticky_container
		
	if target_container:
		if target_container.get_child_count() < documents_ui.MAX_STICKY_NOTES:
			documents_ui.spawn_sticky_note(note_color, mouse_pos, target_container)

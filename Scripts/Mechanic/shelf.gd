extends StaticBody2D

signal box_stored(box_color: String)
signal shelf_full

@export var max_capacity:    int  = 5
@export var target_color:    String = ""  
@export var shelf_id:        String = "shelf_01"

@onready var detect_area:    Area2D       = $DetectArea
@onready var box_display:    HBoxContainer = $BoxDisplay

const BOX_SCENES: Dictionary = {
	"Yellow": preload("res://Scenes/UI/BoxIndicator/yellow_box.tscn"),
	"Green":  preload("res://Scenes/UI/BoxIndicator/green_box.tscn"),
}

var _stored_boxes:   Array[String] = []

func _ready() -> void:
	add_to_group("shelf")
	detect_area.body_entered.connect(_on_body_entered)
	detect_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var ic := body.get_node_or_null("InteractionComponent")
		if ic:
			ic.register_nearby_shelf(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var ic := body.get_node_or_null("InteractionComponent")
		if ic:
			ic.unregister_nearby_shelf(self)

func try_receive_box(box: Node) -> bool:
	print("[SHELF] try_receive_box called with box: ", box.name)
	
	if _stored_boxes.size() >= max_capacity:
		print("[SHELF] Shelf is full!")
		shelf_full.emit()
		return false
		
	var color: String = box.get_color() if box.has_method("get_color") else "Yellow"
	print("[SHELF] Box color: ", color, " | Shelf target_color: ", target_color)
	
	if target_color != "" and color != target_color:
		print("[SHELF] Box color does not match target color!")
		return false

	print("[SHELF] Box accepted! Calling on_dropped.")
	box.on_dropped(self)
	_stored_boxes.append(color)
	print("[SHELF] Current stored boxes: ", _stored_boxes)
	
	_spawn_box_indicator(color)
	box_stored.emit(color)

	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if tracker:
		print("[SHELF] Notifying objective tracker for rack_id: ", shelf_id)
		tracker.notify_returned_to_rack(shelf_id)
	else:
		print("[SHELF] ERROR - Objective tracker not found!")

	return true

func _spawn_box_indicator(color: String) -> void:
	print("[SHELF] Spawning box indicator for color: ", color)
	if not BOX_SCENES.has(color):
		print("[SHELF] ERROR - Box scene not found for color: ", color)
		return
		
	var indicator := (BOX_SCENES[color] as PackedScene).instantiate()
	if indicator:
		box_display.add_child(indicator)
		indicator.visible = true
		
		if indicator is Control:
			indicator.custom_minimum_size = Vector2(10,10)
			
		# THE ULTIMATE DEBUG PRINT
		print("[SHELF] BoxDisplay Global Pos: ", box_display.global_position, " | Indicator Global Pos: ", indicator.global_position, " | Indicator Size: ", indicator.size)
		
		# If the indicator is a TextureRect, check if it has a texture!
		if indicator is TextureRect and indicator.texture == null:
			print("[SHELF] ERROR - Indicator TextureRect has NO TEXTURE assigned in its scene!")

func get_stored_count() -> int:
	return _stored_boxes.size()

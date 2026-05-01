extends StaticBody2D

signal box_stored(box_color: String)
signal shelf_full

@export var max_capacity:    int  = 5
@export var target_color:    String = ""  
@export var shelf_id:        String = "shelf_01"

@onready var detect_area:    Area2D       = $DetectArea
@onready var box_display:    HBoxContainer = $BoxDisplay

# Preloaded box indicator scenes
const BOX_SCENES: Dictionary = {
	"Yellow": preload("res://Scenes/UI/BoxIndicator/yellow_box.tscn"),
	"Green":  preload("res://Scenes/UI/BoxIndicator/green_box.tscn"),
}

var _stored_boxes:   Array[String] = []
var _player_inside:  bool          = false
var _player_ref:     Node          = null

func _ready() -> void:
	add_to_group("shelf")
	detect_area.body_entered.connect(_on_body_entered)
	detect_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_inside = true
		_player_ref    = body

func _on_body_exited(body: Node) -> void:
	if body == _player_ref:
		_player_inside = false
		_player_ref    = null

## Called by InteractionComponent when player uses drop()
func try_receive_box(box: Node) -> bool:
	if not _player_inside: return false
	if _stored_boxes.size() >= max_capacity:
		shelf_full.emit()
		return false
	var color: String = box.get_color() if box.has_method("get_color") else "Yellow"
	if target_color != "" and color != target_color: return false

	box.on_dropped(self)
	_stored_boxes.append(color)
	_spawn_box_indicator(color)
	box_stored.emit(color)

	# Notify ObjectiveTracker
	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if tracker:
		tracker.notify_returned_to_rack(shelf_id)

	return true

func _spawn_box_indicator(color: String) -> void:
	if not BOX_SCENES.has(color): return
	var indicator := (BOX_SCENES[color] as PackedScene).instantiate()
	box_display.add_child(indicator)

func get_stored_count() -> int:
	return _stored_boxes.size()

func is_player_nearby() -> bool:
	return _player_inside

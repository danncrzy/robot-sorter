extends Node

var _parent:       CharacterBody2D = null
var _held_item:    Node            = null
var _nearby_shelf: Node            = null
var _nearby_box: Node = null

signal item_grabbed(item: Node)
signal item_dropped(item: Node)

func _ready() -> void:
	_parent = get_parent()

func register_nearby_box(box: Node) -> void:
	_nearby_box = box

func unregister_nearby_box(box: Node) -> void:
	if _nearby_box == box:
		_nearby_box = null
		
func register_nearby_shelf(shelf: Node) -> void:
	_nearby_shelf = shelf

func unregister_nearby_shelf(shelf: Node) -> void:
	if _nearby_shelf == shelf:
		_nearby_shelf = null

func grab() -> void:
	if _held_item:
		return
	if not _nearby_box:
		return
		
	_held_item = _nearby_box
	_nearby_box = null
	_held_item.on_grabbed(_parent)
	item_grabbed.emit(_held_item)
	
	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if tracker:
		var color = _held_item.get_color() if _held_item.has_method("get_color") else ""
		tracker.notify_grabbed(color)

func drop() -> void:
	if not _held_item: return
	
	if _nearby_shelf and _nearby_shelf.has_method("try_receive_box"):
		var accepted = _nearby_shelf.try_receive_box(_held_item)
		if accepted:
			item_dropped.emit(_held_item)
			_held_item = null
			return
			
	# No shelf nearby or shelf rejected - drop on the floor
	var drop_pos := _parent.global_position
	var movement := _parent.get_node_or_null("MovementComponent")
	if movement:
		var fv = movement._facing_vector()
		drop_pos = _parent.global_position + Vector2(fv.x, fv.y) * movement.TILE_SIZE

	if _held_item.has_method("on_dropped"):
		_held_item.on_dropped(null, drop_pos)
		
	item_dropped.emit(_held_item)
	_held_item = null
	
func interact() -> void:
	pass # Handle other interactions if needed

func is_holding() -> bool:    return _held_item != null
func get_held_item() -> Node: return _held_item

func reset() -> void:
	if _held_item:
		if _held_item.has_method("on_dropped"):
			_held_item.on_dropped()
		_held_item = null

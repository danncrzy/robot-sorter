extends Node

var _parent:       CharacterBody2D = null
var _held_item:    Node            = null
var _nearby_shelf: Node            = null

signal item_grabbed(item: Node)
signal item_dropped(item: Node)

func _ready() -> void:
	_parent = get_parent()

func grab() -> void:
	if _held_item: return
	var front := _get_front_area()
	if front and front.has_method("on_grabbed"):
		_held_item = front
		front.on_grabbed(_parent)
		item_grabbed.emit(front)
		# Notify tracker
		var tracker := get_tree().get_first_node_in_group("objective_tracker")
		if tracker:
			var color = front.get_color() if front.has_method("get_color") else ""
			tracker.notify_grabbed(color)

func drop() -> void:
	if not _held_item: return
	# Check if near a shelf
	var shelf := _find_nearby_shelf()
	if shelf and shelf.has_method("try_receive_box"):
		var accepted = shelf.try_receive_box(_held_item)
		if accepted:
			item_dropped.emit(_held_item)
			_held_item = null
			return
	# Drop on ground
	if _held_item.has_method("on_dropped"):
		_held_item.on_dropped()
	item_dropped.emit(_held_item)
	_held_item = null

func interact() -> void:
	var front := _get_front_area()
	if front and front.has_method("on_interact"):
		front.on_interact(_parent)

func is_holding() -> bool:    return _held_item != null
func get_held_item() -> Node: return _held_item

func reset() -> void:
	if _held_item:
		if _held_item.has_method("on_dropped"):
			_held_item.on_dropped()
		_held_item = null

func _find_nearby_shelf() -> Node:
	# Shelves register themselves — find one where player is inside DetectArea
	var shelves := get_tree().get_nodes_in_group("shelf")
	for s in shelves:
		if s.has_method("is_player_nearby") and s.is_player_nearby():
			return s
	return null

func _get_front_area() -> Node:
	# Fixed node path — uses actual component name
	var movement: Node = _parent.get_node_or_null("MovementCompon")
	if not movement: return null
	var fv        = movement._facing_vector()
	var check_pos = _parent.global_position + Vector2(fv.x, fv.y) * movement.TILE_SIZE
	var space     := _parent.get_world_2d().direct_space_state
	var query     := PhysicsPointQueryParameters2D.new()
	query.position       = check_pos
	query.collision_mask = 0xFFFFFFFF
	var results := space.intersect_point(query)
	for r in results:
		var col: Object = r.get("collider")
		if col and col != _parent:
			return col
	return null

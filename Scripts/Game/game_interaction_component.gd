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
	print("[IC] Nearby box registered: ", box.name)

func unregister_nearby_box(box: Node) -> void:
	if _nearby_box == box:
		_nearby_box = null
		print("[IC] Nearby box unregistered: ", box.name)

func grab() -> void:
	if _held_item:
		print("[GRAB] Already holding: ", _held_item.name)
		return
	if not _nearby_box:
		print("[GRAB] FAIL — no box in range")
		return
	print("[GRAB] Grabbing: ", _nearby_box.name)
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
	var shelf := _find_nearby_shelf()
	if shelf and shelf.has_method("try_receive_box"):
		var accepted = shelf.try_receive_box(_held_item)
		if accepted:
			item_dropped.emit(_held_item)
			_held_item = null
			return
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
	var shelves := get_tree().get_nodes_in_group("shelf")
	for s in shelves:
		if s.has_method("is_player_nearby") and s.is_player_nearby():
			return s
	return null

func _get_front_area() -> Node:
	var movement: Node = _parent.get_node_or_null("MovementComponent")
	if not movement:
		return null
		
	var fv = movement._facing_vector()
	var check_pos_front = _parent.global_position + Vector2(fv.x, fv.y) * movement.TILE_SIZE
	var check_pos_current = _parent.global_position
	
	var space := _parent.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask      = 0xFFFFFFFF
	query.collide_with_areas  = true   # ← Crucial for detecting Area2D boxes!
	query.collide_with_bodies = true   # ← Still checks shelves/other things

	# ── Check 1: The tile in front of the player ──
	query.position = check_pos_front
	var results_front := space.intersect_point(query)
	for r in results_front:
		var col: Object = r.get("collider")
		if col and col != _parent and col.has_method("on_grabbed"):
			return col

	# ── Check 2: The tile the player is standing on (since boxes aren't walls anymore) ──
	query.position = check_pos_current
	var results_current := space.intersect_point(query)
	for r in results_current:
		var col: Object = r.get("collider")
		if col and col != _parent and col.has_method("on_grabbed"):
			return col

	return null

# res://Scripts/Game/game_interaction_component.gd
extends Node

var _parent:    CharacterBody2D = null
var _held_item: Node = null

signal item_grabbed(item: Node)
signal item_dropped(item: Node)

func _ready() -> void:
	_parent = get_parent()

## Pick up item in front of player.
func grab() -> void:
	if _held_item: return
	var front := _get_front_area()
	if front and front.has_method("on_grabbed"):
		_held_item = front
		front.on_grabbed(_parent)
		item_grabbed.emit(front)

## Drop currently held item.
func drop() -> void:
	if not _held_item: return
	if _held_item.has_method("on_dropped"):
		_held_item.on_dropped()
	item_dropped.emit(_held_item)
	_held_item = null

## Interact with object in front.
func interact() -> void:
	var front := _get_front_area()
	if front and front.has_method("on_interact"):
		front.on_interact(_parent)

## Returns true if holding an item.
func is_holding() -> bool:
	return _held_item != null

## Returns held item or null.
func get_held_item() -> Node:
	return _held_item

func reset() -> void:
	if _held_item:
		drop()

func _get_front_area() -> Node:
	var movement: Node = _parent.get_node_or_null("GameMovementComponent")
	if not movement: return null
	var check_pos: Vector2 = _parent.global_position \
		+ Vector2(movement._facing_vector()) * movement.TILE_SIZE
	# Check overlapping areas at front position
	var space := _parent.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position    = check_pos
	query.collision_mask = 0xFFFFFFFF
	var results := space.intersect_point(query)
	for r in results:
		var col: Object = r.get("collider")
		if col and col != _parent:
			return col
	return null

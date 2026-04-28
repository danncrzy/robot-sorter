extends Node

const TILE_SIZE:  float = 16.0
const MOVE_SPEED: float = 120.0

enum Direction { RIGHT, LEFT, UP, DOWN }

var _parent:         CharacterBody2D = null
var _animations:     AnimatedSprite2D = null
var _tilemap:        TileMapLayer = null
var _facing:         Direction = Direction.RIGHT
var _is_moving:      bool = false
var _move_queue:     Array[Vector2] = []
var _start_position: Vector2 = Vector2.ZERO
var _start_facing:   Direction = Direction.RIGHT
var _tween:          Tween = null
var _processing:     bool = false

func _ready() -> void:
	_parent         = get_parent() as CharacterBody2D
	_animations     = _parent.get_node_or_null("PlayerAnimations")
	_tilemap        = _parent.get_node_or_null("../../FactoryFloor")
	_start_position = _parent.global_position
	_start_facing   = _facing
	_play_anim("Idle")

# ══════════════════════════════════════════════════════════════
#  QUEUE PROCESSOR
# ══════════════════════════════════════════════════════════════
func _process_next() -> void:
	if _processing:
		return
	_processing = true

	if _move_queue.is_empty():
		_is_moving  = false
		_processing = false
		_play_anim("Idle")
		return

	_is_moving = true

	var target:    Vector2 = _move_queue[0]
	var direction: Vector2 = (target - _parent.global_position).normalized()

	# ── Raycast — check one tile ahead before committing ──────
	var space_state := _parent.get_world_2d().direct_space_state
	var ray_end     := _parent.global_position + direction * (TILE_SIZE - 2.0)
	var query       := PhysicsRayQueryParameters2D.create(
		_parent.global_position,
		ray_end,
		0xFFFFFFFF,
		[_parent.get_rid()]          # exclude self
	)
	var hit := space_state.intersect_ray(query)

	if not hit.is_empty():
		# Blocked — skip this tile, continue with next queued command
		_move_queue.pop_front()
		_processing = false
		_process_next()
		return

	# ── Animation based on direction ──────────────────────────
	_play_directional_anim(direction)

	var dist: float = _parent.global_position.distance_to(target)
	var dur:  float = dist / MOVE_SPEED

	if is_instance_valid(_tween):
		_tween.kill()

	_tween = _parent.create_tween()
	_tween.tween_property(_parent, "global_position", target, dur) \
		.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(func() -> void:
		_processing = false
		_move_queue.pop_front()
		_process_next()
	)

# ══════════════════════════════════════════════════════════════
#  ANIMATION HELPER
# ══════════════════════════════════════════════════════════════
func _play_directional_anim(direction: Vector2) -> void:
	if not _animations:
		return
	# Vertical dominates
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			_play_anim("Walk_Down")
		else:
			_play_anim("Walk_Up")
	else:
		# Horizontal — flip sprite for left
		_animations.flip_h = direction.x < 0
		_play_anim("Walk")

# ══════════════════════════════════════════════════════════════
#  PUBLIC COMMANDS
# ══════════════════════════════════════════════════════════════
func move(x: int, y: int) -> void:
	# ── Split diagonal into two cardinal steps ─────────────────
	# move(1,1) → right one tile THEN down one tile, no diagonal
	if x != 0 and y != 0:
		var after_h := _last_queued_pos() + Vector2(x, 0) * TILE_SIZE
		_move_queue.append(after_h)
		var after_v := after_h + Vector2(0, y) * TILE_SIZE
		_move_queue.append(after_v)
	else:
		_move_queue.append(_last_queued_pos() + Vector2(x, y) * TILE_SIZE)

	if not _is_moving:
		call_deferred("_process_next")

func move_to(x: int, y: int) -> void:
	if _tilemap:
		var cell   := Vector2i(x - 1, y - 1)
		var target := _tilemap.to_global(_tilemap.map_to_local(cell))
		_move_queue.append(target)
	else:
		_move_queue.append(Vector2(x - 1, y - 1) * TILE_SIZE)
	if not _is_moving:
		call_deferred("_process_next")

func step_forward() -> void:
	var v := _facing_vector()
	move(v.x, v.y)

func step_back() -> void:
	var v := _facing_vector()
	move(-v.x, -v.y)

func stop() -> void:
	_move_queue.clear()
	if is_instance_valid(_tween):
		_tween.kill()
	_is_moving  = false
	_processing = false
	_play_anim("Idle")

func turn_left() -> void:
	match _facing:
		Direction.RIGHT: _facing = Direction.UP
		Direction.UP:    _facing = Direction.LEFT
		Direction.LEFT:  _facing = Direction.DOWN
		Direction.DOWN:  _facing = Direction.RIGHT
	_sync_sprite_flip()

func turn_right() -> void:
	match _facing:
		Direction.RIGHT: _facing = Direction.DOWN
		Direction.DOWN:  _facing = Direction.LEFT
		Direction.LEFT:  _facing = Direction.UP
		Direction.UP:    _facing = Direction.RIGHT
	_sync_sprite_flip()

func rotate_deg(deg: float) -> void:
	var steps := int(round(deg / 90.0))
	for i in abs(steps):
		if steps > 0: turn_right()
		else:         turn_left()

func face(direction: String) -> void:
	match direction.to_lower():
		"right": _facing = Direction.RIGHT
		"left":  _facing = Direction.LEFT
		"up":    _facing = Direction.UP
		"down":  _facing = Direction.DOWN
	_sync_sprite_flip()

func move_right(steps: int = 1) -> void: move(steps,  0)
func move_left(steps: int  = 1) -> void: move(-steps, 0)
func move_up(steps: int    = 1) -> void: move(0, -steps)
func move_down(steps: int  = 1) -> void: move(0,  steps)

func is_moving() -> bool:   return _is_moving

func get_facing() -> String:
	match _facing:
		Direction.RIGHT: return "right"
		Direction.LEFT:  return "left"
		Direction.UP:    return "up"
		Direction.DOWN:  return "down"
	return "right"

func get_grid_position() -> Vector2:
	if _tilemap:
		var cell := _tilemap.local_to_map(_tilemap.to_local(_parent.global_position))
		return Vector2(cell.x + 1, cell.y + 1)
	return _parent.global_position / TILE_SIZE

func reset() -> void:
	stop()
	_parent.global_position = _start_position
	_facing = _start_facing
	_sync_sprite_flip()
	_play_anim("Idle") 

# ══════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════
func _last_queued_pos() -> Vector2:
	if _move_queue.is_empty():
		return _parent.global_position
	return _move_queue.back()

func _facing_vector() -> Vector2i:
	match _facing:
		Direction.RIGHT: return Vector2i(1,  0)
		Direction.LEFT:  return Vector2i(-1, 0)
		Direction.UP:    return Vector2i(0,  -1)
		Direction.DOWN:  return Vector2i(0,   1)
	return Vector2i(1, 0)

func _sync_sprite_flip() -> void:
	if not _animations: return
	_animations.flip_h = (_facing == Direction.LEFT)

func _play_anim(anim: String) -> void:
	if not _animations: return
	if not _animations.sprite_frames: return
	if not _animations.sprite_frames.has_animation(anim): return
	if _animations.animation != anim:
		_animations.play(anim)

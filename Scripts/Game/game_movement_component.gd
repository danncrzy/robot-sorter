extends Node

const TILE_SIZE:  float = 32.0
const MOVE_SPEED: float = 120.0

enum Direction { RIGHT, LEFT, UP, DOWN }

var _parent:         CharacterBody2D = null
var _animations:     AnimatedSprite2D = null
var _facing:         Direction = Direction.RIGHT
var _is_moving:      bool = false
var _move_queue:     Array[Vector2] = []
var _start_position: Vector2 = Vector2.ZERO
var _start_facing:   Direction = Direction.RIGHT
var _tween:          Tween = null

func _ready() -> void:
	if _parent != null:
		return
	_parent         = get_parent() as CharacterBody2D
	_animations     = _parent.get_node_or_null("GamePlayerAnimations")
	_start_position = _parent.global_position
	_start_facing   = _facing
	_process_next()

# ── Queue processing ───────────────────────────────────────────
func _process_next() -> void:
	print("PROCESS_NEXT | queue: ", _move_queue.size(), " | _is_moving: ", _is_moving, " | tween_valid: ", is_instance_valid(_tween), " | tween_running: ", _tween.is_running() if is_instance_valid(_tween) else false)
	print("PROCESS_NEXT | queue: ", _move_queue.size())
	if _move_queue.is_empty():
		_is_moving = false
		_play_anim("Idle")
		return

	_is_moving = true
	_play_anim("Walk")

	var target: Vector2 = _move_queue[0]
	var dist:   float   = _parent.global_position.distance_to(target)
	var dur:    float   = dist / MOVE_SPEED
	print("TWEEN | dist: ", dist, " | dur: ", dur, " | target: ", target)

	if is_instance_valid(_tween):
		_tween.kill()

	# ← get_tree().create_tween() not _parent.create_tween()
	_tween = _parent.create_tween()
	_tween.tween_property(_parent, "global_position", target, dur) \
		.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(func() -> void:
		print("TWEEN DONE")
		_move_queue.pop_front()
		_process_next()
	)
# ═══════════════════════════════════════════════════════════════
#  PUBLIC COMMANDS
# ═══════════════════════════════════════════════════════════════
func move(x: int, y: int) -> void:
	print("MOVE called: ", x, y, " | queue size: ", _move_queue.size(), " | _parent: ", _parent)
	var target := _last_queued_pos() + Vector2(x, y) * TILE_SIZE
	print("TARGET: ", target, " | current pos: ", _parent.global_position)
	_move_queue.append(target)
	if not _is_moving:
		_process_next()


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
	_is_moving = false
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

func move_to(x: int, y: int) -> void:
	_move_queue.append(Vector2(x, y) * TILE_SIZE)
	if not _is_moving:
		_process_next()

func is_moving() -> bool:      return _is_moving
func get_facing() -> String:
	match _facing:
		Direction.RIGHT: return "right"
		Direction.LEFT:  return "left"
		Direction.UP:    return "up"
		Direction.DOWN:  return "down"
	return "right"

func get_grid_position() -> Vector2:
	return _parent.global_position / TILE_SIZE

func reset() -> void:
	stop()
	_parent.global_position = _start_position
	_facing = _start_facing
	_sync_sprite_flip()

# ── Helpers ────────────────────────────────────────────────────
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

extends Node

var TILE_SIZE:  float = 16.0
var MOVE_SPEED: float = 120.0

const BASE_TILE_SIZE:  float = 16.0
const BASE_MOVE_SPEED: float = 120.0

enum Direction { RIGHT, LEFT, UP, DOWN }

var _parent:         CharacterBody2D  = null
var _animations:     AnimatedSprite2D = null
var _tilemap:        Node             = null
var _facing:         Direction        = Direction.RIGHT
var _is_moving:      bool             = false
var _move_queue:     Array            = []  
var _start_position: Vector2          = Vector2.ZERO
var _start_facing:   Direction        = Direction.RIGHT
var _processing:     bool             = false
var _current_target: Vector2          = Vector2.ZERO

var _celebrating:       bool  = false
var _celebration_timer: float = 0.0
const CELEBRATION_DURATION := 3.0

var _is_carrying:    bool   = false
var _carry_color:    String = ""



signal carry_state_changed(carrying: bool, color: String)

func _ready() -> void:
	_parent     = get_parent() as CharacterBody2D
	_animations = _parent.get_node_or_null("PlayerAnimations")
	_tilemap    = _parent.get_node_or_null("../../FactoryFloor")
	if not _tilemap:
		_tilemap = _parent.get_node_or_null("../FactoryFloor")

	# Captures the exact position you placed the player at in the editor
	_start_position = _parent.position
	
	var tracker = get_tree().get_first_node_in_group("objective_tracker")
	if tracker:
		tracker.mission_completed.connect(_on_mission_complete)

	var rand := randf()
	if rand < 0.05:   _play_anim("Idle_Angry")
	elif rand < 0.15: _play_anim("Idle_Tired")
	else:             _play_anim("Idle")

## ══════════════════════════════════════════════════════════════
##  QUEUE PROCESSOR  —  kicks off movement toward next target
## ══════════════════════════════════════════════════════════════
func _process_next() -> void:
	if _celebrating or _processing or _move_queue.is_empty():
		if _move_queue.is_empty():
			_is_moving  = false
			_processing = false
			AudioManager.stop_footsteps()
			_play_idle_anim()
			return
		return

	var next = _move_queue[0]

	# ── If it's an action (Callable), run it instantly and move on ──
	if next is Callable:
		_move_queue.pop_front()
		next.call()
		_process_next()  # immediately check if there's more
		return

	# ── Otherwise it's a Vector2 move target (existing logic) ──
	var target: Vector2 = next
	_processing = true
	_is_moving  = true
	_current_target = target

	var direction := (target - _parent.global_position).normalized()
	AudioManager.start_footsteps(
		preload("res://Assets/Sfx/walk.ogg"),
		0.85, 1.15, 0.30, 0.8
	)
	if not _celebrating:
		_play_directional_anim(direction)

## ══════════════════════════════════════════════════════════════
##  PHYSICS PROCESS  —  velocity toward target + move_and_slide
## ══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	# ── Celebration timer ────────────────────────────────────
	if _celebrating:
		_celebration_timer -= delta
		if _celebration_timer <= 0.0:
			_celebrating = false
			_play_anim("Idle")
		return

	if not _is_moving or not _processing: return
	if not is_instance_valid(_parent):    return

	var to_target := _current_target - _parent.global_position
	var dist      := to_target.length()

	# ── Arrived? ─────────────────────────────────────────────
	if dist <= MOVE_SPEED * delta + 0.5:
		_parent.global_position = _current_target
		_parent.velocity        = Vector2.ZERO
		_parent.move_and_slide()
		_move_queue.pop_front()

		var tracker := _parent.get_tree().get_first_node_in_group("objective_tracker")
		if tracker:
			var pos := _parent.global_position / TILE_SIZE
			tracker.call_deferred("notify_moved_to", pos)
			tracker.call_deferred("notify_step_taken")

		_processing = false

		if _move_queue.is_empty():
			_arrive()
		else:
			_process_next()
		return

	# ── Simulate directional input → set velocity ─────────────
	var dir := to_target.normalized()
	if abs(dir.x) >= abs(dir.y):
		dir = Vector2(sign(dir.x), 0.0)
	else:
		dir = Vector2(0.0, sign(dir.y))

	_parent.velocity = dir * MOVE_SPEED
	_parent.move_and_slide()

	# ── Wall hit? ────────────────────────────────────────────
	if _parent.get_slide_collision_count() > 0:
		var remaining := _current_target - _parent.global_position
		if remaining.dot(dir) <= 0.0:
			_move_queue.clear()
			_parent.velocity = Vector2.ZERO
			_arrive()


func _arrive() -> void:
	_is_moving  = false
	_processing = false
	_parent.velocity = Vector2.ZERO
	AudioManager.stop_footsteps()
	if not _celebrating:
		var rand := randf()
		if rand < 0.05:   _play_anim("Idle_Angry")
		elif rand < 0.15: _play_anim("Idle_Tired")
		else:             _play_anim("Idle")

## ══════════════════════════════════════════════════════════════
##  CELEBRATION
## ══════════════════════════════════════════════════════════════
func _on_mission_complete(_mission) -> void:
	stop()
	_celebrating       = true
	_celebration_timer = CELEBRATION_DURATION
	AudioManager.stop_footsteps()
	_play_anim("Celebration")

## ══════════════════════════════════════════════════════════════
##  ANIMATION
## ══════════════════════════════════════════════════════════════
func _play_directional_anim(direction: Vector2) -> void:
	if not _animations: return

	if _is_carrying and _carry_color != "":
		# Vertical carry
		if abs(direction.y) > abs(direction.x):
			if direction.y > 0:
				# Only Yellow and Green have Down variant
				if _carry_color in ["Yellow", "Green"]:
					_play_anim("Carry_%s_Down" % _carry_color)
				else:
					_play_anim("Carry_Up")  # universal fallback
			else:
				_play_anim("Carry_Up")
		else:
			# Horizontal — flip for left
			_animations.flip_h = direction.x < 0
			_play_anim("Carry_%s" % _carry_color)
		return

	# Normal walk animations
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0: _play_anim("Walk_Down")
		else:               _play_anim("Walk_Up")
	else:
		_animations.flip_h = direction.x < 0
		_play_anim("Walk")

func _play_idle_anim() -> void:
	if _is_carrying and _carry_color != "":
		_play_anim("Carry_%s" % _carry_color)
	else:
		var rand := randf()
		if rand < 0.05:   _play_anim("Idle_Angry")
		elif rand < 0.15: _play_anim("Idle_Tired")
		else:             _play_anim("Idle")

func _play_anim(anim: String) -> void:
	if not _animations: return
	if not _animations.sprite_frames: return
	if not _animations.sprite_frames.has_animation(anim):
		push_warning("Animation '%s' not found!" % anim)
		return
	if _animations.animation != anim:
		_animations.play(anim)

## ══════════════════════════════════════════════════════════════
##  PUBLIC COMMANDS
## ══════════════════════════════════════════════════════════════
func move(x: int, y: int) -> void:
	if _celebrating: return
	if x != 0 and y != 0:
		var after_h := _last_queued_pos() + Vector2(x, 0) * TILE_SIZE
		_move_queue.append(after_h)
		_move_queue.append(after_h + Vector2(0, y) * TILE_SIZE)
	else:
		_move_queue.append(_last_queued_pos() + Vector2(x, y) * TILE_SIZE)
	if not _is_moving:
		call_deferred("_process_next")

func move_to(x: int, y: int) -> void:
	if _celebrating: return
	if _tilemap and _tilemap.has_method("map_to_local"):
		var cell   := Vector2i(x - 1, y - 1)
		var target  = _tilemap.to_global(_tilemap.map_to_local(cell))
		_move_queue.append(target)
	else:
		_move_queue.append(Vector2(x - 1, y - 1) * TILE_SIZE)
	if not _is_moving:
		call_deferred("_process_next")

func step_forward() -> void:
	if _celebrating: return
	var v := _facing_vector(); move(v.x, v.y)

func step_back() -> void:
	if _celebrating: return
	var v := _facing_vector(); move(-v.x, -v.y)

func stop(play_idle: bool = true) -> void:
	_move_queue.clear()
	_parent.velocity = Vector2.ZERO
	_is_moving  = false
	_processing = false
	if play_idle and not _celebrating: _play_anim("Idle")

func turn_left() -> void:
	if _celebrating: return
	match _facing:
		Direction.RIGHT: _facing = Direction.UP
		Direction.UP:    _facing = Direction.LEFT
		Direction.LEFT:  _facing = Direction.DOWN
		Direction.DOWN:  _facing = Direction.RIGHT
	_sync_sprite_flip()

func turn_right() -> void:
	if _celebrating: return
	match _facing:
		Direction.RIGHT: _facing = Direction.DOWN
		Direction.DOWN:  _facing = Direction.LEFT
		Direction.LEFT:  _facing = Direction.UP
		Direction.UP:    _facing = Direction.RIGHT
	_sync_sprite_flip()

func rotate_deg(deg: float) -> void:
	if _celebrating: return
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
func move_left(steps:  int = 1) -> void: move(-steps, 0)
func move_up(steps:    int = 1) -> void: move(0, -steps)
func move_down(steps:  int = 1) -> void: move(0,  steps)

func is_moving() -> bool:
	if _celebrating: return false
	return _is_moving

func get_facing() -> String:
	match _facing:
		Direction.RIGHT: return "right"
		Direction.LEFT:  return "left"
		Direction.UP:    return "up"
		Direction.DOWN:  return "down"
	return "right"

func get_grid_position() -> Vector2:
	if _tilemap and _tilemap.has_method("local_to_map"):
		var cell = _tilemap.local_to_map(_tilemap.to_local(_parent.global_position))
		return Vector2(cell.x + 1, cell.y + 1)
	return _parent.global_position / TILE_SIZE

func reset() -> void:
	stop(false)
	_celebrating = false
	# Reset LOCAL position, not global
	_parent.position = _start_position
	_facing = _start_facing
	_sync_sprite_flip()
	_play_anim("Idle")

## ══════════════════════════════════════════════════════════════
##  HELPERS
## ══════════════════════════════════════════════════════════════
func _last_queued_pos() -> Vector2:
	if _move_queue.is_empty(): return _parent.global_position
	# Walk backwards to find the last queued movement position
	for i in range(_move_queue.size() - 1, -1, -1):
		if _move_queue[i] is Vector2:
			return _move_queue[i]
	# No movement in the queue, current position is the last known
	return _parent.global_position

func _facing_vector() -> Vector2i:
	match _facing:
		Direction.RIGHT: return Vector2i( 1,  0)
		Direction.LEFT:  return Vector2i(-1,  0)
		Direction.UP:    return Vector2i( 0, -1)
		Direction.DOWN:  return Vector2i( 0,  1)
	return Vector2i(1, 0)

func _sync_sprite_flip() -> void:
	if not _animations: return
	_animations.flip_h = (_facing == Direction.LEFT)

func _set_start(pos: Vector2) -> void:
	pass

	
	
func set_carrying(carrying: bool, color: String) -> void:
	_is_carrying  = carrying
	_carry_color  = color
	carry_state_changed.emit(carrying, color)
	# Update idle animation immediately
	if not _is_moving:
		_play_idle_anim()
		
func queue_action(action: Callable) -> void:
	_move_queue.append(action)
	if not _processing:
		_process_next()
		
func apply_world_scale(world_scale: float) -> void:
	TILE_SIZE  = BASE_TILE_SIZE  * world_scale
	MOVE_SPEED = BASE_MOVE_SPEED * world_scale

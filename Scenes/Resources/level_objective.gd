class_name LevelObjective
extends Resource

enum Type {
	MOVE_TO_POINT,      # walk to grid position
	GRAB_ITEM,          # pick up specific item
	DROP_ITEM,          # drop item at position
	RETURN_TO_RACK,     # put item in rack
	USE_COMMAND,        # use specific command e.g. "turn_left"
	REACH_STEP_COUNT,   # move exactly N steps
}

@export var type:          Type    = Type.MOVE_TO_POINT
@export var description:   String  = ""          # shown in UI
@export var hint:          String  = ""          # shown when stuck
@export var target_pos:    Vector2 = Vector2.ZERO # grid position
@export var target_count:  int     = 1           # for count-based objectives
@export var target_id:     String  = ""          # item name / rack id
@export var show_marker:   bool    = true        # show hint marker in world


var _current_count: int = 0
var _completed:     bool = false

func is_complete() -> bool:
	return _completed

func get_progress() -> String:
	match type:
		Type.RETURN_TO_RACK, Type.GRAB_ITEM:
			return "(%d/%d)" % [_current_count, target_count]
		_:
			return ""

func reset() -> void:
	_current_count = 0
	_completed     = false

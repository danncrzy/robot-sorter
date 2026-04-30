class_name LevelMission
extends Resource

@export var mission_title:   String                  = "Misi"
@export var objectives:      Array[LevelObjective]   = []
@export var level_id:        String                  = "level_1"

func get_current_objective() -> LevelObjective:
	for obj in objectives:
		if not obj.is_complete():
			return obj
	return null

func is_complete() -> bool:
	for obj in objectives:
		if not obj.is_complete():
			return false
	return true

func reset() -> void:
	for obj in objectives:
		obj.reset()

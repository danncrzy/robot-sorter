# save_manager.gd  (Autoload name: SaveManager)
extends Node

const SAVE_PATH := "user://save_data.json"

# { "level_01": 3, "level_02": 1, ... }
var _data: Dictionary = {}

func _ready() -> void:
	_load()

func save_stars(level_id: String, stars: int) -> void:
	# Only overwrite if new result is better.
	var prev: int = _data.get(level_id, 0)
	if stars > prev:
		_data[level_id] = stars
		_flush()

func get_stars(level_id: String) -> int:
	return _data.get(level_id, 0)

func _flush() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data))
		f.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var result = JSON.parse_string(f.get_as_text())
	f.close()
	if result is Dictionary:
		_data = result

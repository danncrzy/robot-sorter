# res://Scripts/Autoload/script_manager.gd
extends Node

signal script_registered(script_name: String)
signal script_content_updated(script_name: String, new_content: String)

# { "main.gd": { "content": "...", "path": "res://..." } }
var _scripts: Dictionary = {}

func register_script(script_name: String, content: String = "", path: String = "") -> void:
	if _scripts.has(script_name):
		return
	_scripts[script_name] = { "content": content, "path": path }
	script_registered.emit(script_name)

func get_content(script_name: String) -> String:
	return _scripts.get(script_name, {}).get("content", "")

func update_content(script_name: String, new_content: String) -> void:
	if not _scripts.has(script_name):
		return
	_scripts[script_name]["content"] = new_content
	script_content_updated.emit(script_name, new_content)

func get_script_names() -> PackedStringArray:
	return PackedStringArray(_scripts.keys())

func has_script(script_name: String) -> bool:
	return _scripts.has(script_name)

func clear() -> void:
	_scripts.clear()

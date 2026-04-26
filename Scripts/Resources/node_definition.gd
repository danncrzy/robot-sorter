# res://Scripts/Resources/node_definition.gd
class_name NodeDefinition
extends Resource

@export var structure: String = "Main"
@export var node_type: String = "Node2D" 
@export var script_state: String = "disabled" # "enabled" or "disabled"
@export var script_name: String = "" # e.g., "main.gd"

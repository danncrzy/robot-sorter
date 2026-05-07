extends TextureButton

@onready var resize_container: HBoxContainer = $ResizeContainer
@onready var increase_btn: TextureButton = $ResizeContainer/IncreaseBtn
@onready var decrease_btn: TextureButton = $ResizeContainer/DecreaseBtn

const MIN_SCALE := 0.4
const MAX_SCALE := 2.0
const STEP      := 0.2

var _tween: Tween = null
var _is_open: bool = false

func _ready() -> void:
	resize_container.modulate.a = 0.0
	resize_container.visible    = false
	resize_container.scale      = Vector2(0.8, 0.8)

	pressed.connect(_toggle_container)
	increase_btn.pressed.connect(_on_increase)
	decrease_btn.pressed.connect(_on_decrease)

func _toggle_container() -> void:
	_is_open = !_is_open

	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _is_open:
		resize_container.visible = true
		_tween.tween_property(resize_container, "modulate:a", 1.0, 0.2)
		_tween.parallel().tween_property(resize_container, "scale", Vector2.ONE, 0.2)
	else:
		_tween.tween_property(resize_container, "modulate:a", 0.0, 0.15)
		_tween.parallel().tween_property(resize_container, "scale", Vector2(0.8, 0.8), 0.15)
		_tween.tween_callback(func(): resize_container.visible = false)

func _get_game_nodes() -> Node:
	return get_tree().current_scene.get_node_or_null("GameNodes")

func _on_increase() -> void:
	var game_nodes := _get_game_nodes()
	if not game_nodes: return
	var current := snappedf(game_nodes.scale.x, 0.01)
	var next    := minf(snappedf(current + STEP, 0.01), MAX_SCALE)
	if current >= MAX_SCALE: return
	_animate_scale(game_nodes, next)

func _on_decrease() -> void:
	var game_nodes := _get_game_nodes()
	if not game_nodes: return
	var current := snappedf(game_nodes.scale.x, 0.01)
	var next    := maxf(snappedf(current - STEP, 0.01), MIN_SCALE)
	if current <= MIN_SCALE: return
	_animate_scale(game_nodes, next)

func _animate_scale(target: Node, new_scale: float) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(target, "scale", Vector2(new_scale, new_scale), 0.15)

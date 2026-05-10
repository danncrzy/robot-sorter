extends Control

@onready var star1          := $FinishBg/StarsContainer/Star
@onready var star2          := $FinishBg/StarsContainer/Star2
@onready var star3          := $FinishBg/StarsContainer/Star3
@onready var comments_label := $FinishBg/StatisticContainer/CommentsLabel as RichTextLabel
@onready var personal_best  := $FinishBg/StatisticContainer/PersonalBest  as RichTextLabel
@onready var next_btn       := $FinishBg/NextBtn
@onready var retry_btn      := $FinishBg/RetryBtn
@onready var home_btn       := $FinishBg/HomeBtn
@onready var finish_bg      := $FinishBg
@onready var finish_title   := $FinishBg/FinishTttle

@export var empty_star_texture:  Texture2D = null
@export var filled_star_texture: Texture2D = null
@export var star_sound:          AudioStream = null
@export var slide_sound:         AudioStream = null
@export var click_sound:         AudioStream = null

var _stars_earned:    int    = 0
var _is_showing:      bool   = false
var _next_scene_path: String = ""

## ══════════════════════════════════════════════════════════════
##  READY
## ══════════════════════════════════════════════════════════════
func _ready() -> void:
	visible = false
	modulate.a = 0.0
	_reset_stars()

	next_btn.pressed.connect(_on_next_btn)
	retry_btn.pressed.connect(_on_retry_btn)
	home_btn.pressed.connect(_on_home_btn)

	# Hover juice — scale up slightly on hover.
	for btn in [next_btn, retry_btn, home_btn]:
		var b := btn as TextureButton
		b.mouse_entered.connect(_btn_hover.bind(b))
		b.mouse_exited.connect(_btn_unhover.bind(b))

	# Connect to ObjectiveTracker signal.
	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if tracker and tracker.has_signal("level_completed"):
		tracker.level_completed.connect(_on_level_completed)

## ══════════════════════════════════════════════════════════════
##  SIGNAL RECEIVER
## ══════════════════════════════════════════════════════════════
func _on_level_completed(stars: int, comment: String, _moves: int, tries: int, next_scene: String = "") -> void:
	var is_new_best := tries <= 1
	_next_scene_path = next_scene
	var level_id := LevelManager.current_level.level_id if LevelManager.current_level else ""
	if level_id != "":
		SaveManager.save_stars(level_id, stars)
	show_results(stars, comment, is_new_best)

## ══════════════════════════════════════════════════════════════
##  PUBLIC ENTRY POINT
## ══════════════════════════════════════════════════════════════
func show_results(stars: int, comment: String, is_new_best: bool = false) -> void:
	if _is_showing: return
	_is_showing   = true
	_stars_earned = stars

	_reset_stars()
	visible       = true

	comments_label.bbcode_enabled = true
	comments_label.text = "[center]" + comment + "[/center]"
	personal_best.visible  = is_new_best
	personal_best.bbcode_enabled = true
	if is_new_best:
		personal_best.text = "[center]Rekor Pribadi Baru![/center]"

	# Start: fully transparent, slightly below center.
	modulate.a  = 0.0
	position.y += 60.0

	_play_sfx(slide_sound)

	# ── Phase 1: fade + slide in ────────────────────────────────
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - 60.0, 0.55)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# ── Phase 2: title pop ──────────────────────────────────────
	finish_title.scale = Vector2.ZERO
	tw.tween_property(finish_title, "scale", Vector2(1.15, 1.15), 0.3)\
		.set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(finish_title, "scale", Vector2(1.0, 1.0), 0.12)\
		.set_delay(0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ── Phase 3: stars (sequential, one tween, callbacks) ───────
	# Use a SINGLE chained tween so timing is guaranteed sequential.
	tw.set_parallel(false)
	tw.tween_interval(0.75)   # wait for slide-in to finish
	tw.tween_callback(_fire_star.bind(0))
	tw.tween_interval(0.38)
	tw.tween_callback(_fire_star.bind(1))
	tw.tween_interval(0.38)
	tw.tween_callback(_fire_star.bind(2))

## ══════════════════════════════════════════════════════════════
##  STAR SLAM  — called sequentially by the tween chain above
## ══════════════════════════════════════════════════════════════
func _fire_star(index: int) -> void:
	var stars := [star1, star2, star3]
	if index >= _stars_earned:
		# Not earned — small grey bounce to show the empty slot.
		var s := stars[index] as TextureRect
		var tw := create_tween()
		s.scale = Vector2.ZERO
		tw.tween_property(s, "scale", Vector2(0.85, 0.85), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2(1.0,  1.0),  0.08)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		return

	var s := stars[index] as TextureRect
	if filled_star_texture:
		s.texture = filled_star_texture

	_play_sfx(star_sound)

	# Angry-Birds slam: 0 → overshoot 1.5 → settle 1.0
	s.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2(1.5, 1.5), 0.14)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "scale", Vector2(0.9, 0.9), 0.07)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "scale", Vector2(1.0, 1.0), 0.06)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Glow pulse: star brightens briefly on slam.
	var color_tw := create_tween()
	color_tw.tween_property(s, "modulate", Color(1.6, 1.6, 0.6, 1.0), 0.08)
	color_tw.tween_property(s, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## ══════════════════════════════════════════════════════════════
##  BUTTON CALLBACKS
## ══════════════════════════════════════════════════════════════
func _on_next_btn() -> void:
	_play_sfx(click_sound)
	var next_index := LevelManager.current_level_index + 1
	if next_index < LevelManager.level_resources.size():
		LevelManager.current_level_index = next_index
		LevelManager.current_level       = LevelManager.level_resources[next_index]
		get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_retry_btn() -> void:
	_play_sfx(click_sound)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_home_btn() -> void:
	_play_sfx(click_sound)
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

## ══════════════════════════════════════════════════════════════
##  HELPERS
## ══════════════════════════════════════════════════════════════
func _reset_stars() -> void:
	for s in [star1, star2, star3]:
		(s as TextureRect).scale   = Vector2.ONE
		(s as TextureRect).modulate = Color.WHITE
		if empty_star_texture:
			(s as TextureRect).texture = empty_star_texture
	finish_title.scale = Vector2.ONE

func _play_sfx(stream: AudioStream) -> void:
	if not stream: return
	var p := AudioStreamPlayer.new()
	p.stream   = stream
	p.bus      = "UI"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func _btn_hover(btn: TextureButton) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _btn_unhover(btn: TextureButton) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

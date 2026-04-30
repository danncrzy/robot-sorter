# res://Scripts/Game/game_player.gd
extends CharacterBody2D

@onready var animasi : AnimatedSprite2D = $PlayerAnimations
# ═══════════════════════════════════════════════════════════════
#  Panduan Perintah
#  ─────────────────────────────────────────────────────────────
#  
#  Tulis kode kamu di dalam fungsi run(). Semua perintah siap digunakan:
#  
#  ! Lihat dokumentasi untuk detail perintah. !
#
#  PERGERAKAN:
#    move(x, y)        move_right()    move_left()
#    move_up()         move_down()     move_to(x, y)
#    step_forward()    step_back()     stop()
#
#  ARAH:
#    turn_left()       turn_right()
#    rotate_deg(90)    face("left")
#
#  QUERY:
#    is_moving()       get_facing()    get_position()
#
#  INTERAKSI:
#    grab()            drop()          interact()     is_holding()
#
#  Contoh:
#    func run():
#        move(3, 0)
#        grab()
#
# ═══════════════════════════════════════════════════════════════



var _start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	
	_start_position = global_position

func run() -> void:
	# Tulis kode buatan anda di sini ^^
	pass

func reset() -> void:
	_start_position = get_node("MovementComponent")._start_position
	get_node("MovementComponent").reset()
	get_node("InteractionComponent").reset()

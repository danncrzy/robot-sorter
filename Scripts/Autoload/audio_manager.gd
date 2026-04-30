# res://Scripts/Autoload/audio_manager.gd
extends Node

## ────────────────────── Bus Names ──────────────────────
const BUS_MASTER := "Master"
const BUS_SFX    := "SFX"
const BUS_MUSIC  := "Music"
const BUS_UI     := "UI"

## ────────────────────── Pools ──────────────────────
const SFX_POOL_SIZE := 8

var _sfx_pool:   Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer      = null
var _ui_player:    AudioStreamPlayer      = null

## ────────────────────── State ──────────────────────
var _music_volume: float = 1.0
var _sfx_volume:   float = 1.0
var _ui_volume:    float = 1.0


# ── Internal ───────────────────────────────────────────
const FOOTSTEP_POOL_SIZE := 2

var _footstep_pool:   Array[AudioStreamPlayer] = []
var _footstep_timer:  Timer                    = null
var _footstep_active: bool                     = false

var _footstep_stream:    AudioStream = null
var _footstep_pitch_min: float       = 0.9
var _footstep_pitch_max: float       = 1.1
var _footstep_volume:    float       = 1.0

@export var footstep_interval: float = 0.32


## ═══════════════════════════════════════════════════════
##  LIFECYCLE
## ═══════════════════════════════════════════════════════
func _ready() -> void:
	_ensure_buses()
	_create_music_player()
	_create_ui_player()
	_create_sfx_pool()
	_create_footstep_pool() 

func _ensure_buses() -> void:
	for bus in [BUS_SFX, BUS_MUSIC, BUS_UI]:
		if AudioServer.get_bus_index(bus) == -1:
			var idx := AudioServer.get_bus_count()
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, BUS_MASTER)

func _create_music_player() -> void:
	_music_player      = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus  = BUS_MUSIC
	add_child(_music_player)

func _create_ui_player() -> void:
	_ui_player      = AudioStreamPlayer.new()
	_ui_player.name = "UIPlayer"
	_ui_player.bus  = BUS_UI
	add_child(_ui_player)

func _create_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.bus  = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)


## ═══════════════════════════════════════════════════════
##  MUSIC  (with LOOPING!)
## ═══════════════════════════════════════════════════════
func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	
	if _music_player.playing:
		await _fade_out(_music_player, fade_in * 0.5)
	
	_music_player.stream        = stream

	_music_player.volume_db     = _safe_db(_music_volume)
	
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true

	
	_music_player.play()
	await _fade_in(_music_player, _music_volume, fade_in)

func stop_music(fade_out: float = 0.5) -> void:
	await _fade_out(_music_player, fade_out)
	_music_player.stop()

func set_music_volume(linear: float) -> void:
	_music_volume           = clampf(linear, 0.0, 1.0)
	_music_player.volume_db = _safe_db(_music_volume)  # 👈 FIXED
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_MUSIC),
		_safe_db(_music_volume)  # 👈 FIXED
	)


## ═══════════════════════════════════════════════════════
##  SFX
## ═══════════════════════════════════════════════════════
func play_sfx(stream: AudioStream, pitch: float = 1.0, volume: float = 1.0) -> void:
	var player := _get_free_sfx_player()
	if not player: return
	player.stream     = stream
	player.pitch_scale = pitch
	player.volume_db  = _safe_db(volume * _sfx_volume)  # 👈 Already safe
	player.play()

func play_sfx_random_pitch(stream: AudioStream,
		pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	play_sfx(stream, randf_range(pitch_min, pitch_max))

func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_SFX),
		_safe_db(_sfx_volume)  # 👈 Already safe
	)


## ═══════════════════════════════════════════════════════
##  UI SFX
## ═══════════════════════════════════════════════════════
func play_ui(stream: AudioStream, volume: float = 1.0) -> void:
	_ui_player.stream    = stream
	_ui_player.volume_db = _safe_db(volume * _ui_volume)  # 👈 Already safe
	_ui_player.play()

func set_ui_volume(linear: float) -> void:
	_ui_volume = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_UI),
		_safe_db(_ui_volume)  # 👈 Already safe
	)


## ═══════════════════════════════════════════════════════
##  FOOTSTEPS
## ═══════════════════════════════════════════════════════

func _create_footstep_pool() -> void:
	for i in FOOTSTEP_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "Footstep_%d" % i
		p.bus  = BUS_SFX
		add_child(p)
		_footstep_pool.append(p)

	_footstep_timer              = Timer.new()
	_footstep_timer.wait_time    = footstep_interval
	_footstep_timer.one_shot     = false
	_footstep_timer.timeout.connect(_on_footstep_tick)
	add_child(_footstep_timer)


func start_footsteps(stream: AudioStream,
		pitch_min: float = 0.9, pitch_max: float = 1.1,
		interval: float = 0.32, volume: float = 1.0) -> void:
	if _footstep_active: return
	_footstep_active             = true
	_footstep_timer.wait_time    = interval
	_footstep_stream      = stream
	_footstep_pitch_min   = pitch_min
	_footstep_pitch_max   = pitch_max
	_footstep_volume      = volume
	_play_footstep_once()
	_footstep_timer.start()


func stop_footsteps() -> void:
	if not _footstep_active: return
	_footstep_active = false
	_footstep_timer.stop()


func play_footstep_once(stream: AudioStream,
		pitch_min: float = 0.9, pitch_max: float = 1.1,
		volume: float = 1.0) -> void:
	_footstep_stream    = stream
	_footstep_pitch_min = pitch_min
	_footstep_pitch_max = pitch_max
	_footstep_volume    = volume
	_play_footstep_once()


func _on_footstep_tick() -> void:
	_play_footstep_once()


func _play_footstep_once() -> void:
	if not _footstep_stream: return
	var player := _get_free_footstep_player()
	if not player: return
	player.stream      = _footstep_stream
	player.pitch_scale = randf_range(_footstep_pitch_min, _footstep_pitch_max)
	player.volume_db   = _safe_db(_footstep_volume * _sfx_volume)  # 👈 Already safe
	player.play()


func _get_free_footstep_player() -> AudioStreamPlayer:
	for p in _footstep_pool:
		if not p.playing:
			return p
	return _footstep_pool[0]


## ═══════════════════════════════════════════════════════
##  MASTER
## ═══════════════════════════════════════════════════════
func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_MASTER),
		_safe_db(clampf(linear, 0.0, 1.0))  # 👈 Already safe
	)


func mute_all(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER), muted)


## ═══════════════════════════════════════════════════════
##  HELPERS
## ═══════════════════════════════════════════════════════
func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _fade_in(player: AudioStreamPlayer, target: float, dur: float) -> void:
	var t := create_tween()
	t.tween_property(player, "volume_db",
		_safe_db(target), dur).set_trans(Tween.TRANS_LINEAR)
	await t.finished


func _fade_out(player: AudioStreamPlayer, dur: float) -> void:
	var t := create_tween()
	t.tween_property(player, "volume_db",
		_safe_db(0.001), dur).set_trans(Tween.TRANS_LINEAR)
	await t.finished


## ═══════════════════════════════════════════════════════
##  SAFE DB  (THE FIX!)
## ═══════════════════════════════════════════════════════
func _safe_db(linear: float) -> float:
	# Catch ALL bad values: NaN, negative, zero, infinity
	if not is_finite(linear):
		print("⚠️ AudioManager: NaN/Inf volume detected, clamping to 0.001")
		return -60.0  # -60 dB = basically silent but valid
	
	if linear <= 0.0001:
		return -80.0  # Silent but valid dB value
	
	return linear_to_db(clampf(linear, 0.0001, 1.0))

# error_handler.gd  (Autoload name: ErrorHandler)
# ─────────────────────────────────────────────────────────────────────────────
#  Orchestrates all error detection passes and drives the UI.
#  All patterns, translations, and check logic live in GDScriptErrors autoload.
#  Register GDScriptErrors BEFORE this in Project > Project Settings > Autoload.
# ─────────────────────────────────────────────────────────────────────────────
extends Node

signal errors_found(errors: Array)
signal errors_cleared

var _text_editor:   TextEditorUI   = null
var _error_control: Control        = null
var _check_timer:   Timer          = null
var _lang:          ScriptLanguage = null   # cached once at startup

## ═══════════════════════════════════════════════════════════════
##  SETUP
## ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_check_timer           = Timer.new()
	_check_timer.wait_time = 0.8   # debounce: wait 0.8 s after last keystroke
	_check_timer.one_shot  = true
	_check_timer.timeout.connect(_run_check)
	add_child(_check_timer)

	_lang = _find_gdscript_language()
	if _lang:
		print("ErrorHandler: GDScriptLanguage found via get_class(). Pass 2 active.")
	else:
		push_warning("ErrorHandler: GDScriptLanguage not found. Pass 2 disabled.")

func init(text_editor: TextEditorUI, error_control: Control) -> void:
	_text_editor   = text_editor
	_error_control = error_control
	text_editor.script_content_changed.connect(_on_content_changed)

## ═══════════════════════════════════════════════════════════════
##  TRIGGER
## ═══════════════════════════════════════════════════════════════

func _on_content_changed(_script_name: String, _content: String) -> void:
	_check_timer.stop()
	_check_timer.start()

## ═══════════════════════════════════════════════════════════════
##  MAIN CHECK  —  three passes, results merged by line number
## ═══════════════════════════════════════════════════════════════

func _run_check() -> void:
	if not _text_editor: return
	var content := _text_editor.get_current_script_content()

	if content.strip_edges() == "":
		errors_cleared.emit()
		if _error_control: _error_control.hide_error()
		_unblock_play()
		return

	var errors: Array = []

	# ── PASS 0  Fuzzy keyword / typo check ───────────────────────────────────
	# Catches: funcs→func, vaer→var, @onreedy→@onready,
	#          vaid→void (return type), CharacterBoody2D→CharacterBody2D, etc.
	# Uses Levenshtein edit distance — catches ANY misspelling automatically.
	# All logic and data come from GDScriptErrors autoload.
	var typo_errors := GDScriptErrors.check_keywords(content)
	for e in typo_errors:
		errors.append({ "line": e.get("line", 1), "message": e.get("message", "") })

	# ── PASS 1  Structural parse ──────────────────────────────────────────────
	# Catches: unmatched quotes/brackets, missing colons, unclosed parens.
	# Always runs — pure string parsing, zero risk of crash.
	var structural := GDScriptErrors.parse_structural(content)
	for e in structural:
		var line: int = e.get("line", 1)
		if not _line_reported(errors, line):
			errors.append({ "line": line,
				"message": GDScriptErrors.translate(e.get("message", "")) })

	# ── PASS 2  GDScript engine validator ─────────────────────────────────────
	# Catches: unknown identifiers, type errors, bad calls — everything the
	# engine parser sees. validate() is parse-only and NEVER executes code.
	# Engine limitation: returns at most one critical error per run.
	# That is why Pass 0 + Pass 1 run first to catch the rest.
	if _lang:
		var result: Dictionary = _lang.validate(content, "user_script.gd", true, true)
		if not result.get("valid", false):
			for e in result.get("errors", []):
				var line: int = e.get("line", 1)
				if not _line_reported(errors, line):
					errors.append({ "line": line,
						"message": GDScriptErrors.translate(e.get("message", "")) })
		# Warnings get a ⚠ prefix — informational, not blocking
		for w in result.get("warnings", []):
			errors.append({ "line": w.get("line", 1),
				"message": "⚠ " + GDScriptErrors.translate(w.get("message", "")) })
	else:
		# Lang not found yet — retry (covers hot-reload / late init scenarios)
		_lang = _find_gdscript_language()

	# Sort all collected errors by line number
	errors.sort_custom(func(a, b): return a.get("line", 0) < b.get("line", 0))

	# ── Dispatch result ───────────────────────────────────────────────────────
	if errors.is_empty():
		errors_cleared.emit()
		if _error_control: _error_control.hide_error()
		_unblock_play()
	else:
		errors_found.emit(errors)
		if _error_control: _error_control.show_errors(errors)
		_block_play()

## ═══════════════════════════════════════════════════════════════
##  PLAY BUTTON CONTROL
## ═══════════════════════════════════════════════════════════════

func _block_play() -> void:
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc:
		gc.play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gc.play_btn.modulate.a   = 0.4

func _unblock_play() -> void:
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc and not gc._play_running:
		gc.play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		gc.play_btn.modulate.a   = 1.0

## ═══════════════════════════════════════════════════════════════
##  PRIVATE HELPERS
## ═══════════════════════════════════════════════════════════════

# Find GDScriptLanguage using two strategies:
#   1. get_class() == "GDScriptLanguage"  — works in most standard builds
#   2. has_method("validate")             — fallback for builds where class
#                                           name is slightly different
func _find_gdscript_language() -> ScriptLanguage:
	for i in Engine.get_script_language_count():
		var l := Engine.get_script_language(i)
		# Strategy 1: exact class name check
		if l.get_class() == "GDScriptLanguage":
			return l
	# Strategy 2: find whichever language exposes validate()
	for i in Engine.get_script_language_count():
		var l := Engine.get_script_language(i)
		if l.has_method("validate"):
			return l
	return null

# Returns true when errors already has an entry on the given line.
# Prevents duplicate messages from different passes for the same line.
func _line_reported(errors: Array, line: int) -> bool:
	for e in errors:
		if e.get("line") == line:
			return true
	return false

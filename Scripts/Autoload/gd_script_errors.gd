# gdscript_errors.gd  (Autoload name: GDScriptErrors)
# ─────────────────────────────────────────────────────────────────────────────
#  Single source of truth for ALL GDScript error detection and translation.
#  Uses Levenshtein fuzzy matching + dirty token detection for special chars.
#  error_handler.gd calls into this exclusively.
#
#  VERSION 7 — undeclared identifier detection (Pass-0.5):
#    check_undeclared(): flags single bare tokens (pasera / tessor / nugg etc.)
#    that are not declared anywhere in the file and not in any whitelist.
#    BUILTIN_NAMES whitelist added — covers all GDScript built-ins, node
#    methods, properties, singletons, and project game commands.
#    Helpers: _is_bare_statement, _extract_decl_name, _collect_global_names,
#             _extract_func_params, _is_declaration_line.
#  Plus all v6/v5/v4/v3 improvements.
# ─────────────────────────────────────────────────────────────────────────────
extends Node

## ═══════════════════════════════════════════════════════════════
##  CANDIDATE LISTS
## ═══════════════════════════════════════════════════════════════

const LINE_KEYWORDS: Array[String] = [
	"extends", "func", "var", "const", "class", "class_name",
	"signal", "enum", "static", "if", "elif", "else", "for",
	"while", "match", "break", "continue", "return", "pass",
	"await", "breakpoint",
]

const ANNOTATIONS: Array[String] = [
	"onready", "export", "tool", "static_unload",
	"export_group", "export_subgroup", "export_range", "export_enum",
	"export_flags", "export_node_path", "export_file", "export_dir",
	"export_color_no_alpha", "export_placeholder", "export_multiline",
	"export_exp_easing", "warning_ignore", "rpc",
]

const TYPE_NAMES: Array[String] = [
	"void", "int", "float", "bool", "String",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Rect2", "Rect2i", "Color", "Plane", "Quaternion",
	"AABB", "Basis", "Transform2D", "Transform3D",
	"Array", "Dictionary", "Object", "Node", "Node2D", "Node3D",
	"PackedScene", "Resource", "Callable", "StringName", "NodePath", "RID",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
	"Signal", "Variant",
]

const BUILTIN_TYPES: Array[String] = [
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Rect2", "Rect2i", "Color", "Plane", "Quaternion",
	"AABB", "Basis", "Transform2D", "Transform3D",
	"Array", "Dictionary", "Object", "Node", "Node2D", "Node3D",
	"PackedScene", "Resource", "Callable", "StringName", "NodePath", "RID",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
	"CharacterBody2D", "CharacterBody3D",
	"RigidBody2D", "RigidBody3D",
	"AnimatableBody2D", "AnimatableBody3D",
	"StaticBody2D", "StaticBody3D",
	"AnimatedSprite2D", "AnimatedSprite3D",
	"Sprite2D", "Sprite3D",
	"CollisionShape2D", "CollisionShape3D",
	"CollisionPolygon2D", "CollisionPolygon3D",
	"Area2D", "Area3D",
	"Camera2D", "Camera3D",
	"Label", "RichTextLabel", "Button", "TextureButton",
	"Control", "Panel", "PanelContainer",
	"HBoxContainer", "VBoxContainer", "GridContainer", "MarginContainer",
	"NinePatchRect", "TextureRect",
	"Timer", "Tween",
	"AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",
	"AnimationPlayer", "AnimationTree",
	"TileMap", "TileMapLayer",
	"NavigationAgent2D", "NavigationAgent3D",
	"RayCast2D", "RayCast3D",
	"Line2D", "Polygon2D",
	"CPUParticles2D", "GPUParticles2D",
	"Marker2D", "Marker3D",
	"RemoteTransform2D", "RemoteTransform3D",
	"Path2D", "PathFollow2D",
	"MeshInstance3D",
	"DirectionalLight3D", "SpotLight3D", "OmniLight3D",
	"WorldEnvironment", "Environment",
	"VisibleOnScreenNotifier2D", "VisibleOnScreenNotifier3D",
]

## ═══════════════════════════════════════════════════════════════
##  BUILT-IN NAME WHITELIST
##  All GDScript built-in functions, node methods, properties, and
##  special constants. Used by check_undeclared to avoid flagging
##  legitimate GDScript identifiers as "undeclared".
## ═══════════════════════════════════════════════════════════════

const BUILTIN_NAMES: Array[String] = [
	# Constants / literals
	"PI", "TAU", "INF", "NAN",
	"self", "super", "null", "true", "false", "owner",
	# Built-in global functions
	"print", "printerr", "printraw", "prints", "printt", "print_debug",
	"push_error", "push_warning",
	"len", "range", "abs", "sign", "min", "max", "clamp", "lerp",
	"smoothstep", "move_toward", "floor", "ceil", "round", "sqrt",
	"pow", "log", "exp", "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
	"deg_to_rad", "rad_to_deg", "fmod", "fposmod", "posmod", "snapped", "wrap",
	"is_nan", "is_inf", "is_equal_approx", "is_zero_approx",
	"randomize", "randi", "randf", "randi_range", "randf_range",
	"rand_from_seed", "seed",
	"str", "var_to_str", "str_to_var", "type_string", "typeof",
	"is_instance_valid", "is_instance_of", "weakref",
	"load", "preload", "assert",
	# Node methods
	"get_node", "has_node", "add_child", "remove_child", "queue_free", "free",
	"get_parent", "get_children", "get_child", "get_child_count",
	"find_child", "find_children", "find_parent",
	"get_path", "get_tree", "get_viewport", "get_window",
	"is_inside_tree", "is_node_ready",
	"set_process", "set_physics_process",
	"set", "get", "call", "callv", "has_method", "has_signal",
	"emit_signal", "connect", "disconnect", "is_connected",
	"notification", "to_local", "to_global",
	"create_tween", "duplicate", "replace_by",
	# Node2D properties / methods
	"position", "global_position", "rotation", "global_rotation",
	"rotation_degrees", "global_rotation_degrees",
	"scale", "global_scale", "transform", "global_transform",
	"z_index", "z_as_relative", "y_sort_enabled",
	"get_angle_to", "look_at", "translate", "global_translate",
	"rotate", "apply_scale",
	# Node common
	"name", "visible", "modulate", "self_modulate", "process_mode",
	# CharacterBody2D
	"velocity", "up_direction", "move_and_slide", "move_and_collide",
	"test_move", "is_on_floor", "is_on_ceiling", "is_on_wall",
	"is_on_floor_only", "is_on_ceiling_only", "is_on_wall_only",
	"get_floor_normal", "get_floor_angle", "get_wall_normal",
	"get_slide_collision_count", "get_slide_collision",
	"get_last_motion", "get_position_delta", "get_real_velocity",
	# AnimatedSprite2D / AnimationPlayer
	"animation", "frame", "speed_scale", "playing", "flip_h", "flip_v",
	"play", "pause", "stop", "is_playing",
	# Input singleton
	"Input",
	"is_action_pressed", "is_action_just_pressed",
	"is_action_just_released", "get_action_strength",
	"get_axis", "get_vector",
	# Timer
	"wait_time", "one_shot", "autostart", "timeout",
	"start", "get_time_left", "is_stopped",
	# Tween
	"tween_property", "tween_callback", "tween_interval",
	"tween_method", "set_loops", "set_parallel", "set_ease", "set_trans",
	# Godot singletons
	"Engine", "OS", "Time", "ProjectSettings", "ResourceLoader",
	"FileAccess", "DirAccess", "JSON", "Marshalls",
	# Common game commands (from the player command palette in this project)
	"move", "move_right", "move_left", "move_up", "move_down", "move_to",
	"step_forward", "step_back",
	"turn_left", "turn_right", "rotate_deg", "face",
	"is_moving", "get_facing",
	"grab", "drop", "interact", "is_holding",
	"reset",
]

## ═══════════════════════════════════════════════════════════════
##  DIRTY TOKEN DETECTION
##
##  A "dirty token" is a whitespace-separated chunk that contains BOTH
##  word characters (a-z A-Z 0-9 _) AND one or more characters that are
##  NEVER valid inside a GDScript identifier.
##
##  Examples:
##    ext/ends         → dirty → cleaned: "extends"
##    Cha!racterBody2D → dirty → cleaned: "CharacterBody2D"
##    f@unc            → dirty → cleaned: "func"   (@ is mid-word, so dirty)
##    vo@id            → dirty → cleaned: "void"
##    get_n&ode        → dirty → cleaned: "get_node"
##
##  NOT dirty (v3 fix):
##    @onready         → @ is at position-0 of chunk → valid annotation prefix
##    $PlayerAnimations→ $ is at position-0 of chunk → valid node-path prefix
## ═══════════════════════════════════════════════════════════════

# Characters that are NEVER valid INSIDE a GDScript identifier.
# IMPORTANT: @ and $ are in this list but are exempted when they appear
# at position 0 of a whitespace-separated chunk (see _find_dirty_tokens).
const DIRTY_CHARS: String = "!@#$%^&*?|~`/\\;"

var _all_types: Array = []

func _ready() -> void:
	_all_types = TYPE_NAMES.duplicate()
	for t in BUILTIN_TYPES:
		if not t in _all_types:
			_all_types.append(t)

## ═══════════════════════════════════════════════════════════════
##  PASS-0  KEYWORD / TYPO CHECK  (fuzzy + dirty token detection)
## ═══════════════════════════════════════════════════════════════

func check_keywords(content: String) -> Array:
	var errors: Array = []
	var lines         := content.split("\n")

	for i in lines.size():
		var raw      := lines[i]
		var stripped := raw.strip_edges()
		if stripped == "" or stripped.begins_with("#"): continue

		# Strip trailing inline comments (outside strings) before analysis.
		var code := _remove_comment(stripped)
		if code.strip_edges() == "": continue

		var clean  := _strip_strings(code)
		var tokens := _tokenize(clean)
		if tokens.is_empty(): continue

		var reported: Dictionary = {}

		# ── A) Annotation names  (@onreedy → @onready) ─────────────────────
		# stripped is used here (not code) so the full @annotation is visible.
		if stripped.begins_with("@"):
			var ann := stripped.substr(1).split("(")[0].split(" ")[0].strip_edges()
			if ann != "" and not ann in ANNOTATIONS:
				var s := _fuzzy_match(ann, ANNOTATIONS, _max_dist(ann))
				if s != "":
					reported[ann] = true
					errors.append({ "line": i + 1,
						"message": 'Anotasi "@%s" tidak dikenal → apakah maksudmu "@%s"?' \
							% [ann, s] })

		# ── B) Line-starting declaration keywords  (funcs→func, vaer→var) ──
		# Lines ending with ":" are always block-starters, never expressions.
		# Bypassing _looks_like_expression for them catches "funcs run():" etc.
		var first = tokens[0]
		var is_block_line := stripped.ends_with(":")
		if not reported.has(first) and (is_block_line or not _looks_like_expression(stripped)):
			if not first in LINE_KEYWORDS and not first.begins_with("_"):
				var s := _fuzzy_match(first, LINE_KEYWORDS, _max_dist(first))
				if s != "":
					reported[first] = true
					errors.append({ "line": i + 1,
						"message": 'Kemungkinan salah ketik kata kunci: "%s" → apakah maksudmu "%s"?' \
							% [first, s] })

		# ── C) Return type after ->  (vaid→void, Voctor2→Vector2) ──────────
		var arrow := clean.find("->")
		if arrow != -1:
			var after  := clean.substr(arrow + 2).strip_edges().trim_suffix(":").strip_edges()
			var rt_tok := _tokenize(after)
			if not rt_tok.is_empty():
				var rt = rt_tok[0]
				if not reported.has(rt) and not rt in _all_types:
					var s := _fuzzy_match(rt, _all_types, _max_dist(rt))
					if s != "":
						reported[rt] = true
						errors.append({ "line": i + 1,
							"message": 'Kemungkinan salah ketik tipe kembalian: "%s" → apakah maksudmu "%s"?' \
								% [rt, s] })

		# ── D) PascalCase tokens → builtin types ────────────────────────────
		for token in tokens:
			if reported.has(token): continue
			if not _is_pascal_case(token): continue
			if token in BUILTIN_TYPES: continue
			var s := _fuzzy_match(token, BUILTIN_TYPES, _max_dist_pascal(token))
			if s != "":
				reported[token] = true
				errors.append({ "line": i + 1,
					"message": 'Kemungkinan salah ketik tipe: "%s" → apakah maksudmu "%s"?' \
						% [token, s] })

		# ── E) DIRTY TOKENS — special chars embedded inside identifiers ─────
		# Catches: ext/ends, Cha!racterBody2D, f@unc, vo@id, Vec!tor2,
		#          get_n&ode, g#et_node, fu_nc (underscore is fine), etc.
		#
		# v3 FIX: @ at chunk[0] = annotation prefix (valid, NOT dirty).
		#          $ at chunk[0] = node-path prefix  (valid, NOT dirty).
		# So @onready and $PlayerAnimations are never flagged here.
		var dirty_results := _find_dirty_tokens(clean)
		for dt in dirty_results:
			var chunk_raw:   String = dt["raw"]
			var chunk_clean: String = dt["cleaned"]
			var bad_chars:   String = dt["bad_chars"]

			if reported.has(chunk_raw): continue

			var suggestion := ""

			# Keyword match
			var s := _fuzzy_match(chunk_clean, LINE_KEYWORDS, _max_dist(chunk_clean))
			if s != "": suggestion = s

			# Type match (PascalCase)
			if suggestion == "" and _is_pascal_case(chunk_clean):
				s = _fuzzy_match(chunk_clean, BUILTIN_TYPES, _max_dist_pascal(chunk_clean))
				if s != "": suggestion = s

			# Annotation match (if @ was the only bad char and it was mid-word)
			if suggestion == "" and "@" in bad_chars:
				s = _fuzzy_match(chunk_clean, ANNOTATIONS, _max_dist(chunk_clean))
				if s != "": suggestion = "@" + s

			# Exact match after cleaning — 100% confident, no need for fuzzy
			var is_exact := (chunk_clean in LINE_KEYWORDS) or \
							(chunk_clean in BUILTIN_TYPES) or \
							(chunk_clean in TYPE_NAMES)

			reported[chunk_raw] = true

			if is_exact:
				errors.append({ "line": i + 1,
					"message": 'Karakter "%s" tidak valid di dalam "%s" → hapus karakter tersebut.' \
						% [bad_chars, chunk_raw] })
			elif suggestion != "":
				errors.append({ "line": i + 1,
					"message": 'Karakter "%s" tidak valid di dalam "%s" → apakah maksudmu "%s"?' \
						% [bad_chars, chunk_raw, suggestion] })
			else:
				errors.append({ "line": i + 1,
					"message": 'Karakter tidak valid "%s" ditemukan di dalam kata "%s".' \
						% [bad_chars, chunk_raw] })

		# ── F) Mid-line # check (comment silently cuts off code) ────────────
		var hash_pos := _find_mid_line_hash(stripped)
		if hash_pos > 0:
			var before := stripped.substr(0, hash_pos).strip_edges()
			if before != "" and not reported.has("__hash__"):
				reported["__hash__"] = true
				errors.append({ "line": i + 1,
					"message": 'Tanda "#" di tengah baris memulai komentar — semua setelah "#" diabaikan oleh GDScript.' })

		# ── G0) Missing variable name after "var" / "const" ───────────────
		# Catches:  var     → lone keyword, nothing follows it
		# Safe:     var a   → name present
		# Token-based: if tokens == ["var"] or ["const"] (size 1), name is absent.
		if not reported.has("__var_noname__"):
			var _vkw = tokens[0]
			if (_vkw == "var" or _vkw == "const") and tokens.size() == 1:
				reported["__var_noname__"] = true
				errors.append({ "line": i + 1,
					"message": 'Nama variabel tidak ada setelah "%s" — tulis nama variabelnya (contoh: %s nama_variabel).' % [_vkw, _vkw] })

		# ── G) Missing type specifier after ":" in var/const declarations ───
		# Catches:  var x:          → "Expected type specifier after ':'"
		#           var x: = 5      → same (: followed by = with no type)
		# Safe:     var x: int = 5  → "int" is after the colon, no error.
		#           var x := 5      → ":=" walrus, the colon is part of :=, no error.
		if (stripped.begins_with("var ") or stripped.begins_with("const ")) \
		   and not reported.has("__type_colon__"):
			var tc := _find_type_colon(clean)
			if tc != -1:
				var after_colon := clean.substr(tc + 1).strip_edges()
				# Empty after colon, OR starts with "=" (no type between : and =)
				if after_colon == "" or after_colon.begins_with("="):
					reported["__type_colon__"] = true
					errors.append({ "line": i + 1,
						"message": 'Tipe data tidak ditulis setelah ":" — tulis tipe yang valid (misal: int, String, Vector2) setelah tanda titik dua.' })

		# ── H) Missing or invalid loop variable after "for" ─────────────────
		# Token-based check covers all sub-cases:
		#   "for"    → lone keyword,  tokens == ["for"]
		#   "for:"   → ":" is stripped by tokenizer, leaves ["for"]
		#   "for in" → variable missing before "in"
		var is_for_line = not tokens.is_empty() and tokens[0] == "for"
		if is_for_line and not reported.has("__for_var__"):
			if tokens.size() == 1:
				# "for" or "for:" — nothing meaningful after the keyword.
				reported["__for_var__"] = true
				errors.append({ "line": i + 1,
					"message": 'Pernyataan "for" tidak lengkap — format yang benar: for <variabel> in <iterable>:  (contoh: for i in range(5):).' })
			elif tokens[1] == "in":
				# "for in ..." — variable name missing before "in".
				reported["__for_var__"] = true
				errors.append({ "line": i + 1,
					"message": 'Nama variabel loop tidak ada setelah "for" — tulis nama variabel sebelum "in" (contoh: for i in range(5):).' })

		# ── I) range() called with zero arguments ────────────────────────────
		# Catches:  range()   → "Invalid call for range(). Expected at least 1 argument"
		# Skips substrings like "arrange()" by checking the char before "range(".
		if not reported.has("__range_empty__"):
			var ri := 0
			while true:
				var rp := clean.find("range(", ri)
				if rp < 0: break
				# Make sure "range" is not the tail of a longer word (e.g. "arrange")
				var preceded_by_word := rp > 0 and _is_word_char_code(clean[rp - 1].unicode_at(0))
				if not preceded_by_word:
					# Check that immediately after "range(" there is ")"
					var after_rp := clean.substr(rp + 6).strip_edges()
					if after_rp.begins_with(")"):
						reported["__range_empty__"] = true
						errors.append({ "line": i + 1,
							"message": 'Fungsi "range()" dipanggil tanpa argumen — berikan minimal 1 angka (contoh: range(5) atau range(1, 10)).' })
						break
				ri = rp + 1

	return errors


## ═══════════════════════════════════════════════════════════════
##  PASS-0.5  UNDECLARED IDENTIFIER CHECK  (Symbol-Table Edition)
##
##  How scope IDs work:
##    100  = global — declared outside any function; usable everywhere.
##    1    = func _ready   (first func found in the file)
##    2    = func run      (second func)
##    3    = func reset    (third func)
##    …and so on.
##
##  Every declared name is stored in a Dictionary:
##    symbol_table["_start_position"] = 100   ← global var
##    symbol_table["animasi"]         = 100   ← @onready var
##    symbol_table["_ready"]          = 100   ← func names are always global
##    symbol_table["run"]             = 100
##    symbol_table["local_x"]        = 2    ← var declared inside func run (id 2)
##
##  When checking a bare token inside func id N:
##    • Not in table at all           → ERROR: undeclared
##    • table[tok] == 100             → OK: global, usable everywhere
##    • table[tok] == N               → OK: declared in this very function
##    • table[tok] is some other id M → ERROR: wrong scope
##       (e.g. using a _ready-local var inside func run)
##
##  Only "bare statement" lines are checked — lines with no . ( = [ : + - * /
##  etc. — to avoid false positives on method calls and assignments.
## ═══════════════════════════════════════════════════════════════

## PASS-0.5 ENTRY POINT
func check_undeclared(content: String) -> Array:
	var errors: Array = []
	var lines         := content.split("\n")

	# ── Step 1: Build the symbol table ───────────────────────────────────
	var symbol_table: Dictionary = _build_symbol_table(lines)

	# ── Step 2: Scan lines with scope tracking ────────────────────────────
	# We need to know which function id we're inside while checking.
	# We replay the same counter logic as _build_symbol_table uses.
	var func_counter  := 0   # increments each time a "func" line is seen
	var func_id       := 0   # id of the currently-active function (0 = global)
	var func_indent   := -1  # indent depth of that func's declaration line

	for i in lines.size():
		var raw      := lines[i]
		var stripped := raw.strip_edges()
		if stripped == "" or stripped.begins_with("#"): continue

		var indent := _count_indent(raw)

		# ── Track function entry / exit ───────────────────────────────
		if stripped.begins_with("func "):
			func_counter += 1
			func_id     = func_counter
			func_indent = indent
		elif func_id > 0 and indent <= func_indent:
			func_id     = 0
			func_indent = -1

		# ── Skip declaration lines ────────────────────────────────────
		if _is_declaration_line(stripped): continue

		# ── Only check bare single-token statement lines ──────────────
		var code  := _remove_comment(stripped)
		var clean := _strip_strings(code)
		if not _is_bare_statement(clean): continue

		var tokens := _tokenize(clean)
		if tokens.size() != 1: continue

		var tok = tokens[0]

		# ── Built-in / keyword whitelist ──────────────────────────────
		if tok in LINE_KEYWORDS:  continue
		if tok in TYPE_NAMES:     continue
		if tok in BUILTIN_TYPES:  continue
		if tok in BUILTIN_NAMES:  continue
		if tok.is_valid_int() or tok.is_valid_float(): continue

		# ── Symbol-table lookup ───────────────────────────────────────
		if not symbol_table.has(tok):
			errors.append({ "line": i + 1,
				"message": '"%s" tidak dikenal — kata ini belum dideklarasikan di mana pun. Gunakan "var %s = ..." untuk mendeklarasikannya, atau hapus baris ini.' \
					% [tok, tok] })
		else:
			var tok_scope: int = symbol_table[tok]
			if tok_scope != 100 and tok_scope != func_id:
				# Declared, but in a different function — wrong scope.
				errors.append({ "line": i + 1,
					"message": '"%s" dideklarasikan di fungsi lain dan tidak bisa digunakan di sini. Deklarasikan ulang dengan "var %s = ..." di dalam fungsi ini, atau jadikan variabel global.' \
						% [tok, tok] })

	return errors

## ════════════════════════════════════════════════════════════════
##  SYMBOL TABLE BUILDER
##
##  Two-pass scan — first collect ALL declarations so forward references
##  (e.g. calling reset() before it is defined) are handled correctly.
##
##  Scope ID rules:
##    Global scope (outside any func) → 100
##    First  func found               → 1
##    Second func found               → 2
##    … and so on.
##
##  Stored:
##    • Global var / const / @onready var  → id 100
##    • Signal names                       → id 100
##    • Enum names                         → id 100
##    • Func names (all of them)           → id 100  (callable from anywhere)
##    • Func parameters                    → id N    (belong to func N)
##    • Local var / const inside func      → id N
## ════════════════════════════════════════════════════════════════

func _build_symbol_table(lines: Array) -> Dictionary:
	var table:        Dictionary = {}
	var func_counter  := 0
	var func_id       := 0   # 0 = global scope
	var func_indent   := -1

	for line in lines:
		var s      := (line as String).strip_edges()
		if s == "" or s.begins_with("#"): continue

		var indent := _count_indent(line as String)

		# ── Detect function exit ──────────────────────────────────────
		if func_id > 0 and indent <= func_indent and s != "":
			func_id     = 0
			func_indent = -1

		# ── Detect function entry ─────────────────────────────────────
		if s.begins_with("func "):
			func_counter += 1
			func_id      = func_counter
			func_indent  = indent
			# Func name itself is global (callable from anywhere)
			var fname := _extract_func_name(s)
			if fname != "":
				table[fname] = 100
			# Parameters belong to this function's scope
			for param in _extract_func_params(s):
				if param != "": table[param] = func_id
			continue

		# ── Global scope declarations ─────────────────────────────────
		if func_id == 0:
			var n := _extract_decl_name(s)
			if n != "": table[n] = 100; continue
			if s.begins_with("signal "):
				var sn := s.substr(7).split("(")[0].strip_edges()
				if sn != "": table[sn] = 100
			elif s.begins_with("enum "):
				var en := s.substr(5).split("{")[0].strip_edges()
				if en != "": table[en] = 100

		# ── Local scope declarations (inside a function) ──────────────
		else:
			if s.begins_with("var ") or s.begins_with("const "):
				var n := _extract_decl_name(s)
				if n != "": table[n] = func_id

	return table

## Extract the function name from a func declaration line.
## "func _ready() -> void:" → "_ready"
## "func move(x, y):"       → "move"
func _extract_func_name(stripped: String) -> String:
	if not stripped.begins_with("func "): return ""
	var after := stripped.substr(5).strip_edges()
	return after.split("(")[0].strip_edges()

## Returns true when a code-line (strings + comments already stripped) is a
## "bare statement" — a single word with no connective syntax.
## Lines with ANY of these chars are skipped (calls, assignments, chains, etc.)
func _is_bare_statement(clean: String) -> bool:
	for ch in [".", "(", "=", "[", ":", "+", "-", "*", "/", "%", "!", "<", ">", "&", "|", "~", ","]:
		if ch in clean: return false
	return true

## Extract declared name from a var / const / @onready var line.
## "var _start_position: Vector2 = Vector2.ZERO" → "_start_position"
## "@onready var animasi : AnimatedSprite2D = …" → "animasi"
func _extract_decl_name(stripped: String) -> String:
	var s := stripped
	if s.begins_with("@"):
		var vp := s.find("var ")
		if vp == -1: return ""
		s = s.substr(vp)
	if s.begins_with("var ") or s.begins_with("const "):
		var rest := s.substr(s.find(" ") + 1).strip_edges()
		var tok  := rest.split(":")[0].split("=")[0].strip_edges()
		return tok
	return ""

## Extract parameter names from a func declaration line.
## "func move(x: int, y: int) -> void:" → ["x", "y"]
func _extract_func_params(stripped: String) -> Array:
	var params: Array = []
	var po := stripped.find("(")
	var pc := stripped.find(")")
	if po == -1 or pc == -1 or pc <= po + 1: return params
	var inside := stripped.substr(po + 1, pc - po - 1)
	for part in inside.split(","):
		var pname := part.strip_edges().split(":")[0].strip_edges()
		if pname != "": params.append(pname)
	return params

## Returns true when a stripped line is a declaration (should not be inspected
## for undeclared identifiers — it IS the declaration).
func _is_declaration_line(stripped: String) -> bool:
	for prefix in ["var ", "const ", "func ", "@", "extends ",
				   "class_name ", "signal ", "enum ", "class ", "static func "]:
		if stripped.begins_with(prefix as String): return true
	return false

## ═══════════════════════════════════════════════════════════════
##  DIRTY TOKEN FINDER
## ═══════════════════════════════════════════════════════════════

## Scans a code line (strings already stripped) and returns all
## whitespace-separated chunks that contain both word chars AND dirty chars.
##
## v3 KEY FIX:
##   @ is exempt from "dirty" when it is chunk[0]  → @onready stays clean.
##   $ is exempt from "dirty" when it is chunk[0]  → $PlayerAnimations stays clean.
##
## Returns: Array of { raw, cleaned, bad_chars }
func _find_dirty_tokens(line: String) -> Array:
	var results: Array = []

	# Split on whitespace
	var chunks: Array = []
	var current := ""
	for i in line.length():
		var c := line[i].unicode_at(0)
		if c == 32 or c == 9:          # space / tab
			if current != "": chunks.append(current); current = ""
		else:
			current += line[i]
	if current != "": chunks.append(current)

	for chunk in chunks:
		if chunk.length() < 2: continue   # single char can't be a dirty identifier

		var has_word  := false
		var has_dirty := false
		var bad       := ""

		for ci in chunk.length():
			var ch = chunk[ci]
			var cc = ch.unicode_at(0)
			if _is_word_char_code(cc):
				has_word = true
			elif ch in DIRTY_CHARS:
				# v3 FIX: @ or $ at position 0 of the chunk are valid GDScript
				# prefixes (annotation / node path) — do NOT count as dirty.
				if ci == 0 and (ch == "@" or ch == "$"):
					pass   # valid leading prefix, skip
				else:
					has_dirty = true
					if ch not in bad:
						bad += ch

		if not (has_word and has_dirty): continue

		# Build the cleaned version: keep only word chars.
		# If the chunk started with @/$, strip that leading prefix too.
		var cleaned := ""
		for ci in chunk.length():
			if _is_word_char_code(chunk[ci].unicode_at(0)):
				cleaned += chunk[ci]

		if cleaned == "": continue

		results.append({ "raw": chunk, "cleaned": cleaned, "bad_chars": bad })

	return results

## ═══════════════════════════════════════════════════════════════
##  PASS-1  STRUCTURAL PARSE  (brackets, quotes, colons, indentation)
## ═══════════════════════════════════════════════════════════════

func parse_structural(content: String) -> Array:
	var errors: Array       = []
	var lines               := content.split("\n")
	var open_parens         := 0
	var open_brackets       := 0
	var in_multiline_string := false

	# ── J) Pre-scan: determine indentation style from first indented line ─
	# GDScript requires a single consistent style throughout the file.
	# We find the very first line that starts with whitespace and record
	# whether it uses a tab or a space, then flag every line that differs.
	var indent_style := ""   # "tab" | "space" | "" = not yet determined
	for raw_line in lines:
		if raw_line.length() == 0: continue
		if raw_line[0] == "\t":
			indent_style = "tab";   break
		elif raw_line[0] == " " and raw_line.strip_edges() != "":
			indent_style = "space"; break

	for i in lines.size():
		var line     := lines[i]
		var stripped := line.strip_edges()

		# ── J) Per-line indentation consistency ──────────────────────────
		# Two sub-checks, both run on every non-blank line:
		#
		# J-1) Wrong character at start — whole-line style mismatch.
		#      File uses tabs but line starts with space → error.
		#      File uses spaces but line starts with tab → error.
		#
		# J-2) Mixed characters inside the leading whitespace region.
		#      Scans every character left-to-right until the first
		#      non-whitespace (the "right side" that has the actual code).
		#      If ANY character in that region differs from indent_style,
		#      the left side is dirty → error.
		#
		#      Example (file uses tabs):
		#        [tab][space][space]var hello
		#         ↑ ok  ↑ DIRTY — space found in tab-indented region
		if indent_style != "" and stripped != "" and line.length() > 0:
			var fc := line[0]
			# J-1: first-character style check
			if indent_style == "tab" and fc == " ":
				errors.append({ "line": i + 1,
					"message": 'Indentasi baris ini menggunakan spasi, tapi file ini menggunakan tab — ganti spasi dengan tab (atau tekan Tab di editor).' })
			elif indent_style == "space" and fc == "\t":
				errors.append({ "line": i + 1,
					"message": 'Indentasi baris ini menggunakan tab, tapi file ini menggunakan spasi — ganti tab dengan spasi.' })
			else:
				# J-2: scan every leading-whitespace character for mixed chars.
				# Stop at the first non-whitespace (that is the safe "right side").
				var bad_mix := false
				for ci in line.length():
					var ch := line[ci]
					if ch != " " and ch != "\t":
						break   # reached code — right side is safe, stop
					if indent_style == "tab"   and ch == " ":
						bad_mix = true; break
					if indent_style == "space" and ch == "\t":
						bad_mix = true; break
				if bad_mix:
					var wrong := "spasi" if indent_style == "tab" else "tab"
					var right := "tab"   if indent_style == "tab" else "spasi"
					errors.append({ "line": i + 1,
						"message": 'Indentasi campuran di baris ini — ada %s di dalam area tab sebelum kode. Hapus semua %s di bagian kiri dan gunakan hanya %s.' \
							% [wrong, wrong, right] })

		var triple_count := line.count('"""')
		if triple_count % 2 != 0:
			in_multiline_string = !in_multiline_string
		if in_multiline_string: continue
		if stripped.begins_with("#"): continue

		# Unmatched double quotes
		var dq := 0; var j := 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\": j += 2; continue
			if ch == '"' : dq += 1
			j += 1
		if dq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched '\"'" })

		# Unmatched single quotes
		var sq := 0; j = 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\": j += 2; continue
			if ch == "'" : sq += 1
			j += 1
		if sq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched \"'\"" })

		# Parentheses balance
		open_parens += line.count("(") - line.count(")")
		if open_parens < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ')'" })
			open_parens = 0

		# Bracket balance
		open_brackets += line.count("[") - line.count("]")
		if open_brackets < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ']'" })
			open_brackets = 0

		# Missing colon after block-starters
		if stripped.begins_with("if ")    or stripped.begins_with("elif ") or \
		   stripped.begins_with("for ")   or stripped.begins_with("while ") or \
		   stripped.begins_with("func ")  or stripped == "else" or \
		   stripped.begins_with("match ") or stripped.begins_with("class "):
			if not stripped.ends_with(":") and not stripped.ends_with("\\") \
			   and not stripped.ends_with(","):
				errors.append({ "line": i + 1,
					"message": "'%s' block missing ':'" % stripped.split(" ")[0] })

		# ── L) Block with no indented body (func / for / if / while / else …) ─
		# Any block-starter ending in ":" whose next non-blank, non-comment
		# line is NOT indented deeper has an empty body → GDScript will crash.
		# Tab depth is the signal: each nested level adds one more leading \t.
		var BLOCK_STARTERS_L := ["for ", "func ", "if ", "elif ", "else", "while ", "match ", "class "]
		var _is_block_starter_L := false
		for _bs in BLOCK_STARTERS_L:
			if stripped.begins_with(_bs) or stripped == _bs.strip_edges():
				_is_block_starter_L = true; break
		if _is_block_starter_L and stripped.ends_with(":"):
			var ni := i + 1
			while ni < lines.size():
				var ns := lines[ni].strip_edges()
				if ns != "" and not ns.begins_with("#"):
					break
				ni += 1
			var block_indent := _count_indent(lines[i])
			var block_word   := stripped.split(" ")[0].trim_suffix(":")
			if ni >= lines.size() or _count_indent(lines[ni]) <= block_indent:
				errors.append({ "line": i + 1,
					"message": 'Blok "%s" tidak memiliki isi — tambahkan setidaknya satu perintah di dalamnya, atau tulis "pass" jika belum ada kode.' % block_word })

	if open_parens > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '('" })
	if open_brackets > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '['" })

	return errors

## ═══════════════════════════════════════════════════════════════
##  TRANSLATION  (engine English messages → Bahasa Indonesia)
## ═══════════════════════════════════════════════════════════════

const PATTERNS: Array = [
	# Scope / identifier
	{ "p": "not declared in the current scope",
	  "t": 'Variabel atau fungsi "{ID}" tidak ditemukan di scope ini.' },
	{ "p": "already declared in this scope",
	  "t": 'Nama "{ID}" sudah dipakai di scope yang sama.' },
	{ "p": "shadows a variable",
	  "t": 'Variabel "{ID}" menyembunyikan variabel lain di scope luar.' },
	# Function / method
	{ "p": "nonexistent function",
	  "t": 'Fungsi "{ID}" tidak ada.' },
	{ "p": "function not found in base",
	  "t": 'Fungsi "{ID}" tidak ada di tipe ini.' },
	{ "p": "method not found",
	  "t": 'Metode "{ID}" tidak ditemukan pada tipe ini.' },
	{ "p": "too many arguments",
	  "t": "Terlalu banyak argumen yang diberikan ke fungsi ini." },
	{ "p": "too few arguments",
	  "t": "Argumen yang diberikan kurang dari yang dibutuhkan." },
	{ "p": "expected a return value",
	  "t": "Fungsi ini harus mengembalikan nilai." },
	{ "p": "return type mismatch",
	  "t": "Tipe nilai yang dikembalikan tidak sesuai dengan deklarasi fungsi." },
	{ "p": "cannot return a value",
	  "t": "Fungsi bertipe void tidak boleh mengembalikan nilai." },
	{ "p": "callable is not a method",
	  "t": "Nilai ini bukan sebuah fungsi yang bisa dipanggil." },
	# Type
	{ "p": "cannot assign a value of type",
	  "t": "Tipe data tidak cocok saat menetapkan nilai." },
	{ "p": "cannot convert",
	  "t": "Tidak bisa mengkonversi tipe data ini ke tipe yang diharapkan." },
	{ "p": "invalid assignment",    "t": "Penugasan nilai tidak valid." },
	{ "p": "read-only",
	  "t": "Variabel ini bersifat read-only, tidak bisa diubah nilainya." },
	{ "p": "invalid operand",       "t": "Operand tidak valid untuk operasi ini." },
	{ "p": "invalid operator",      "t": "Operator tidak valid di sini." },
	{ "p": "incompatible",
	  "t": "Tipe data tidak kompatibel untuk operasi ini." },
	{ "p": "is not an object",
	  "t": "Nilai ini bukan objek, tidak bisa mengakses properti atau metode." },
	{ "p": "type mismatch",         "t": "Tipe data tidak sesuai di sini." },
	# Syntax / parse
	{ "p": "expected end of statement",
	  "t": "Pernyataan tidak lengkap atau ada karakter yang tidak terduga." },
	{ "p": "expected newline",
	  "t": "Diharapkan baris baru setelah pernyataan ini." },
	{ "p": "unexpected token",
	  "t": "Token atau simbol yang tidak terduga di sini." },
	{ "p": "unexpected character",  "t": "Karakter yang tidak dikenal di sini." },
	{ "p": "expected indented block after function",
	  "t": 'Fungsi ini tidak memiliki isi — tambahkan setidaknya satu perintah, atau tulis "pass".' },
	{ "p": "expected indented block",
	  "t": "Blok kode setelah pernyataan ini harus di-indent — tambahkan isi blok, atau tulis 'pass'." },
	{ "p": "unindent does not match",
	  "t": "Indentasi tidak konsisten — periksa jumlah spasi atau tab." },
	{ "p": "unexpected indent",
	  "t": "Indentasi tidak terduga di baris ini." },
	{ "p": "used space character for indentation",
	  "t": "Baris ini menggunakan spasi untuk indentasi, tapi file ini menggunakan tab — ganti spasi dengan tab." },
	{ "p": "used tab character for indentation",
	  "t": "Baris ini menggunakan tab untuk indentasi, tapi file ini menggunakan spasi — ganti tab dengan spasi." },
	{ "p": "expected ':'",          "t": "Tanda titik dua ':' hilang di akhir baris ini." },
	{ "p": "missing ':'",           "t": "Tanda titik dua ':' hilang di akhir baris ini." },
	{ "p": "expected '('",          "t": "Tanda kurung buka '(' tidak ada." },
	{ "p": "expected ')'",          "t": "Tanda kurung tutup ')' tidak ada." },
	{ "p": "expected '['",          "t": "Tanda kurung siku buka '[' tidak ada." },
	{ "p": "expected ']'",          "t": "Tanda kurung siku tutup ']' tidak ada." },
	{ "p": "expected expression",   "t": "Ekspresi tidak lengkap atau kosong di sini." },
	{ "p": "expected identifier",
	  "t": "Diharapkan nama variabel atau fungsi yang valid di sini." },
	{ "p": "unexpected end of file",
	  "t": "File berakhir terlalu cepat — mungkin ada blok yang belum ditutup." },
	{ "p": "unmatched",             "t": "Tanda kutip atau kurung tidak berpasangan." },
	{ "p": "unclosed '('",          "t": "Tanda kurung '(' tidak ditutup." },
	{ "p": "unclosed '['",          "t": "Tanda kurung siku '[' tidak ditutup." },
	{ "p": "unexpected ')'",        "t": "Tanda ')' muncul tanpa ada '(' sebelumnya." },
	{ "p": "unexpected ']'",        "t": "Tanda ']' muncul tanpa ada '[' sebelumnya." },
	# Control flow
	{ "p": "return outside function",
	  "t": "Pernyataan 'return' digunakan di luar fungsi." },
	{ "p": "break outside loop",
	  "t": "Pernyataan 'break' digunakan di luar loop." },
	{ "p": "continue outside loop",
	  "t": "Pernyataan 'continue' digunakan di luar loop." },
	{ "p": "await not in async",
	  "t": "'await' hanya bisa dipakai di dalam fungsi async." },
	# Property / member
	{ "p": "property not found",
	  "t": 'Properti "{ID}" tidak ada di objek ini.' },
	{ "p": "member not found",
	  "t": 'Anggota "{ID}" tidak ditemukan di tipe ini.' },
	{ "p": "cannot access member",
	  "t": "Tidak bisa mengakses anggota dari objek yang mungkin null." },
	{ "p": "is not a valid member of",
	  "t": 'Nama "{ID}" bukan anggota yang valid dari tipe ini.' },
	# Signal
	{ "p": "signal not declared",
	  "t": 'Sinyal "{ID}" tidak dideklarasikan.' },
	{ "p": "signal already exists",
	  "t": 'Sinyal "{ID}" sudah dideklarasikan sebelumnya.' },
	# Class / extends
	{ "p": "class not found",       "t": 'Kelas "{ID}" tidak ditemukan.' },
	{ "p": "invalid extends",
	  "t": "Kelas induk yang dipakai di 'extends' tidak valid." },
	{ "p": "cannot extend",         "t": "Kelas ini tidak bisa di-extends." },
	{ "p": "cyclic inheritance",
	  "t": "Ditemukan siklus pewarisan — kelas tidak boleh mewarisi dirinya sendiri." },
	# Annotation
	{ "p": "invalid annotation",
	  "t": "Anotasi ini tidak valid atau dipakai di tempat yang salah." },
	{ "p": "unknown annotation",    "t": "Anotasi ini tidak dikenal." },
	# Variable / constant
	{ "p": "constant value must be a literal",
	  "t": "Nilai 'const' harus berupa nilai tetap (literal), bukan variabel." },
	{ "p": "cannot assign to constant",
	  "t": "Konstanta tidak bisa diubah nilainya setelah dideklarasikan." },
	{ "p": "variable is not assigned",
	  "t": 'Variabel "{ID}" dipakai sebelum diberi nilai.' },
	# Structural (from parse_structural)
	{ "p": "block missing ':'",
	  "t": "Blok kode membutuhkan tanda titik dua ':' di akhir baris ini." },
	# Pass-0 G/H/I syntax checks (also used as fallback for engine messages)
	{ "p": "expected type specifier after",
	  "t": 'Tipe data tidak ditulis setelah ":" — tulis tipe yang valid (misal: int, String, Vector2).' },
	{ "p": "expected loop variable",
	  "t": 'Nama variabel loop tidak ada setelah "for" — tulis nama variabel sebelum "in" (contoh: for i in range(5):).' },
	{ "p": "expected at least 1 argument",
	  "t": 'Fungsi "range()" dipanggil tanpa argumen — berikan minimal 1 angka (contoh: range(5) atau range(1, 10)).' },
	# Warnings
	{ "p": "unused variable",
	  "t": 'Variabel "{ID}" dideklarasikan tapi tidak pernah digunakan.' },
	{ "p": "unused parameter",
	  "t": 'Parameter "{ID}" tidak pernah digunakan di dalam fungsi.' },
	{ "p": "return value discarded", "t": "Nilai kembalian fungsi ini diabaikan." },
	{ "p": "narrowing conversion",
	  "t": "Konversi tipe mempersempit nilai (misalnya float ke int)." },
	{ "p": "integer division",
	  "t": "Pembagian antar integer menghasilkan integer, bukan float." },
]

func translate(msg: String) -> String:
	if msg == "": return ""
	var ml := msg.to_lower()
	for entry in PATTERNS:
		if (entry["p"] as String).to_lower() in ml:
			var t: String = entry["t"]
			if "{ID}" in t:
				t = t.replace("{ID}", _extract_quoted(msg))
			return t
	return "Kesalahan: " + msg

## ═══════════════════════════════════════════════════════════════
##  LEVENSHTEIN FUZZY MATCHING
## ═══════════════════════════════════════════════════════════════

func _levenshtein(a: String, b: String) -> int:
	var la := a.length(); var lb := b.length()
	if la == 0: return lb
	if lb == 0: return la
	if la > 40 or lb > 40: return 99

	var prev := PackedInt32Array(); var curr := PackedInt32Array()
	prev.resize(lb + 1);             curr.resize(lb + 1)
	for j in (lb + 1): prev[j] = j

	for i in range(1, la + 1):
		curr[0] = i
		for j in range(1, lb + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr[j] = mini(mini(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
		var tmp := prev; prev = curr; curr = tmp

	return prev[lb]

func _fuzzy_match(token: String, candidates: Array, max_dist: int) -> String:
	if token in candidates: return ""
	var best_dist := max_dist + 1; var best := ""; var tl := token.to_lower()
	for c in candidates:
		var d := _levenshtein(tl, (c as String).to_lower())
		if d < best_dist: best_dist = d; best = c
	return best if best_dist <= max_dist else ""

func _max_dist(token: String) -> int:
	var l := token.length()
	if l <= 3: return 1
	if l <= 6: return 2
	return 2

func _max_dist_pascal(token: String) -> int:
	return 1 if token.length() <= 5 else 2

## ═══════════════════════════════════════════════════════════════
##  PRIVATE HELPERS
## ═══════════════════════════════════════════════════════════════

## Count the number of leading whitespace characters in a line.
## Used by check L to compare indentation depth between two lines.
func _count_indent(line: String) -> int:
	var count := 0
	for ch in line:
		if ch == "\t" or ch == " ":
			count += 1
		else:
			break
	return count

## Remove everything from the first unquoted # onward (inline comment strip).
func _remove_comment(line: String) -> String:
	var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == "#": return line.substr(0, i)
			if ch == '"' or ch == "'": in_str = true; str_ch = ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
		i += 1
	return line

## Find position of first # that is NOT inside a string and NOT at pos 0.
## Returns -1 if none found.
func _find_mid_line_hash(line: String) -> int:
	var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == "#" and i > 0: return i
			if ch == '"' or ch == "'": in_str = true; str_ch = ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
		i += 1
	return -1

## Returns true when a line looks like an expression/assignment, not a declaration.
func _looks_like_expression(stripped: String) -> bool:
	if stripped.contains("=") and not stripped.contains("->"):
		return true
	if stripped.begins_with("_"):
		return true
	if stripped.contains("("):
		var tok := _tokenize(_strip_strings(stripped))
		if not tok.is_empty():
			if not tok[0] in ["func", "if", "elif", "while", "for", "match", "class"]:
				return true
	return false

## Find the position of the first ":" in a line that is NOT part of ":=".
## Used by check G to detect missing type specifiers in var/const lines.
## Returns -1 if no such colon exists.
func _find_type_colon(line: String) -> int:
	for k in line.length():
		if line[k] == ":":
			# Skip ":=" — that is the walrus / infer operator, not a type colon.
			if k + 1 < line.length() and line[k + 1] == "=":
				continue
			return k
	return -1

## Replace string contents with spaces (prevents false matches inside strings).
func _strip_strings(line: String) -> String:
	var result := ""; var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == '"' or ch == "'": in_str = true; str_ch = ch; result += " "
			else: result += ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
			result += " "
		i += 1
	return result

## Split into pure word-char tokens (a-z A-Z 0-9 _).
func _tokenize(line: String) -> Array:
	var tokens: Array = []; var current := ""
	for i in line.length():
		var c := line[i].unicode_at(0)
		if _is_word_char_code(c): current += line[i]
		else:
			if current != "": tokens.append(current); current = ""
	if current != "": tokens.append(current)
	return tokens

func _is_word_char_code(c: int) -> bool:
	return (c >= 97 and c <= 122) or (c >= 65 and c <= 90) \
		   or (c >= 48 and c <= 57) or c == 95

func _is_pascal_case(s: String) -> bool:
	if s.length() < 2: return false
	var c := s[0].unicode_at(0)
	return c >= 65 and c <= 90

func _extract_quoted(msg: String) -> String:
	var dq_o := msg.find('"');  var dq_c := msg.find('"', dq_o + 1)
	if dq_o != -1 and dq_c != -1: return msg.substr(dq_o + 1, dq_c - dq_o - 1)
	var sq_o := msg.find("'");  var sq_c := msg.find("'", sq_o + 1)
	if sq_o != -1 and sq_c != -1: return msg.substr(sq_o + 1, sq_c - sq_o - 1)
	return msg

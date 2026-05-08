# res://Scripts/UI/tutorial_ui.gd
extends Control

@onready var rich_text:        RichTextLabel  = $ScrollContainer/RichTextLabel
@onready var close_btn:        TextureButton  = $CloseBtn
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var v_scroll_bar:     VScrollBar      = $VScrollBar



const TUTORIAL_TEXT := """
[b][color=#0d0e26]Mekanik Kotak dan Rak[/color][/b]

Level ini memperkenalkan objek baru: [b]Kotak[/b] dan [b]Rak[/b].
Tugasmu adalah mengambil kotak dan menatanya di rak yang tersedia.

[color=#00B4D8]grab[/color][color=#90A4AE]()[/color]  → ambil kotak (SOR-BOT harus berada tepat di atas kotak)
[color=#00B4D8]drop[/color][color=#90A4AE]()[/color]  → letakkan kotak (SOR-BOT harus berada di dekat Rak)

[b]Contoh:[/b]

[color=#903240]func[/color] [color=#55c8cc]run[/color][color=#90A4AE]():[/color]
    [color=#00B4D8]move_right[/color][color=#90A4AE]([/color][color=#49dcab]2[/color][color=#90A4AE])[/color]
    [color=#00B4D8]grab[/color][color=#90A4AE]()[/color]
    [color=#00B4D8]move_left[/color][color=#90A4AE]([/color][color=#49dcab]4[/color][color=#90A4AE])[/color]
    [color=#00B4D8]drop[/color][color=#90A4AE]()[/color]

"""



func _ready() -> void:
	rich_text.bbcode_enabled = true
	rich_text.fit_content    = true
	rich_text.scroll_active  = false
	rich_text.text           = TUTORIAL_TEXT

	close_btn.pressed.connect(func() -> void:
		visible = false
	)

	# Hide built-in scrollbar
	var built_in := scroll_container.get_v_scroll_bar()
	built_in.modulate.a          = 0
	built_in.custom_minimum_size = Vector2(0, 0)

	# Custom bar → ScrollContainer
	v_scroll_bar.value_changed.connect(func(val: float) -> void:
		scroll_container.scroll_vertical = int(val)
	)

	# ScrollContainer → custom bar
	built_in.changed.connect(func() -> void:
		v_scroll_bar.max_value = built_in.max_value
		v_scroll_bar.page      = built_in.page
		v_scroll_bar.set_value_no_signal(built_in.value)
	)

	# Initial sync after layout
	await get_tree().process_frame
	await get_tree().process_frame
	var bi := scroll_container.get_v_scroll_bar()
	v_scroll_bar.max_value = bi.max_value
	v_scroll_bar.page      = bi.page

# res://Scripts/UI/tutorial_ui.gd
extends Control

@onready var rich_text:        RichTextLabel  = $ScrollContainer/RichTextLabel
@onready var close_btn:        TextureButton  = $CloseBtn
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var v_scroll_bar:     VScrollBar      = $VScrollBar



const TUTORIAL_TEXT := """
[color=#0d0e26][b]TUTORIAL[/b][/color]

[color=#6d2a39][b]PERHATIAN[/b][/color]
[color=#6d2a39]Penulisan kode yang salah dan tidak sesuai dengan GDScript dapat memicu crash game.[/color]
[color=#4ec539]Selalu periksa kode sebelum menekan Play.[/color]

──────────────────────────────

[b][color=#0d0e26]Selamat datang, Programmer.[/color][/b]

Ini adalah level pertamamu. Tugasmu sederhana:
[b]Selesaikan misi dengan memerintahkan SOR-BOT.[/b]

──────────────────────────────

[b][color=#0d0e26]LANGKAH 1 — Buka Script[/color][/b]

Lihat panel [b]Scene Tree[/b] di sebelah kiri.
Ketuk node [color=#00B4D8][b]Player[/b][/color], lalu ketuk ikon [b]Script[/b].
File [color=#00B4D8]game_player.gd[/color] akan terbuka di editor.

──────────────────────────────

[b][color=#0d0e26]LANGKAH 2 — Tulis func run()[/color][/b]

Tulis function ini di dalam editor:

[color=#00B4D8][b]func[/b][/color] [color=#06D6A0]run[/color][color=#E8F4F8]() -> [/color][color=#00B4D8]void[/color][color=#E8F4F8]:[/color]
[color=#6d2a39]     pass[/color]  [color=#90A4AE] # Tulis kode kamu di sini[/color]

Semua perintahmu ditulis [b]di dalam fungsi ini[/b], menggantikan baris [color=#90A4AE]pass[/color].

──────────────────────────────

[b][color=#0d0e26]LANGKAH 3 — Tulis Perintah[/color][/b]

Lihat grid di layar. Titik tujuan ditandai dengan
[color=#4ec539][b]kotak hijau bercahaya[/b][/color] beserta koordinatnya.

[color=#00B4D8]move_right([/color][color=#e7f2f7]langkah[/color][color=#00B4D8])[/color]  → gerak ke kanan
[color=#00B4D8]move_left([/color][color=#e7f2f7]langkah[/color][color=#00B4D8])[/color]   → gerak ke kiri
[color=#00B4D8]move_up([/color][color=#e7f2f7]langkah[/color][color=#00B4D8])[/color]     → gerak ke atas
[color=#00B4D8]move_down([/color][color=#e7f2f7]langkah[/color][color=#00B4D8])[/color]   → gerak ke bawah

[b]Contoh:[/b]

[color=#00B4D8]func[/color] [color=#06D6A0]run[/color][color=#E8F4F8]():[/color]
    [color=#00B4D8]move_right[/color][color=#E8F4F8]([/color][color=#e7f2f7]5[/color][color=#E8F4F8])[/color]
    [color=#00B4D8]move_down[/color][color=#E8F4F8]([/color][color=#e7f2f7]3[/color][color=#E8F4F8])[/color]

──────────────────────────────

[b][color=#0d0e26]LANGKAH 4 — Jalankan[/color][/b]

Ketuk tombol [color=#4ec539][b]▶[/b][/color] di bagian bawah atas.
SOR-BOT akan menjalankan kode yang kamu tulis.

Jika bot tidak menyelesaikan misis dengan tepat, ketuk [color=#4ec539][b]Tombol RESET[/b][/color],
perbaiki kode, coba lagi.

──────────────────────────────

[b][color=#0d0e26]TIPS[/color][/b]

[color=#278c40]✓[/color]  Lihat label [color=#278c40](x,y)[/color] pada grid untuk menghitung langkah
[color=#278c40]✓[/color]  Kode berjalan dari atas ke bawah, urutan penulisan itu penting
[color=#278c40]✓[/color]  Buka [b]Docs[/b] jika butuh referensi perintah lengkap
[color=#278c40]✓[/color]  Tekan tombol mata untuk masuk mode [color=#278c40][b]Fokus[/b][/color], [color=#278c40]pastikan Text Editor[/color] dan [color=#278c40]Dokumentasi[/color]  sudah terbuka.
[color=#6d2a39]✗[/color]  Jangan tulis kode di luar [color=#90A4AE]func run()[/color]
[color=#6d2a39]✗[/color]  Jangan menulis sintaks yang salah

──────────────────────────────

[color=#0d0e26][i]@Muhammad Zaidan Abdi Fairus.[/i][/color]"""



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

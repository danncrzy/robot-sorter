# res://Scripts/Autoload/game_docs.gd
extends Node

# ── BBCode color helpers ───────────────────────────────────────
# KW  = keyword    (func, for, if, else, return, var)
# FN  = function   (method name)
# PM  = parameter  (numbers, values, strings)
# TP  = type       (void, bool, int, String)
# CM  = comment    (# ...)
# OP  = operator   ((), ->, :, ==, etc.)
# TX  = plain text

const KW := "[color=#c45c6a][b]%s[/b][/color]"
const FN := "[color=#263f71]%s[/color]"
const PM := "[color=#2f9755]%s[/color]"
const TP := "[color=#2f9755]%s[/color]"
const CM := "[color=#90A4AE]%s[/color]"
const OP := "[color=#E8F4F8]%s[/color]"
const ST := "[color=#b67435]\"%s\"[/color]"   # string literal

var pages: Array[Dictionary] = [
	# ── 0. Daftar Isi ─────────────────────────────────────────
	{
		"title":       "Daftar Isi",
		"content":     "",
		"is_toc":      true,
		"toc_visible": true,
		"toc_indent":  0
	},

	# ── 1. Pembukaan ───────────────────────────────────────────
	{
		"title": "Pembukaan",
		"content": """Selamat datang di Game ini.

Buku ini berisi seluruh informasi penting mengenai game ini, buka ketika kamu sedang bingung atau tersesat.
Setiap perintah memiliki parameter dan cara kerjanya masing-masing, pelajari baik-baik.

Semua perintah ditulis di dalam fungsi [color=#c45c6a][b]run()[/b][/color].
Tekan [b]Play[/b] untuk menjalankan kode.
Tekan [b]Reset[/b] jika bot tidak sesuai harapan.

Selamat Bersenang-senang ^^

[color=#90A4AE]— @Muhammad Zaidan Abdi Fairus[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},

	# ── 2. Memulai ─────────────────────────────────────────────
	{
		"title": "Memulai",
		"content": """Satu-satunya tempat kamu menulis kode adalah di dalam fungsi [color=#c45c6a][b]run()[/b][/color].

[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#90A4AE]# tulis perintahmu di sini[/color]

Kode dijalankan dari [b]atas ke bawah[/b], baris per baris.
Bot akan menyelesaikan setiap perintah sebelum lanjut ke berikutnya.

Contoh paling sederhana:

[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8])[/color]
    [color=#263f71]grab[/color][color=#E8F4F8]()[/color]

Bot akan bergerak [b]3 langkah ke kanan[/b], lalu [b]mengambil kotak[/b] di depannya.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},

	# ── 3. Pergerakan ──────────────────────────────────────────
	{
		"title":   "Pergerakan",
		"content": "Perintah untuk menggerakkan SOR-BOT di atas grid.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "move_right / move_left / move_up / move_down",
		"content": """Gerakkan bot ke arah tertentu.

[color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]   [color=#90A4AE]→ 1 langkah ke kanan[/color]
[color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]4[/color][color=#E8F4F8])[/color]   [color=#90A4AE]→ 4 langkah ke kanan[/color]
[color=#263f71]move_left[/color][color=#E8F4F8]([/color][color=#2f9755]2[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ 2 langkah ke kiri[/color]
[color=#263f71]move_up[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]      [color=#90A4AE]→ 1 langkah ke atas[/color]
[color=#263f71]move_down[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ 3 langkah ke bawah[/color]

Parameter [color=#2f9755]steps[/color] wajib diisi dengan jumlah langkah.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "move(x, y)",
		"content": """Gerakkan bot berdasarkan koordinat relatif.

[color=#263f71]move[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8], [/color][color=#2f9755]0[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ 3 langkah ke kanan[/color]
[color=#263f71]move[/color][color=#E8F4F8]([/color][color=#2f9755]0[/color][color=#E8F4F8], [/color][color=#2f9755]-2[/color][color=#E8F4F8])[/color]   [color=#90A4AE]→ 2 langkah ke atas[/color]
[color=#263f71]move[/color][color=#E8F4F8]([/color][color=#2f9755]-1[/color][color=#E8F4F8], [/color][color=#2f9755]0[/color][color=#E8F4F8])[/color]   [color=#90A4AE]→ 1 langkah ke kiri[/color]
[color=#263f71]move[/color][color=#E8F4F8]([/color][color=#2f9755]0[/color][color=#E8F4F8], [/color][color=#2f9755]4[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ 4 langkah ke bawah[/color]

[color=#2f9755]x[/color] positif = kanan, [color=#2f9755]y[/color] positif = bawah.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "step_forward / step_back",
		"content": """Maju atau mundur 1 langkah sesuai arah hadap bot saat ini.

[color=#263f71]step_forward[/color][color=#E8F4F8]()[/color]   [color=#90A4AE]→ maju 1 langkah[/color]
[color=#263f71]step_back[/color][color=#E8F4F8]()[/color]      [color=#90A4AE]→ mundur 1 langkah[/color]

Berguna jika kamu sudah mengatur arah bot dengan [color=#263f71]face()[/color].""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 4. Arah ────────────────────────────────────────────────
	{
		"title":   "Arah",
		"content": "Perintah untuk mengubah arah hadap bot.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "face(arah)",
		"content": """Hadapkan bot langsung ke arah tertentu.

[color=#263f71]face[/color][color=#E8F4F8]([/color][color=#b67435]"right"[/color][color=#E8F4F8])[/color]   [color=#90A4AE]→ hadap kanan[/color]
[color=#263f71]face[/color][color=#E8F4F8]([/color][color=#b67435]"left"[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ hadap kiri[/color]
[color=#263f71]face[/color][color=#E8F4F8]([/color][color=#b67435]"up"[/color][color=#E8F4F8])[/color]      [color=#90A4AE]→ hadap atas[/color]
[color=#263f71]face[/color][color=#E8F4F8]([/color][color=#b67435]"down"[/color][color=#E8F4F8])[/color]    [color=#90A4AE]→ hadap bawah[/color]

Lebih cepat dari turn jika arah tujuan jauh dari arah saat ini.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 5. Interaksi ───────────────────────────────────────────
	{
		"title":   "Interaksi",
		"content": "Perintah untuk mengambil dan meletakkan kotak.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "grab()",
		"content": """Ambil kotak yang berada di dekat bot.

[color=#263f71]grab[/color][color=#E8F4F8]()[/color]

Bot hanya bisa memegang [b]satu kotak[/b] dalam satu waktu.
Jika sudah memegang kotak, [color=#263f71]grab()[/color] tidak akan bekerja.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "drop()",
		"content": """Letakkan kotak yang sedang dipegang.

[color=#263f71]drop[/color][color=#E8F4F8]()[/color]

Jika bot berada di dekat rak yang tepat, kotak akan [b]tersimpan di rak[/b].
Jika tidak, kotak dijatuhkan di lantai.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 6. Pengecekan ──────────────────────────────────────────
	{
		"title":   "Pengecekan",
		"content": "Perintah untuk mengecek status bot. Digunakan bersama [color=#c45c6a][b]if[/b][/color].",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "is_holding()",
		"content": """Cek apakah bot sedang memegang kotak.

Mengembalikan: [color=#2f9755]true[/color] atau [color=#2f9755]false[/color]

[color=#c45c6a][b]if[/b][/color] [color=#263f71]is_holding[/color][color=#E8F4F8]():[/color]
    [color=#263f71]drop[/color][color=#E8F4F8]()[/color]
[color=#c45c6a][b]else[/b][/color][color=#E8F4F8]:[/color]
	[color=#263f71]grab[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "get_facing()",
		"content": """Cek arah hadap bot saat ini.

Mengembalikan: [color=#b67435]"right"[/color], [color=#b67435]"left"[/color], [color=#b67435]"up"[/color], atau [color=#b67435]"down"[/color]

[color=#c45c6a][b]if[/b][/color] [color=#263f71]get_facing[/color][color=#E8F4F8]() == [/color][color=#b67435]"right"[/color][color=#E8F4F8]:[/color]
	[color=#263f71]step_forward[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "get_grid_position()",
		"content": """Dapatkan posisi bot di atas grid.

Mengembalikan: koordinat [color=#2f9755](x, y)[/color]

[color=#c45c6a][b]var[/b][/color] [color=#E8F4F8]pos = [/color][color=#263f71]get_grid_position[/color][color=#E8F4F8]()[/color]
[color=#c45c6a][b]if[/b][/color] [color=#E8F4F8]pos.x == [/color][color=#2f9755]5[/color][color=#E8F4F8]:[/color]
	[color=#263f71]grab[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 7. Perulangan ──────────────────────────────────────────
	{
		"title":   "Perulangan",
		"content": "Mengulang perintah tanpa menulis kode yang sama berkali-kali.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "for (ulang sejumlah kali)",
		"content": """Ulangi kode sebanyak angka yang ditentukan.

[color=#c45c6a][b]for[/b][/color] [color=#E8F4F8]i [/color][color=#c45c6a][b]in[/b][/color] [color=#263f71]range[/color][color=#E8F4F8]([/color][color=#2f9755]5[/color][color=#E8F4F8]):[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]

Bot akan bergerak kanan sebanyak [color=#2f9755]5[/color] kali.
[color=#263f71]range[/color][color=#E8F4F8]([/color][color=#2f9755]n[/color][color=#E8F4F8])[/color] menghasilkan angka dari [color=#2f9755]0[/color] sampai [color=#2f9755]n-1[/color].

Contoh lain:
[color=#c45c6a][b]for[/b][/color] [color=#E8F4F8]i [/color][color=#c45c6a][b]in[/b][/color] [color=#263f71]range[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8]):[/color]
    [color=#263f71]grab[/color][color=#E8F4F8]()[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]
	[color=#263f71]drop[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Kondisi (if / else)",
		"content": """Jalankan kode hanya jika kondisi terpenuhi.

[color=#c45c6a][b]if[/b][/color] [color=#263f71]is_holding[/color][color=#E8F4F8]():[/color]
    [color=#263f71]drop[/color][color=#E8F4F8]()[/color]

[color=#c45c6a][b]if[/b][/color] [color=#263f71]get_facing[/color][color=#E8F4F8]() == [/color][color=#b67435]"right"[/color][color=#E8F4F8]:[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]
[color=#c45c6a][b]else[/b][/color][color=#E8F4F8]:[/color]
    [color=#263f71]face[/color][color=#E8F4F8]([/color][color=#b67435]"right"[/color][color=#E8F4F8])[/color]

Operator yang bisa digunakan:
  [color=#E8F4F8]==[/color]   sama dengan
  [color=#E8F4F8]!=[/color]   tidak sama dengan
  [color=#E8F4F8]>[/color]    lebih besar dari
  [color=#E8F4F8]<[/color]    lebih kecil dari""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 8. Contoh Program ──────────────────────────────────────
	{
		"title":   "Contoh Program",
		"content": "Kode siap pakai untuk berbagai situasi.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "Ambil kotak lalu taruh di rak",
		"content": """[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8])[/color]
    [color=#263f71]grab[/color][color=#E8F4F8]()[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]2[/color][color=#E8F4F8])[/color]
	[color=#263f71]drop[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Ambil 3 kotak berjajar",
		"content": """[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#c45c6a][b]for[/b][/color] [color=#E8F4F8]i [/color][color=#c45c6a][b]in[/b][/color] [color=#263f71]range[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8]):[/color]
        [color=#263f71]grab[/color][color=#E8F4F8]()[/color]
        [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]1[/color][color=#E8F4F8])[/color]

[color=#90A4AE]# Bot mengambil kotak lalu bergeser kanan sebanyak 3 kali.[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Jelajahi pola U",
		"content": """[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#263f71]move_right[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8])[/color]
    [color=#263f71]move_down[/color][color=#E8F4F8]([/color][color=#2f9755]2[/color][color=#E8F4F8])[/color]
	[color=#263f71]move_left[/color][color=#E8F4F8]([/color][color=#2f9755]3[/color][color=#E8F4F8])[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Cek sebelum ambil",
		"content": """[color=#c45c6a][b]func[/b][/color] [color=#4ef3e1]run[/color][color=#E8F4F8]():[/color]
    [color=#c45c6a][b]if[/b][/color] [color=#c45c6a][b]not[/b][/color] [color=#263f71]is_holding[/color][color=#E8F4F8]():[/color]
        [color=#263f71]grab[/color][color=#E8F4F8]()[/color]
    [color=#c45c6a][b]if[/b][/color] [color=#263f71]is_holding[/color][color=#E8F4F8]():[/color]
		[color=#263f71]drop[/color][color=#E8F4F8]()[/color]""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
]

func get_page(index: int) -> Dictionary:
	if index >= 0 and index < pages.size():
		return pages[index]
	return {}

func get_page_count() -> int:
	return pages.size()

func get_toc_pages() -> Array:
	var toc := []
	for i in pages.size():
		var p: Dictionary = pages[i]
		if p.get("toc_visible", false) and not p.get("is_toc", false):
			toc.append({ "index": i, "title": p["title"], "indent": p.get("toc_indent", 0) })
	return toc

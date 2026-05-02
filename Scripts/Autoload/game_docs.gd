# res://Scripts/Autoload/game_docs.gd
extends Node

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

Buku ini berisi  seluruh informasi penting mengenai game ini, buka ketika kamu sedang bingung atau tersesat.
Setiap perintah memiliki parameter dan cara kerjanya masing masing, pelajari baik-baik.

Semua perintah ditulis di dalam fungsi run().
Tekan Play untuk menjalankan kode.
Tekan Reset jika bot tidak sesuai harapan.

Selamat Bersenang-senang ^^

— @Muhammad Zaidan Abdi Fairus""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},

	# ── 2. Memulai ─────────────────────────────────────────────
	{
		"title": "Memulai",
		"content": """Satu-satunya tempat kamu menulis kode adalah di dalam fungsi run().

func run():
    # tulis perintahmu di sini

Kode dijalankan dari atas ke bawah, baris per baris.
Bot akan menyelesaikan setiap perintah sebelum lanjut ke perintah berikutnya.

Contoh paling sederhana:

func run():
    move_right(3)
    grab()

Bot akan bergerak 3 langkah ke kanan, lalu mengambil kotak di depannya.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},

	# ── 3. Pergerakan ──────────────────────────────────────────
	{
		"title":       "Pergerakan",
		"content":     "Perintah untuk menggerakkan SOR-BOT di atas grid.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "move_right / move_left / move_up / move_down",
		"content": """Gerakkan bot ke arah tertentu.

move_right()      → 1 langkah ke kanan
move_right(4)     → 4 langkah ke kanan
move_left(2)      → 2 langkah ke kiri
move_up()         → 1 langkah ke atas
move_down(3)      → 3 langkah ke bawah

Parameter steps bersifat opsional. Tanpa angka = 1 langkah.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "move(x, y)",
		"content": """Gerakkan bot berdasarkan koordinat relatif.

move(3, 0)    → 3 langkah ke kanan
move(0, -2)   → 2 langkah ke atas
move(-1, 0)   → 1 langkah ke kiri
move(0, 4)    → 4 langkah ke bawah

Catatan: x positif = kanan, y positif = bawah.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "move_to(x, y)",
		"content": """Pindahkan bot langsung ke koordinat tertentu di grid.

move_to(5, 3)   → pindah ke posisi (5, 3)
move_to(1, 1)   → kembali ke pojok kiri atas

Koordinat dilihat dari label pada grid di layar.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "step_forward / step_back",
		"content": """Maju atau mundur 1 langkah sesuai arah hadap bot saat ini.

step_forward()   → maju 1 langkah
step_back()      → mundur 1 langkah

Berguna jika kamu sudah mengatur arah bot dengan turn atau face.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "stop()",
		"content": """Hentikan semua pergerakan bot secara instan.

stop()

Semua antrian gerak dibatalkan. Bot berhenti di posisinya.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 4. Arah ────────────────────────────────────────────────
	{
		"title":       "Arah",
		"content":     "Perintah untuk mengubah arah hadap bot.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "turn_left / turn_right",
		"content": """Putar bot 90 derajat tanpa bergerak.

turn_left()    → putar ke kiri
turn_right()   → putar ke kanan

Contoh: bot menghadap kanan → turn_left() → kini menghadap atas.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "face(arah)",
		"content": """Hadapkan bot langsung ke arah tertentu.

face(\"right\")   → hadap kanan
face(\"left\")    → hadap kiri
face(\"up\")      → hadap atas
face(\"down\")    → hadap bawah

Lebih cepat dari turn jika arah tujuan jauh dari arah saat ini.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "rotate_deg(derajat)",
		"content": """Putar bot sejumlah derajat.

rotate_deg(90)    → putar 90° ke kanan
rotate_deg(-90)   → putar 90° ke kiri
rotate_deg(180)   → balik arah

Gunakan kelipatan 90 agar hasilnya tepat.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 5. Interaksi ───────────────────────────────────────────
	{
		"title":       "Interaksi",
		"content":     "Perintah untuk mengambil dan meletakkan kotak.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "grab()",
		"content": """Ambil kotak yang berada di depan bot.

grab()

Bot harus menghadap ke arah kotak.
Bot hanya bisa memegang satu kotak dalam satu waktu.
Jika sudah memegang kotak, grab() tidak akan bekerja.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "drop()",
		"content": """Letakkan kotak yang sedang dipegang.

drop()

Jika bot berada di dekat rak yang tepat, kotak akan tersimpan di rak.
Jika tidak, kotak dijatuhkan di lantai.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "interact()",
		"content": """Berinteraksi dengan objek di depan bot.

interact()

Digunakan untuk menekan tombol, membuka pintu, atau
mengaktifkan mesin tertentu di level.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 6. Pengecekan ──────────────────────────────────────────
	{
		"title":       "Pengecekan",
		"content":     "Perintah untuk mengecek status bot. Digunakan bersama if.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "is_holding()",
		"content": """Cek apakah bot sedang memegang kotak.

Mengembalikan: true atau false

Contoh penggunaan:
if is_holding():
    drop()
else:
	grab()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "get_facing()",
		"content": """Cek arah hadap bot saat ini.

Mengembalikan: \"right\", \"left\", \"up\", atau \"down\"

Contoh penggunaan:
if get_facing() == \"right\":
	step_forward()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "is_moving()",
		"content": """Cek apakah bot sedang bergerak.

Mengembalikan: true atau false

Contoh penggunaan:
if not is_moving():
	grab()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "get_grid_position()",
		"content": """Dapatkan posisi bot di atas grid.

Mengembalikan: koordinat (x, y)

Contoh penggunaan:
var pos = get_grid_position()
if pos.x == 5:
	stop()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 7. Perulangan ──────────────────────────────────────────
	{
		"title":       "Perulangan",
		"content":     "Mengulang perintah tanpa menulis kode yang sama berkali-kali.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "for (ulang sejumlah kali)",
		"content": """Ulangi kode sebanyak angka yang ditentukan.

for i in range(5):
    move_right()

Bot akan bergerak kanan sebanyak 5 kali.

range(n) menghasilkan angka dari 0 sampai n-1.
Variabel i bisa diabaikan jika tidak dipakai.

Contoh lain:
for i in range(3):
    grab()
    move_right()
	drop()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Kondisi (if / else)",
		"content": """Jalankan kode hanya jika kondisi terpenuhi.

if is_holding():
    drop()

if get_facing() == \"right\":
    move_right()
else:
    face(\"right\")

Operator yang bisa digunakan:
  ==   sama dengan
  !=   tidak sama dengan
  >    lebih besar dari
  <    lebih kecil dari""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},

	# ── 8. Contoh Program ──────────────────────────────────────
	{
		"title":       "Contoh Program",
		"content":     "Kode siap pakai untuk berbagai situasi.",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  0
	},
	{
		"title": "Ambil kotak lalu taruh di rak",
		"content": """func run():
    move_right(3)
    grab()
    move_right(2)
	drop()""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Ambil 5 kotak berjajar",
		"content": """func run():
    for i in range(5):
        grab()
        move_right()

Bot mengambil kotak lalu bergeser kanan sebanyak 5 kali.""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Jelajahi pola U",
		"content": """func run():
    move_right(3)
    move_down(2)
	move_left(3)""",
		"is_toc":      false,
		"toc_visible": true,
		"toc_indent":  1
	},
	{
		"title": "Cek sebelum ambil",
		"content": """func run():
    if not is_holding():
        grab()
    move_to(8, 4)
    if is_holding():
		drop()""",
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

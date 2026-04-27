# res://Scripts/Autoload/game_docs.gd
extends Node

var pages: Array[Dictionary] = [
	{
		"title": "Daftar Isi",
		"content": "",
		"is_toc": true,
		"toc_visible": true,
		"toc_indent": 0
	},
	
	# ============================================================
	#   DASAR-DASAR GDSCRIPT
	# ============================================================
	{
		"title": "1. Variabel",
		"content": "Variabel adalah wadah untuk menyimpan data. Gunakan kata kunci 'var' untuk membuatnya.\n\nContoh:\nvar skor = 0\nvar nama = \"Bot\"\nvar aktif = true",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "1.1 Tipe Data",
		"content": "GDScript memiliki beberapa tipe data utama:\n\nint      → Bilangan bulat (10, -5, 0)\nfloat    → Bilangan desimal (3.14, -2.5)\nString   → Teks (\"Halo\", \"Bot\")\nbool     → Benar atau salah (true, false)\nVector2  → Posisi 2D (x, y)\n\nContoh:\nvar umur: int = 10\nvar tinggi: float = 1.75\nvar nama: String = \"SOR\"\nvar hidup: bool = true\nvar pos: Vector2 = Vector2(3, 5)",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "1.2 Boolean (bool)",
		"content": "Boolean hanya memiliki dua nilai: true atau false.\n\nDigunakan untuk kondisi dan pengecekan status.\n\nContoh:\nvar sedang_gerak = false\nvar memegang_barang = true",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "1.3 String",
		"content": "String digunakan untuk menyimpan teks. Teks ditulis dalam tanda kutip.\n\nContoh:\nvar nama = \"Robot\"\nvar arah = \"up\"\n\nGabung string dengan operator +:\nvar pesan = \"Halo, \" + nama",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   FUNGSI
	# ============================================================
	{
		"title": "2. Fungsi",
		"content": "Fungsi adalah blok kode yang dapat digunakan ulang. Definisikan dengan kata kunci 'func'.\n\nStruktur:\nfunc nama_fungsi(parameter):\n    # kode di sini\n\nContoh:\nfunc sapa():\n    print(\"Halo!\")\n\nfunc tambah(a, b):\n    return a + b",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "2.1 Fungsi run()",
		"content": "Fungsi run() adalah titik masuk utama program kamu. Kode yang ditulis di sini akan dieksekusi saat tombol Play ditekan.\n\nContoh:\nfunc run():\n    move(3, 0)\n    grab()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   PERINTAH SOR-BOT - PERGERAKAN
	# ============================================================
	{
		"title": "3. Pergerakan",
		"content": "Perintah untuk menggerakkan bot pada grid.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "3.1 move(x, y)",
		"content": "Menggeser posisi bot berdasarkan koordinat relatif.\n\nParameter:\n  x (int) → Geser horizontal (+ kanan, - kiri)\n  y (int) → Geser vertikal (+ bawah, - atas)\n\nContoh:\nmove(3, 0)   # gerak 3 langkah ke kanan\nmove(0, -2)  # gerak 2 langkah ke atas\nmove(-1, 1)  # gerak 1 kiri, 1 bawah",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "3.2 move_right / move_left / move_up / move_down",
		"content": "Gerak ke arah tertentu sejumlah langkah.\n\nParameter:\n  steps (int, opsional) → jumlah langkah (default: 1)\n\nContoh:\nmove_right()     # 1 langkah kanan\nmove_right(5)    # 5 langkah kanan\nmove_left(3)     # 3 langkah kiri\nmove_up(2)       # 2 langkah atas\nmove_down()      # 1 langkah bawah",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "3.3 move_to(x, y)",
		"content": "Memindahkan bot langsung ke posisi koordinat tertentu.\n\nParameter:\n  x (int) → koordinat horizontal tujuan\n  y (int) → koordinat vertikal tujuan\n\nContoh:\nmove_to(5, 3)  # pindah langsung ke posisi (5, 3)\nmove_to(0, 0)  # kembali ke pojok kiri atas",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "3.4 step_forward / step_back",
		"content": "Maju atau mundur 1 langkah sesuai arah hadap bot.\n\nContoh:\nstep_forward()  # maju 1 langkah ke depan\nstep_back()     # mundur 1 langkah ke belakang",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "3.5 stop",
		"content": "Menghentikan semua pergerakan bot secara instan.\n\nContoh:\nstop()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   PERINTAH SOR-BOT - ARAH & ROTASI
	# ============================================================
	{
		"title": "4. Arah dan Rotasi",
		"content": "Perintah untuk mengubah arah hadap bot.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "4.1 turn_left / turn_right",
		"content": "Memutar bot 90 derajat.\n\nContoh:\nturn_left()   # putar 90° berlawanan jarum jam\nturn_right()  # putar 90° searah jarum jam",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "4.2 rotate_deg",
		"content": "Memutar bot dengan derajat yang ditentukan.\n\nParameter:\n  deg (float) → sudut rotasi dalam derajat\n\nContoh:\nrotate_deg(45)   # putar 45°\nrotate_deg(-90)  # putar 90° ke kiri\nrotate_deg(180)  # putar balik",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "4.3 face",
		"content": "Menghadapkan bot langsung ke arah tertentu.\n\nParameter:\n  direction (string) → \"left\", \"right\", \"up\", atau \"down\"\n\nContoh:\nface(\"up\")    # hadap atas\nface(\"right\") # hadap kanan\nface(\"down\")  # hadap bawah",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   PERINTAH SOR-BOT - QUERY (PENGECEKAN)
	# ============================================================
	{
		"title": "5. Query (Pengecekan Status)",
		"content": "Perintah untuk mendapatkan informasi status bot.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "5.1 is_moving",
		"content": " Mengecek apakah bot sedang bergerak.\n\nReturn:\n  bool → true jika sedang bergerak, false jika diam\n\nContoh:\nif is_moving():\n    print(\"Bot sedang bergerak\")",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "5.2 get_facing",
		"content": " Mendapatkan arah hadap bot saat ini.\n\nReturn:\n  string → \"left\", \"right\", \"up\", atau \"down\"\n\nContoh:\nvar arah = get_facing()\nif arah == \"up\":\n    print(\"Bot menghadap atas\")",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "5.3 get_grid_position",
		"content": " Mendapatkan posisi bot pada grid.\n\nReturn:\n  Vector2 → posisi (x, y) pada grid\n\nContoh:\nvar pos = get_grid_position()\nprint(\"Posisi X: \", pos.x)\nprint(\"Posisi Y: \", pos.y)",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "5.4 is_holding",
		"content": " Mengecek apakah bot sedang memegang barang.\n\nReturn:\n  bool → true jika memegang barang, false jika tidak\n\nContoh:\nif is_holding():\n    drop()\nelse:\n    grab()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   PERINTAH SOR-BOT - INTERAKSI
	# ============================================================
	{
		"title": "6. Interaksi",
		"content": "Perintah untuk berinteraksi dengan objek dan barang.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "6.1 grab",
		"content": " Mengambil barang yang berada di depan bot.\n\nContoh:\ngrab()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "6.2 drop",
		"content": " Meletakkan barang yang sedang dipegang.\n\nContoh:\ndrop()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "6.3 interact",
		"content": " Berinteraksi dengan objek yang berada di depan bot (misalnya: menekan tombol, membuka pintu).\n\nContoh:\ninteract()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   KONTROL ALUR PROGRAM
	# ============================================================
	{
		"title": "7. Kontrol Alur Program",
		"content": "Mengontrol bagaimana kode dieksekusi.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "7.1 Percabangan (if/else)",
		"content": "Menjalankan kode berdasarkan kondisi.\n\nContoh:\nif get_facing() == \"right\":\n    move_forward()\nelse:\n    turn_right()\n\nOperator perbandingan:\n  ==  sama dengan\n  !=  tidak sama dengan\n  >   lebih besar\n  <   lebih kecil\n  >=  lebih besar atau sama\n  <=  lebih kecil atau sama",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "7.2 Perulangan (for/while)",
		"content": "Mengulang kode beberapa kali.\n\nFor loop:\nfor i in range(5):\n    move_right()  # diulang 5 kali\n\nWhile loop:\nvar hitung = 0\nwhile hitung < 3:\n    move_forward()\n    hitung += 1",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},

	# ============================================================
	#   CONTOH LENGKAP
	# ============================================================
	{
		"title": "8. Contoh Program",
		"content": "Beberapa contoh kode lengkap yang bisa langsung digunakan.\n\n--- Contoh 1: Gerak ke kanan lalu ambil item ---\nfunc run():\n    move(3, 0)\n    grab()\n\n--- Contoh 2: Jelajahi bentuk U ---\nfunc run():\n    move_right(3)\n    move_down(2)\n    move_left(3)\n\n--- Contoh 3: Ambil semua item dalam barisan ---\nfunc run():\n    for i in range(5):\n        grab()\n        move_right()\n\n--- Contoh 4: Cek arah sebelum gerak ---\nfunc run():\n    if get_facing() != \"right\":\n        face(\"right\")\n    move_forward()",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	}
]

func get_page(index: int) -> Dictionary:
	if index >= 0 and index < pages.size():
		return pages[index]
	return {}

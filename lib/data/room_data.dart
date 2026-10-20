import '../models/room_model.dart';

// ============================================================
// DATA MASTER SELURUH RUANGAN — 3 LANTAI
//
// KONVENSI FOTO:
//   Folder : assets/images/rooms/lantaiX/
//   Nama   : [kode_tanpa_titik]_[huruf].jpg
//   Contoh : ruangan 1.1 → 1_1_a.jpg, 1_1_b.jpg, dst.
//            ruangan 2.15 → 2_15_a.jpg, 2_15_b.jpg, dst.
//
// Cara tambah foto:
//   1. Taruh file di folder lantai yang sesuai
//   2. Tambahkan path ke list images[] di bawah
//   3. Bisa lebih dari 1 foto per ruangan (a, b, c, dst.)
//
// Kategori:
//   loker     = Loker Penitipan        (teal)
//   koleksi   = Ruang Layanan/Koleksi  (amber)
//   pertemuan = Ruang Pertemuan        (pink gelap)
//   kantor    = Kantor/Administrasi    (biru)
//   cafetaria = Cafetaria              (pink muda)
// ============================================================

const List<RoomModel> masterRoomsData = [

// ==================== LANTAI DASAR (internal: floor 1) ====================
  RoomModel(
    code: "1.1",
    name: "Ruang Bermain Anak",
    floor: 1,
    xRatio: 0.670,
    yRatio: 0.653,
    category: RoomCategory.koleksi,
    desc: "Area bermain interaktif untuk anak-anak.",
    images: [

    ],
  ),
  RoomModel(
    code: "1.2",
    name: "Ruang Laktasi",
    floor: 1,
    xRatio: 0.578,
    yRatio: 0.688,
    category: RoomCategory.koleksi,
    desc: "Ruang menyusui dan perawatan bayi.",
    images: [
      // 'assets/images/rooms/lantai1/1_2_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.3",
    name: "Ruang Mendongeng",
    floor: 1,
    xRatio: 0.563,
    yRatio: 0.406,
    category: RoomCategory.koleksi,
    desc: "Ruang kegiatan bercerita dan dongeng anak.",
    images: [
      // 'assets/images/rooms/lantai1/1_3_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.4",
    name: "Ruang Musik Anak",
    floor: 1,
    xRatio: 0.385,
    yRatio: 0.400,
    category: RoomCategory.koleksi,
    desc: "Fasilitas pengenalan dan latihan musik anak.",
    images: [
      // 'assets/images/rooms/lantai1/1_4_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.5",
    name: "Ruang Koleksi Buku Anak",
    floor: 1,
    xRatio: 0.385,
    yRatio: 0.629,
    category: RoomCategory.koleksi,
    desc: "Area koleksi buku bacaan khusus anak-anak.",
    images: [
      // 'assets/images/rooms/lantai1/1_5_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.6",
    name: "Ruang Penyimpanan Koleksi Keliling & Paket",
    floor: 1,
    xRatio: 0.265,
    yRatio: 0.592,
    category: RoomCategory.koleksi,
    desc: "Gudang penyimpanan armada dan bahan pustaka keliling.",
    images: [
      // 'assets/images/rooms/lantai1/1_6_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.7",
    name: "Ruang Koleksi Tandon Bawah",
    floor: 1,
    xRatio: 0.274,
    yRatio: 0.362,
    category: RoomCategory.koleksi,
    desc: "Penyimpanan koleksi tandon utama lantai bawah.",
    images: [
      // 'assets/images/rooms/lantai1/1_7_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.8",
    name: "Ruang Kasubbid Deposit dan Pengolahan Bahan Pustaka",
    floor: 1,
    xRatio: 0.31,
    yRatio: 0.29,
    category: RoomCategory.kantor,
    desc: "Kantor Kepala Subbidang Deposit & Pengolahan.",
    images: [
      // 'assets/images/rooms/lantai1/1_8_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.9",
    name: "Ruang Pustakawan",
    floor: 1,
    xRatio: 0.245,
    yRatio: 0.271,
    category: RoomCategory.kantor,
    desc: "Ruang kerja para staf pustakawan.",
    images: [
      // 'assets/images/rooms/lantai1/1_9_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.10",
    name: "Ruang Pengolahan Bahan Pustaka",
    floor: 1,
    xRatio: 0.265,
    yRatio: 0.192,
    category: RoomCategory.kantor,
    desc: "Proses klasifikasi, katalogisasi, dan pengolahan buku baru.",
    images: [
      // 'assets/images/rooms/lantai1/1_10_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.11",
    name: "Ruang Penerimaan Bahan Pustaka",
    floor: 1,
    xRatio: 0.39,
    yRatio: 0.19,
    category: RoomCategory.kantor,
    desc: "Penerimaan serah simpan karya cetak dan rekam.",
    images: [
      // 'assets/images/rooms/lantai1/1_11_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.12",
    name: "Loker Lantai Dasar",
    floor: 1,
    xRatio: 0.44,
    yRatio: 0.26,
    category: RoomCategory.loker,
    desc: "Fasilitas loker penitipan barang bawaan pengunjung Lantai Dasar.",
    images: [
      // 'assets/images/rooms/lantai1/1_12_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.13",
    name: "Ruang Loker Pegawai",
    floor: 1,
    xRatio: 0.598,
    yRatio: 0.184,
    category: RoomCategory.kantor,
    desc: "Fasilitas loker khusus staf dan pegawai perpustakaan.",
    images: [
      // 'assets/images/rooms/lantai1/1_13_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.14",
    name: "Ruang Restorasi Pustaka",
    floor: 1,
    xRatio: 0.577,
    yRatio: 0.279,
    category: RoomCategory.kantor,
    desc: "Perbaikan dan perawatan fisik buku yang rusak.",
    images: [
      // 'assets/images/rooms/lantai1/1_14_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.15",
    name: "Ruang Alih Media",
    floor: 1,
    xRatio: 0.644,
    yRatio: 0.264,
    category: RoomCategory.kantor,
    desc: "Proses digitalisasi naskah dan dokumen ke format digital.",
    images: [
      // 'assets/images/rooms/lantai1/1_15_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.16",
    name: "Ruang Pelestarian Bahan Pustaka",
    floor: 1,
    xRatio: 0.707,
    yRatio: 0.190,
    category: RoomCategory.kantor,
    desc: "Konservasi dan preservasi koleksi fisik perpustakaan.",
    images: [
      // 'assets/images/rooms/lantai1/1_16_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.17",
    name: "Ruang Kasie. Pelestarian Bahan Pustaka",
    floor: 1,
    xRatio: 0.729,
    yRatio: 0.276,
    category: RoomCategory.kantor,
    desc: "Kantor Kepala Seksi Pelestarian Bahan Pustaka.",
    images: [
      // 'assets/images/rooms/lantai1/1_17_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.18",
    name: "Ruang Bioskop/Cinema 6D",
    floor: 1,
    xRatio: 0.718,
    yRatio: 0.376,
    category: RoomCategory.koleksi,
    desc: "Fasilitas pemutaran film edukasi 6 Dimensi.",
    images: [
      // 'assets/images/rooms/lantai1/1_18_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.19",
    name: "Mushola",
    floor: 1,
    xRatio: 0.717,
    yRatio: 0.566,
    category: RoomCategory.koleksi,
    desc: "Fasilitas tempat ibadah untuk pengunjung.",
    images: [
      // 'assets/images/rooms/lantai1/1_19_a.jpg',
    ],
  ),
  RoomModel(
    code: "1.20",
    name: "Kantin",
    floor: 1,
    xRatio: 0.110,
    yRatio: 0.779,
    category: RoomCategory.cafetaria,
    desc: "Area kantin utama tempat makan & minum pengunjung.",
    images: [
      'assets/images/rooms/lantai1/1_20_a.webp',
      'assets/images/rooms/lantai1/1_20_b.webp',
      'assets/images/rooms/lantai1/1_20_c.webp',
      'assets/images/rooms/lantai1/1_20_d.webp',
      'assets/images/rooms/lantai1/1_20_e.webp',
      'assets/images/rooms/lantai1/1_20_f.webp',
    ],
  ),

// ==================== LANTAI 1 (internal: floor 2) ====================
  RoomModel(
    code: "2.1",
    name: "Ruang Prefunction Lt. 1",
    floor: 2,
    xRatio: 0.64,
    yRatio: 0.815,
    category: RoomCategory.kantor,
    desc: "Area selasar/lobby penerimaan sebelum masuk area utama Lantai 1.",
    images: [
      // 'assets/images/rooms/lantai2/2_1_a.jpg',
    ],
  ),
  RoomModel(
    code: "2.2",
    name: "Ruang Informasi Layanan",
    floor: 2,
    xRatio: 0.578,
    yRatio: 0.850,
    category: RoomCategory.koleksi,
    desc: "Pusat informasi dan bantuan layanan perpustakaan.",
    images: [
      'https://drive.google.com/file/d/1VTU8h8sYP1YAT_k_WU49s3IIpVPQtYVT/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.3",
    name: "Ruang Keanggotaan dan Layanan Bebas Pustaka",
    floor: 2,
    xRatio: 0.565,
    yRatio: 0.729,
    category: RoomCategory.koleksi,
    desc: "Layanan pendaftaran kartu anggota dan pengurusan surat bebas pustaka.",
    images: [
      // 'assets/images/rooms/lantai2/2_3_a.jpg',
    ],
  ),
  RoomModel(
    code: "2.4",
    name: "Ruang Loker Lantai 1",
    floor: 2,
    xRatio: 0.384,
    yRatio: 0.743,
    category: RoomCategory.loker,
    desc: "Fasilitas penitipan barang bawaan pengunjung Lantai 1.",
    images: [
      'https://drive.google.com/file/d/15ney2q3IrpK48-ow8o2z7GGQcFQyJDnl/view?usp=sharing',
      'https://drive.google.com/file/d/1GMlDK4h4WEWcBLTL3ROTTs4De5rc9lyu/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.5",
    name: "Ruang Pameran",
    floor: 2,
    xRatio: 0.28,
    yRatio: 0.823,
    category: RoomCategory.pertemuan,
    desc: "Galeri pameran karya seni, literasi, dan kebudayaan.",
    images: [
      'https://drive.google.com/file/d/1eKGOI6TNa5-qQiuGbYTfDCAMN0zWxVXo/view?usp=sharing',
      'https://drive.google.com/file/d/1q-JqvuyZedVU9nrDER19Yq3a7OrQdKAl/view?usp=sharing',
      'https://drive.google.com/file/d/1ed3pG_UarpfL81VzgjMQVU5zq86-uzg3/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.6",
    name: "Ruang Koleksi Umum",
    floor: 2,
    xRatio: 0.251,
    yRatio: 0.401,
    category: RoomCategory.koleksi,
    desc: "Koleksi buku ilmu pengetahuan umum dan peminjaman.",
    images: [
      'https://drive.google.com/file/d/1YZGLLvTrqD-q8uj6kAk9Sh4lI0zHURkL/view?usp=sharing',
      'https://drive.google.com/file/d/1EmWPnm5dqv2GX_81r-Kzcv-I0v5gxgqj/view?usp=sharing',
      'https://drive.google.com/file/d/1bk_LvVzVQimqsW2vurBPXFlkoQiNyRIF/view?usp=sharing',
      'https://drive.google.com/file/d/1jhpEqNzKpGLJoJrjCKwmhq8xz1xSdLYP/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.7",
    name: "Ruang Koleksi Braille",
    floor: 2,
    xRatio: 0.483,
    yRatio: 0.237,
    category: RoomCategory.koleksi,
    desc: "Area koleksi buku dan layanan baca berhuruf Braille.",
    images: [
      'https://drive.google.com/file/d/1kLf_vEfhYeYrGNVBLt_b-wuW47gW1gvS/view?usp=sharing',
      'https://drive.google.com/file/d/16l7SR79IeCIlsLyZx1KnvJMBVkJgjMZI/view?usp=sharing',
      'https://drive.google.com/file/d/1yRToUxCcxQw962FU7f5XuGsZHOWV2ZiT/view?usp=sharing',
      'https://drive.google.com/file/d/1gjiatocsNHvgNrQSNh_emK79ovEjm2z1/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.8",
    name: "Ruang Cafetaria",
    floor: 2,
    xRatio: 0.595,
    yRatio: 0.203,
    category: RoomCategory.cafetaria,
    desc: "Area kantin/tempat bersantai dan membeli makanan minuman.",
    images: [
      'https://drive.google.com/file/d/1m9kcE0eBwlPhaUrrsrzG6F3cuQx5zKR9/view?usp=sharing',
      'https://drive.google.com/file/d/1QHhwcW6V1thwwUA_yMF6hVGFlq7rEXTa/view?usp=sharing',
      'https://drive.google.com/file/d/1xCHKv3eow6IjgV-AIPXU8ic-sTJ2NY91/view?usp=sharing',
      'https://drive.google.com/file/d/1ncOyUST0H1pv85ct9fmzhk8MTjahbT4G/view?usp=sharing',
      'https://drive.google.com/file/d/10UMGnRt40SUW9IhtEpt8gR9n9F4hGet9/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.9",
    name: "Ruang Rapat Lantai 1",
    floor: 2,
    xRatio: 0.632,
    yRatio: 0.288,
    category: RoomCategory.pertemuan,
    desc: "Ruang pertemuan internal dan rapat kerja.",
    images: [
      'https://drive.google.com/file/d/1MgokICaD5XJx59PkwbteAjhZTrjWjBlA/view?usp=sharing',
      'https://drive.google.com/file/d/15oHAPHFNqjCaacHdrUUjDnbFHb1U2RoW/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.10",
    name: "Ruang Kepala Balai",
    floor: 2,
    xRatio: 0.707,
    yRatio: 0.180,
    category: RoomCategory.kantor,
    desc: "Kantor pimpinan Balai Grhatama Pustaka.",
    images: [
      'https://drive.google.com/file/d/1ExfQgfAM7n9uVrCgpLwWfR5EHG1UyYOq/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.11",
    name: "Ruang Kasubbag Tata Usaha",
    floor: 2,
    xRatio: 0.724,
    yRatio: 0.232,
    category: RoomCategory.kantor,
    desc: "Kantor Kasubbag Tata Usaha.",
    images: [
      // 'assets/images/rooms/lantai2/2_11_a.jpg',
    ],
  ),
  RoomModel(
    code: "2.12",
    name: "Ruang Kasie Pelayanan Perpustakaan",
    floor: 2,
    xRatio: 0.723,
    yRatio: 0.287,
    category: RoomCategory.kantor,
    desc: "Kantor Kepala Seksi Pelayanan Perpustakaan.",
    images: [
      // 'assets/images/rooms/lantai2/2_12_a.jpg',
    ],
  ),
  RoomModel(
    code: "2.13",
    name: "Ruang Staf Tata Usaha 1",
    floor: 2,
    xRatio: 0.714,
    yRatio: 0.374,
    category: RoomCategory.kantor,
    desc: "Kantor administrasi dan operasional staf TU 1.",
    images: [
      'https://drive.google.com/file/d/1augfqgTThcoUkmQVjthaZL4cJ_fWdAqp/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.14",
    name: "Ruang Staf Tata Usaha 2",
    floor: 2,
    xRatio: 0.640,
    yRatio: 0.376,
    category: RoomCategory.kantor,
    desc: "Kantor operasional staf TU 2.",
    images: [
      'https://drive.google.com/file/d/1uOKk0fLYwyAra-2F7oc3Jlo3V9RG26Bg/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.15",
    name: "Ruang Auditorium",
    floor: 2,
    xRatio: 0.69,
    yRatio: 0.60,
    category: RoomCategory.pertemuan,
    desc: "Aula serbaguna kapasitas besar untuk pertunjukan dan acara resmi.",
    images: [
      'https://drive.google.com/file/d/1hpFEL_41_aD-ArrYQ7iSQEEzok8cjoHs/view?usp=sharing',
    ],
  ),
  RoomModel(
    code: "2.16",
    name: "Ruang Persuratan",
    floor: 2,
    xRatio: 0.725,
    yRatio: 0.759,
    category: RoomCategory.kantor,
    desc: "Pusat pengelolaan dokumen dan administrasi persuratan.",
    images: [
      'https://drive.google.com/file/d/16oiZQKCwOQjPUbOyc1WKId_ciR_2v_Ey/view?usp=sharing',
    ],
  ),

// ==================== LANTAI 2 (internal: floor 3) ====================
  RoomModel(
    code: "3.1",
    name: "Ruang Loker Lantai 2",
    floor: 3,
    xRatio: 0.436,
    yRatio: 0.747,
    category: RoomCategory.loker,
    desc: "Fasilitas penitipan barang pengunjung Lantai 2.",
    images: [
      // 'assets/images/rooms/lantai3/3_1_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.2",
    name: "Ruang Koleksi Digital",
    floor: 3,
    xRatio: 0.286,
    yRatio: 0.835,
    category: RoomCategory.koleksi,
    desc: "Layanan komputer dan akses pustaka digital.",
    images: [
      // 'assets/images/rooms/lantai3/3_2_a.jpg',
      // 'assets/images/rooms/lantai3/3_2_b.jpg',
    ],
  ),
  RoomModel(
    code: "3.3",
    name: "Ruang Koleksi Langka",
    floor: 3,
    xRatio: 0.308,
    yRatio: 0.617,
    category: RoomCategory.koleksi,
    desc: "Koleksi buku kuno, naskah, dan dokumen langka.",
    images: [
      // 'assets/images/rooms/lantai3/3_3_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.4",
    name: "Ruang Koleksi Referensi",
    floor: 3,
    xRatio: 0.307,
    yRatio: 0.432,
    category: RoomCategory.koleksi,
    desc: "Koleksi kamus, ensiklopedia, dan direktori.",
    images: [
      // 'assets/images/rooms/lantai3/3_4_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.5",
    name: "Ruang Koleksi Majalah, Koran & Budaya Timur",
    floor: 3,
    xRatio: 0.314,
    yRatio: 0.264,
    category: RoomCategory.koleksi,
    desc: "Area terbitan berkala, koran harian, dan naskah budaya.",
    images: [
      // 'assets/images/rooms/lantai3/3_5_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.6",
    name: "Ruang Koleksi Tandon Atas",
    floor: 3,
    xRatio: 0.304,
    yRatio: 0.156,
    category: RoomCategory.koleksi,
    desc: "Area penyimpanan tandon koleksi perpustakaan.",
    images: [
      // 'assets/images/rooms/lantai3/3_6_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.7",
    name: "Ruang Seminar & Diskusi",
    floor: 3,
    xRatio: 0.548,
    yRatio: 0.191,
    category: RoomCategory.pertemuan,
    desc: "Ruang pertemuan untuk acara seminar dan diskusi.",
    images: [
      // 'assets/images/rooms/lantai3/3_7_a.jpg',
      // 'assets/images/rooms/lantai3/3_7_b.jpg',
    ],
  ),
  RoomModel(
    code: "3.8",
    name: "Ruang Koridor ke Depo Arsip",
    floor: 3,
    xRatio: 0.731,
    yRatio: 0.184,
    category: RoomCategory.kantor,
    desc: "Akses koridor menuju gedung depo penyimpanan arsip.",
    images: [
      // 'assets/images/rooms/lantai3/3_8_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.9",
    name: "Ruang Transit",
    floor: 3,
    xRatio: 0.764,
    yRatio: 0.376,
    category: RoomCategory.kantor,
    desc: "Ruang persiapan/transit petugas perpustakaan.",
    images: [
      // 'assets/images/rooms/lantai3/3_9_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.10",
    name: "Ruang Koleksi Skripsi",
    floor: 3,
    xRatio: 0.695,
    yRatio: 0.375,
    category: RoomCategory.koleksi,
    desc: "Koleksi karya ilmiah, skripsi, dan tesis.",
    images: [
      // 'assets/images/rooms/lantai3/3_10_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.11",
    name: "Ruang Koleksi COE & Pustaka Nusantara",
    floor: 3,
    xRatio: 0.756,
    yRatio: 0.459,
    category: RoomCategory.koleksi,
    desc: "Center of Excellent & koleksi Pustaka Nusantara.",
    images: [
      // 'assets/images/rooms/lantai3/3_11_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.12",
    name: "Ruang Audio Visual",
    floor: 3,
    xRatio: 0.726,
    yRatio: 0.635,
    category: RoomCategory.pertemuan,
    desc: "Fasilitas pemutaran media audio, film, dan multimedia.",
    images: [
      // 'assets/images/rooms/lantai3/3_12_a.jpg',
      // 'assets/images/rooms/lantai3/3_12_b.jpg',
    ],
  ),
  RoomModel(
    code: "3.13",
    name: "Ruang Administrasi Layanan",
    floor: 3,
    xRatio: 0.582,
    yRatio: 0.744,
    category: RoomCategory.kantor,
    desc: "Kantor dan pusat administrasi staf Lantai 2.",
    images: [
      // 'assets/images/rooms/lantai3/3_13_a.jpg',
    ],
  ),
  RoomModel(
    code: "3.14",
    name: "Ruang Prefunction Lt. 2",
    floor: 3,
    xRatio: 0.672,
    yRatio: 0.837,
    category: RoomCategory.pertemuan,
    desc: "Area kumpul/lobby sebelum masuk ke ruang utama.",
    images: [
      // 'assets/images/rooms/lantai3/3_14_a.jpg',
    ],
  ),
];

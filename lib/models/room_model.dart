import 'package:flutter/material.dart';

// 5 Kategori ruangan sesuai legenda denah
enum RoomCategory {
  loker,       // Loker Penitipan       — teal hijau
  koleksi,     // Ruang Layanan/Koleksi — amber kuning
  pertemuan,   // Ruang Pertemuan       — pink gelap
  kantor,      // Kantor/Administrasi   — biru
  cafetaria,   // Cafetaria             — pink muda
}

// Palet 5 warna resmi berdasarkan legenda denah Grhatama Pustaka
class RoomColors {
  static const Color loker     = Color(0xFF26A69A); // Teal
  static const Color koleksi   = Color(0xFFFFA726); // Amber
  static const Color pertemuan = Color(0xFFC2185B); // Pink gelap (Ruang Pertemuan)
  static const Color kantor    = Color(0xFF1E88E5); // Biru
  static const Color cafetaria = Color(0xFFF48FB1); // Pink muda (Cafetaria)

  static Color fromCategory(RoomCategory cat) {
    switch (cat) {
      case RoomCategory.loker:     return loker;
      case RoomCategory.koleksi:   return koleksi;
      case RoomCategory.pertemuan: return pertemuan;
      case RoomCategory.kantor:    return kantor;
      case RoomCategory.cafetaria: return cafetaria;
    }
  }

  static String labelFromCategory(RoomCategory cat) {
    switch (cat) {
      case RoomCategory.loker:     return 'Loker Penitipan';
      case RoomCategory.koleksi:   return 'Ruang Layanan / Koleksi';
      case RoomCategory.pertemuan: return 'Ruang Pertemuan';
      case RoomCategory.kantor:    return 'Kantor / Administrasi';
      case RoomCategory.cafetaria: return 'Cafetaria';
    }
  }
}

class RoomModel {
  final String? id;
  final String code;
  final String name;
  final int floor;
  final double xRatio;
  final double yRatio;
  final RoomCategory category;
  final String desc;
  // Slot gambar — isi dengan path asset saat foto tersedia
  final List<String> images;

  const RoomModel({
    this.id,
    required this.code,
    required this.name,
    required this.floor,
    required this.xRatio,
    required this.yRatio,
    required this.category,
    required this.desc,
    this.images = const [],
  });

  Color get color => RoomColors.fromCategory(category);

  static RoomCategory categoryFromString(String value) {
    switch (value.toLowerCase()) {
      case 'loker':
        return RoomCategory.loker;
      case 'koleksi':
        return RoomCategory.koleksi;
      case 'pertemuan':
        return RoomCategory.pertemuan;
      case 'kantor':
        return RoomCategory.kantor;
      case 'cafetaria':
      case 'kafetaria':
        return RoomCategory.cafetaria;
      default:
        return RoomCategory.koleksi;
    }
  }

  static String categoryToString(RoomCategory cat) {
    return cat.name;
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id']?.toString(),
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      floor: (map['floor'] as num?)?.toInt() ?? 1,
      xRatio: (map['x_ratio'] as num?)?.toDouble() ?? 0.5,
      yRatio: (map['y_ratio'] as num?)?.toDouble() ?? 0.5,
      category: categoryFromString(map['category'] as String? ?? ''),
      desc: map['description'] as String? ?? (map['desc'] as String? ?? ''),
      images: (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'floor': floor,
      'x_ratio': xRatio,
      'y_ratio': yRatio,
      'category': categoryToString(category),
      'description': desc,
      'images': images,
    };
  }

  RoomModel copyWith({
    String? id,
    String? code,
    String? name,
    int? floor,
    double? xRatio,
    double? yRatio,
    RoomCategory? category,
    String? desc,
    List<String>? images,
  }) {
    return RoomModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      xRatio: xRatio ?? this.xRatio,
      yRatio: yRatio ?? this.yRatio,
      category: category ?? this.category,
      desc: desc ?? this.desc,
      images: images ?? this.images,
    );
  }
}


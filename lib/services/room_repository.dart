import 'package:flutter/foundation.dart';
import '../data/room_data.dart';
import '../models/room_model.dart';
import 'supabase_service.dart';

class RoomRepository {
  RoomRepository._internal() {
    // Muat data master awal saat inisialisasi agar aplikasi tidak kosong
    _rooms = List.from(masterRoomsData);
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  static final RoomRepository instance = RoomRepository._internal();

  List<RoomModel> _rooms = [];
  final ValueNotifier<List<RoomModel>> roomsNotifier = ValueNotifier<List<RoomModel>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  List<RoomModel> get rooms => _rooms;

  List<RoomModel> getRoomsByFloor(int floor) {
    return _rooms.where((r) => r.floor == floor).toList();
  }

  RoomModel? findByCode(String code) {
    try {
      return _rooms.firstWhere((r) => r.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Memuat data ruangan dari Supabase. Jika belum terhubung, fallback ke data bawaan.
  Future<void> fetchRooms() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) {
      debugPrint('[RoomRepository] Supabase belum aktif. Menggunakan data statis bawaan.');
      return;
    }

    isLoadingNotifier.value = true;
    try {
      final response = await supabase.client!
          .from('rooms')
          .select()
          .order('floor', ascending: true)
          .order('code', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        _rooms = data.map((item) => RoomModel.fromMap(item as Map<String, dynamic>)).toList();
        roomsNotifier.value = List.unmodifiable(_rooms);
        debugPrint('[RoomRepository] Berhasil memuat ${_rooms.length} ruangan dari Supabase.');
      } else {
        debugPrint('[RoomRepository] Tabel rooms kosong di Supabase. Masih menggunakan data bawaan.');
      }
    } catch (e) {
      debugPrint('[RoomRepository] Gagal memuat data dari Supabase: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Tambah ruangan baru
  Future<void> addRoom(RoomModel room) async {
    final supabase = SupabaseService.instance;
    if (supabase.isReady && supabase.client != null) {
      final res = await supabase.client!
          .from('rooms')
          .insert(room.toMap())
          .select()
          .single();
      final newRoom = RoomModel.fromMap(res);
      _rooms.add(newRoom);
    } else {
      // Mode lokal / demo jika belum ada koneksi Supabase
      _rooms.add(room);
    }
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  /// Update data ruangan yang sudah ada
  Future<void> updateRoom(RoomModel room) async {
    final supabase = SupabaseService.instance;
    if (supabase.isReady && supabase.client != null) {
      await supabase.client!
          .from('rooms')
          .upsert(room.toMap(), onConflict: 'code');
    }

    final index = _rooms.indexWhere((r) => r.code == room.code);
    if (index != -1) {
      _rooms[index] = room;
    } else {
      _rooms.add(room);
    }
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  /// Hapus ruangan
  Future<void> deleteRoom(String code) async {
    final supabase = SupabaseService.instance;
    if (supabase.isReady && supabase.client != null) {
      await supabase.client!.from('rooms').delete().eq('code', code);
    }

    _rooms.removeWhere((r) => r.code == code);
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  /// Migrasi Otomatis (Seed): Mengunggah seluruh data awal di room_data.dart ke tabel rooms di Supabase
  Future<int> seedInitialData() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) {
      throw Exception('Supabase belum aktif. Pastikan URL dan Anon Key sudah benar.');
    }

    isLoadingNotifier.value = true;
    int insertedCount = 0;
    try {
      // Ambil data yang saat ini sudah ada di Supabase untuk menjaga foto yang sudah diunggah
      final response = await supabase.client!.from('rooms').select('code, images');
      final Map<String, List<String>> existingPhotosMap = {};
      for (final item in (response as List)) {
        if (item is Map<String, dynamic> && item['code'] != null) {
          final imgs = (item['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
          if (imgs.isNotEmpty) {
            existingPhotosMap[item['code'].toString()] = imgs;
          }
        }
      }

      final rowsToInsert = masterRoomsData.map((room) {
        final existingImgs = existingPhotosMap[room.code];
        if (existingImgs != null && existingImgs.isNotEmpty) {
          // Pertahankan foto yang sudah diunggah pengguna!
          return room.copyWith(images: existingImgs).toMap();
        }
        return room.toMap();
      }).toList();
      
      // Upsert berdasarkan 'code' agar tidak menduplikasi
      await supabase.client!
          .from('rooms')
          .upsert(rowsToInsert, onConflict: 'code');

      insertedCount = rowsToInsert.length;
      await fetchRooms();
      return insertedCount;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Upload foto ruangan ke Supabase Storage (bucket: 'room-photos')
  Future<String?> uploadRoomPhoto({
    required String roomCode,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) {
      throw Exception('Supabase belum aktif untuk upload gambar.');
    }

    final sanitizedCode = roomCode.replaceAll('.', '_');
    final filePath = 'rooms/${sanitizedCode}_$fileName';

    await supabase.client!.storage.from('room-photos').uploadBinary(
      filePath,
      fileBytes,
    );

    final publicUrl = supabase.client!.storage.from('room-photos').getPublicUrl(filePath);
    return publicUrl;
  }
}

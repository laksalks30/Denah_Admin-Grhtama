import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import 'supabase_service.dart';

class RoomRepository {
  RoomRepository._internal();
  static final RoomRepository instance = RoomRepository._internal();

  List<RoomModel> _rooms = [];
  final ValueNotifier<List<RoomModel>> roomsNotifier =
      ValueNotifier<List<RoomModel>>([]);

  List<RoomModel> get rooms => _rooms;

  List<RoomModel> getRoomsByFloor(int floor) =>
      _rooms.where((r) => r.floor == floor).toList();

  RoomModel? findByCode(String code) {
    try {
      return _rooms.firstWhere((r) => r.code == code);
    } catch (_) {
      return null;
    }
  }

  SupabaseService get _supabase => SupabaseService.instance;

  /// Muat semua ruangan dari Supabase
  Future<void> fetchRooms() async {
    if (!_supabase.isReady || _supabase.client == null) {
      debugPrint('[RoomRepository] Supabase belum aktif.');
      return;
    }
    try {
      final response = await _supabase.client!
          .from('rooms')
          .select()
          .order('floor', ascending: true)
          .order('code', ascending: true);

      _rooms = (response as List<dynamic>)
          .map((item) => RoomModel.fromMap(item as Map<String, dynamic>))
          .toList();
      roomsNotifier.value = List.unmodifiable(_rooms);
      debugPrint('[RoomRepository] ${_rooms.length} ruangan dimuat dari Supabase.');
    } catch (e) {
      debugPrint('[RoomRepository] Gagal fetch: $e');
    }
  }

  /// Tambah ruangan baru
  Future<void> addRoom(RoomModel room) async {
    final res = await _supabase.client!
        .from('rooms')
        .insert(room.toMap())
        .select()
        .single();
    _rooms.add(RoomModel.fromMap(res));
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  /// Update ruangan — pakai id kalau ada, fallback upsert by code
  Future<void> updateRoom(RoomModel room) async {
    if (room.id != null) {
      // Update by primary key — aman meski kode diubah
      await _supabase.client!
          .from('rooms')
          .update(room.toUpdateMap())
          .eq('id', room.id!);
    } else {
      await _supabase.client!
          .from('rooms')
          .upsert(room.toMap(), onConflict: 'code');
    }

    final idx = _rooms.indexWhere((r) => r.code == room.code || r.id == room.id);
    if (idx != -1) {
      _rooms[idx] = room;
    } else {
      _rooms.add(room);
    }
    roomsNotifier.value = List.unmodifiable(_rooms);
  }

  /// Hapus ruangan
  Future<void> deleteRoom(String code) async {
    await _supabase.client!.from('rooms').delete().eq('code', code);
    _rooms.removeWhere((r) => r.code == code);
    roomsNotifier.value = List.unmodifiable(_rooms);
  }
}

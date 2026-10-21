import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/room_model.dart';
import '../../services/room_repository.dart';
import '../../services/supabase_service.dart';
import '../../utils/floor_label.dart';
import 'admin_login_screen.dart';
import 'room_form_screen.dart';
import 'visual_pin_picker_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  int _selectedFloorFilter = 0; // 0 = Semua, 1 = Dasar, 2 = Lt. 1, 3 = Lt. 2
  RoomCategory? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.instance.signOut();
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          );
        }
      }
    }
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text('Yakin ingin menghapus ruangan "${room.code} - ${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RoomRepository.instance.deleteRoom(room.code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ruangan ${room.code} berhasil dihapus'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _quickAdjustPin(RoomModel room) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => VisualPinPickerScreen(
          initialFloor: room.floor,
          initialX: room.xRatio,
          initialY: room.yRatio,
          roomCode: room.code,
          roomName: room.name,
          category: room.category,
        ),
      ),
    );

    if (result != null) {
      final updated = room.copyWith(
        xRatio: result['xRatio'] as double,
        yRatio: result['yRatio'] as double,
        floor: result['floor'] as int,
      );
      await RoomRepository.instance.updateRoom(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posisi pin ${room.code} berhasil diperbarui!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = SupabaseService.instance.isAuthenticated;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SupabaseService.instance.signOut();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            MediaQuery.of(context).size.width < 500 ? 'Admin Denah' : 'Dashboard Manajemen Denah',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Keluar & Kembali',
            onPressed: _logout,
          ),
          actions: [
            // Indikator Status Koneksi
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade800 : Colors.amber.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    size: 13,
                    color: Colors.white,
                  ),
                  if (MediaQuery.of(context).size.width >= 420) ...[
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),

            IconButton(
              tooltip: 'Refresh Data',
              icon: const Icon(Icons.refresh),
              onPressed: () => RoomRepository.instance.fetchRooms(),
            ),

            IconButton(
              tooltip: 'Keluar Admin',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ValueListenableBuilder<List<RoomModel>>(
        valueListenable: RoomRepository.instance.roomsNotifier,
        builder: (context, allRooms, _) {
          // Filter data berdasarkan search, lantai, dan kategori
          final query = _searchController.text.trim().toLowerCase();
          final filteredRooms = allRooms.where((r) {
            final matchesQuery = query.isEmpty ||
                r.name.toLowerCase().contains(query) ||
                r.code.toLowerCase().contains(query) ||
                r.desc.toLowerCase().contains(query);
            final matchesFloor = _selectedFloorFilter == 0 || r.floor == _selectedFloorFilter;
            final matchesCategory = _selectedCategoryFilter == null || r.category == _selectedCategoryFilter;
            return matchesQuery && matchesFloor && matchesCategory;
          }).toList()
            ..sort((a, b) {
              final pa = a.code.split('.');
              final pb = b.code.split('.');
              final fa = int.tryParse(pa[0]) ?? 0;
              final fb = int.tryParse(pb[0]) ?? 0;
              if (fa != fb) return fa.compareTo(fb);
              final sa = pa.length > 1 ? (int.tryParse(pa[1]) ?? 0) : 0;
              final sb = pb.length > 1 ? (int.tryParse(pb[1]) ?? 0) : 0;
              return sa.compareTo(sb);
            });

          return Column(
            children: [
              // Panel Statistik & Tombol Aksi Cepat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Chips & Tombol Aksi (Horizontally scrollable on mobile)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatChip('Total', allRooms.length.toString(), Colors.blueGrey),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            'Dasar',
                            allRooms.where((r) => r.floor == 1).length.toString(),
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            'Lt. 1',
                            allRooms.where((r) => r.floor == 2).length.toString(),
                            Colors.indigo,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            'Lt. 2',
                            allRooms.where((r) => r.floor == 3).length.toString(),
                            Colors.purple,
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RoomFormScreen()),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Ruangan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Bar: Search + Lantai + Kategori (Responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 650;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Search input full width
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Cari nama, kode, deskripsi...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () => setState(() => _searchController.clear()),
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              // Dua Dropdown berdampingan
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedFloorFilter,
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(value: 0, child: Text('Semua Lantai', style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(value: 1, child: Text('Lantai Dasar', style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(value: 2, child: Text('Lantai 1', style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(value: 3, child: Text('Lantai 2', style: TextStyle(fontSize: 13))),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedFloorFilter = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<RoomCategory?>(
                                          value: _selectedCategoryFilter,
                                          isExpanded: true,
                                          hint: const Text('Semua Kategori', style: TextStyle(fontSize: 13)),
                                          items: [
                                            const DropdownMenuItem(value: null, child: Text('Semua Kategori', style: TextStyle(fontSize: 13))),
                                            ...RoomCategory.values.map(
                                              (c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(RoomColors.labelFromCategory(c), style: const TextStyle(fontSize: 13)),
                                              ),
                                            ),
                                          ],
                                          onChanged: (val) => setState(() => _selectedCategoryFilter = val),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        // Desktop: 1 baris
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Cari berdasarkan nama, kode, atau deskripsi...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () => setState(() => _searchController.clear()),
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: _selectedFloorFilter,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Semua Lantai')),
                                DropdownMenuItem(value: 1, child: Text('Lantai Dasar')),
                                DropdownMenuItem(value: 2, child: Text('Lantai 1')),
                                DropdownMenuItem(value: 3, child: Text('Lantai 2')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFloorFilter = val);
                              },
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<RoomCategory?>(
                              value: _selectedCategoryFilter,
                              hint: const Text('Semua Kategori'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                                ...RoomCategory.values.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(RoomColors.labelFromCategory(c)),
                                  ),
                                ),
                              ],
                              onChanged: (val) => setState(() => _selectedCategoryFilter = val),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Daftar Ruangan
              Expanded(
                child: filteredRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada ruangan yang cocok',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRooms.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final room = filteredRooms[index];
                          return Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris Atas: Lingkaran Kode + Nama + Kategori Badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Lingkaran Kode Ruangan
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: room.color,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: room.color.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            room.code,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Nama Ruangan & Badges
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              room.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: room.color.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    RoomColors.labelFromCategory(room.category),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: room.color,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    floorLabelFull(room.floor),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? Colors.white70 : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                if (room.images.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.photo_library, size: 12, color: Colors.blue),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${room.images.length} foto',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.blue,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 6),

                                  // Baris Bawah: Info Koordinat Pin & Tombol Aksi
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: isDark ? Colors.white54 : Colors.black45,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Pin: (${room.xRatio.toStringAsFixed(3)}, ${room.yRatio.toStringAsFixed(3)})',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white54 : Colors.black45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tombol Quick Visual Pin Picker
                                      IconButton(
                                        tooltip: 'Atur Posisi Pin di Denah',
                                        icon: const Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 20),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _quickAdjustPin(room),
                                      ),

                                      // Tombol Edit
                                      IconButton(
                                        tooltip: 'Edit Data Ruangan',
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RoomFormScreen(initialRoom: room),
                                            ),
                                          );
                                        },
                                      ),

                                      // Tombol Hapus
                                      IconButton(
                                        tooltip: 'Hapus Ruangan',
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _deleteRoom(room),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Ruangan Baru',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoomFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    ),
  );
}

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

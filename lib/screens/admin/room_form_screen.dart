import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/room_model.dart';
import '../../services/room_repository.dart';
import '../../utils/floor_label.dart';
import 'visual_pin_picker_screen.dart';

class RoomFormScreen extends StatefulWidget {
  final RoomModel? initialRoom;

  const RoomFormScreen({super.key, this.initialRoom});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;

  late int _floor;
  late double _xRatio;
  late double _yRatio;
  late RoomCategory _category;
  late List<String> _images;
  bool _isLoading = false;

  bool get isEditing => widget.initialRoom != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoom;
    _codeController = TextEditingController(text: r?.code ?? '');
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.desc ?? '');
    _imageUrlController = TextEditingController();

    _floor = r?.floor ?? 1;
    _xRatio = r?.xRatio ?? 0.5;
    _yRatio = r?.yRatio ?? 0.5;
    _category = r?.category ?? RoomCategory.koleksi;
    _images = List.from(r?.images ?? []);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _openPinPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => VisualPinPickerScreen(
          initialFloor: _floor,
          initialX: _xRatio,
          initialY: _yRatio,
          roomCode: _codeController.text.trim(),
          roomName: _nameController.text.trim(),
          category: _category,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _xRatio = result['xRatio'] as double;
        _yRatio = result['yRatio'] as double;
        _floor = result['floor'] as int;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Posisi pin diperbarui: Lantai ${floorLabelFull(_floor)} ($_xRatio, $_yRatio)',
          ),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final room = RoomModel(
        id: widget.initialRoom?.id,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        floor: _floor,
        xRatio: _xRatio,
        yRatio: _yRatio,
        category: _category,
        desc: _descController.text.trim(),
        images: _images,
      );

      if (isEditing) {
        await RoomRepository.instance.updateRoom(room);
      } else {
        await RoomRepository.instance.addRoom(room);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Ruangan berhasil diperbarui' : 'Ruangan baru berhasil ditambahkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _images.add(url);
        _imageUrlController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Ruangan (${widget.initialRoom!.code})' : 'Tambah Ruangan Baru'),
        actions: [
          IconButton(
            tooltip: 'Simpan',
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Informasi Dasar
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Ruangan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Kode Ruangan
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _codeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Kode Ruangan *',
                                    hintText: 'Contoh: 1.15 atau 2.4',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.tag),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Pilihan Lantai
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _floor,
                                  decoration: const InputDecoration(
                                    labelText: 'Lantai *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.layers_outlined),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('Lantai Dasar')),
                                    DropdownMenuItem(value: 2, child: Text('Lantai 1')),
                                    DropdownMenuItem(value: 3, child: Text('Lantai 2')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _floor = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Nama Ruangan
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Ruangan *',
                              hintText: 'Contoh: Ruang Koleksi Anak',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.meeting_room_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Kategori Ruangan
                          DropdownButtonFormField<RoomCategory>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Kategori Ruangan *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: RoomCategory.values.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: RoomColors.fromCategory(cat),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(RoomColors.labelFromCategory(cat)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Deskripsi
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi / Layanan Ruangan',
                              hintText: 'Jelaskan fasilitas, jam layanan, atau peruntukan ruangan ini...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card Koordinat & Visual Pin Picker
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Posisi Pin di Denah Peta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RoomColors.fromCategory(_category).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'xRatio: ${_xRatio.toStringAsFixed(3)} | yRatio: ${_yRatio.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: RoomColors.fromCategory(_category),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tentukan letak pin ruangan secara presisi di atas gambar denah lantai ${floorLabelFull(_floor)}.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Buka Visual Pin Picker
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openPinPicker,
                              icon: const Icon(Icons.pin_drop),
                              label: const Text('Buka Peta & Tentukan Posisi Pin (Visual Picker)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card Foto / Gambar Ruangan
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto / Galeri Ruangan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'URL Foto (atau path aset)',
                                    hintText: 'https://... atau assets/images/rooms/...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _addImageUrl,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                          if (_images.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _images.asMap().entries.map((entry) {
                                final index = entry.key;
                                final img = entry.value;
                                return Chip(
                                  avatar: const Icon(Icons.image, size: 16),
                                  label: Text(
                                    img.length > 25 ? '${img.substring(0, 22)}...' : img,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onDeleted: () {
                                    setState(() => _images.removeAt(index));
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Aksi Simpan
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambahkan Ruangan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

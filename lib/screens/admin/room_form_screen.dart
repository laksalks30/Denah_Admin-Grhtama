import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/room_model.dart';
import '../../services/room_repository.dart';
import '../../services/storage_service.dart';
import '../../utils/floor_label.dart';
import '../../utils/image_url_resolver.dart';
import '../../widgets/app_image_view.dart';
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
  late List<RoomScheduleItem> _schedule;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _uploadStatusText;

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
    _images   = List.from(r?.images   ?? []);
    _schedule = List.from(r?.schedule ?? []);
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

  Future<void> _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green.shade700 : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isSuccess ? 'Lanjut' : 'Tutup'),
          ),
        ],
      ),
    );
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
        schedule: _schedule,
      );

      if (isEditing) {
        await RoomRepository.instance.updateRoom(room);
      } else {
        await RoomRepository.instance.addRoom(room);
      }

      if (mounted) {
        await _showResultDialog(
          isSuccess: true,
          title: isEditing ? 'Berhasil Diperbarui' : 'Berhasil Ditambahkan',
          message: isEditing
              ? 'Data ruangan "${room.code} - ${room.name}" berhasil diperbarui ke Supabase.'
              : 'Ruangan baru "${room.code} - ${room.name}" berhasil disimpan ke Supabase.',
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String title = 'Gagal Menyimpan';
        String msg = e.toString();
        if (msg.contains('rooms_code_key') ||
            msg.contains('23505') ||
            msg.contains('duplicate key')) {
          title = 'Kode Ruangan Sudah Ada';
          final existing =
              RoomRepository.instance.findByCode(_codeController.text.trim());
          final existingName =
              existing != null ? ' ("${existing.name}")' : '';
          msg =
              'Kode ruangan "${_codeController.text.trim()}"$existingName sudah terdaftar di database.\n\nSilakan gunakan kode ruangan lain atau edit ruangan tersebut langsung dari daftar dashboard.';
        } else {
          msg = 'Terjadi kendala saat menyimpan ke database:\n$msg';
        }

        await _showResultDialog(
          isSuccess: false,
          title: title,
          message: msg,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addImageUrl() {
    final rawUrl = _imageUrlController.text.trim();
    if (rawUrl.isNotEmpty) {
      final url = resolveImageUrl(rawUrl);
      setState(() {
        _images.add(url);
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final pickedList = await StorageService.instance.pickImagesFromStorage(allowMultiple: true);
      if (pickedList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada gambar yang dipilih.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingImage = true;
        _uploadStatusText = 'Menyiapkan ${pickedList.length} foto...';
      });

      int successCount = 0;
      for (int i = 0; i < pickedList.length; i++) {
        final item = pickedList[i];
        if (!mounted) break;
        setState(() {
          _uploadStatusText = 'Menyimpan foto (${i + 1}/${pickedList.length})...';
        });

        final imageUri = await StorageService.instance.uploadImageBytes(
          bytes: item.bytes,
          originalFileName: item.name,
          roomCode: _codeController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _images.add(imageUri);
          });
        }
        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menambahkan $successCount foto.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[RoomFormScreen] Upload error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan foto: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadStatusText = null;
        });
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final item = await StorageService.instance.pickImageFromCamera();
      if (item == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengambilan foto dibatalkan.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingImage = true;
        _uploadStatusText = 'Menyimpan foto kamera...';
      });

      final imageUri = await StorageService.instance.uploadImageBytes(
        bytes: item.bytes,
        originalFileName: item.name,
        roomCode: _codeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _images.add(imageUri);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto kamera berhasil ditambahkan.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[RoomFormScreen] Camera upload error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadStatusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Ruangan (${widget.initialRoom!.code})' : 'Tambah Ruangan Baru',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = constraints.maxWidth < 450;
                              if (isSmall) {
                                return Column(
                                  children: [
                                    TextFormField(
                                      controller: _codeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Kode Ruangan *',
                                        hintText: 'Contoh: 1.15 atau 2.4',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.tag),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Wajib diisi';
                                        }
                                        final trimmed = v.trim();
                                        if (!isEditing) {
                                          final existing = RoomRepository.instance.findByCode(trimmed);
                                          if (existing != null) {
                                            return 'Kode "$trimmed" sudah ada (${existing.name})';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<int>(
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
                                  ],
                                );
                              }
                              return Row(
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
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Wajib diisi';
                                        }
                                        final trimmed = v.trim();
                                        if (!isEditing) {
                                          final existing = RoomRepository.instance.findByCode(trimmed);
                                          if (existing != null) {
                                            return 'Kode "$trimmed" sudah ada (${existing.name})';
                                          }
                                        }
                                        return null;
                                      },
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
                              );
                            },
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
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
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
                              label: const Text(
                                'Buka Peta & Tentukan Posisi Pin (Visual Picker)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
                          const SizedBox(height: 4),
                          Text(
                            'Unggah foto langsung dari Galeri HP / Folder PC ke Supabase Storage, atau masukkan link manual.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Upload dari Galeri / Folder & Kamera
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isUploadingImage ? null : _pickAndUploadImages,
                                icon: _isUploadingImage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.photo_library_rounded, size: 20),
                                label: Text(
                                  _isUploadingImage
                                      ? (_uploadStatusText ?? 'Mengunggah...')
                                      : 'Pilih dari Galeri / Folder',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isUploadingImage ? null : _pickFromCamera,
                                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                                label: const Text('Ambil dari Kamera'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),

                          if (_isUploadingImage) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _uploadStatusText ?? 'Sedang mengunggah foto...',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'atau masukkan link manual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 360;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _imageUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'URL Foto atau Path Aset',
                                        hintText: 'Link Google Drive / Unsplash / URL foto...',
                                        helperText: 'Mendukung Google Drive (pastikan akses diset "Siapa saja yang memiliki link")',
                                        helperMaxLines: 2,
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _addImageUrl(),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addImageUrl,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tambah URL'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _imageUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'URL Foto atau Path Aset',
                                        hintText: 'Link Google Drive / Unsplash / URL foto...',
                                        helperText: 'Mendukung Google Drive (pastikan akses diset "Siapa saja yang memiliki link")',
                                        helperMaxLines: 2,
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _addImageUrl(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: ElevatedButton.icon(
                                      onPressed: _addImageUrl,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tambah'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_images.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _images.asMap().entries.map((entry) {
                                final index = entry.key;
                                final img = entry.value;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 100,
                                        height: 80,
                                        color: isDark ? Colors.white10 : Colors.black12,
                                        child: AppImageView(
                                          imagePath: img,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 80,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _images.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Card Jadwal ────────────────────────────────────────
                  _ScheduleCard(
                    schedule: _schedule,
                    isDark: isDark,
                    roomColor: RoomColors.fromCategory(_category),
                    onChanged: (updated) => setState(() => _schedule = updated),
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

// ── Card Kelola Jadwal (Admin) ────────────────────────────────────────────────
class _ScheduleCard extends StatefulWidget {
  final List<RoomScheduleItem> schedule;
  final bool isDark;
  final Color roomColor;
  final ValueChanged<List<RoomScheduleItem>> onChanged;

  const _ScheduleCard({
    required this.schedule,
    required this.isDark,
    required this.roomColor,
    required this.onChanged,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  void _addItem() async {
    final result = await showDialog<RoomScheduleItem>(
      context: context,
      builder: (_) => const _ScheduleItemDialog(),
    );
    if (result != null) {
      widget.onChanged([...widget.schedule, result]);
    }
  }

  void _editItem(int index) async {
    final result = await showDialog<RoomScheduleItem>(
      context: context,
      builder: (_) => _ScheduleItemDialog(initial: widget.schedule[index]),
    );
    if (result != null) {
      final updated = List<RoomScheduleItem>.from(widget.schedule);
      updated[index] = result;
      widget.onChanged(updated);
    }
  }

  void _deleteItem(int index) {
    final updated = List<RoomScheduleItem>.from(widget.schedule)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = widget.isDark;
    final color       = widget.roomColor;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSec     = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Jadwal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tambahkan jadwal sesi atau kegiatan ruangan ini.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.schedule.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.schedule_outlined, size: 32, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada jadwal',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header tabel
                    Container(
                      color: color.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text('Hari',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text('Jam',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                          Expanded(
                            child: Text('Keterangan',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                          const SizedBox(width: 56), // aksi
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Baris data
                    ...widget.schedule.asMap().entries.map((e) {
                      final i    = e.key;
                      final item = e.value;
                      final rowBg = i.isEven
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.015))
                          : Colors.transparent;

                      return Container(
                        color: rowBg,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(item.hari,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary)),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(item.jam,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ),
                            Expanded(
                              child: Text(item.keterangan,
                                  style: TextStyle(fontSize: 12, color: textSec)),
                            ),
                            // Tombol edit & hapus
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined, size: 17),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _editItem(i),
                                ),
                                IconButton(
                                  tooltip: 'Hapus',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 17, color: Colors.red),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _deleteItem(i),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog tambah / edit satu baris jadwal ────────────────────────────────────
class _ScheduleItemDialog extends StatefulWidget {
  final RoomScheduleItem? initial;
  const _ScheduleItemDialog({this.initial});

  @override
  State<_ScheduleItemDialog> createState() => _ScheduleItemDialogState();
}

class _ScheduleItemDialogState extends State<_ScheduleItemDialog> {
  late TextEditingController _hariCtrl;
  late TextEditingController _jamCtrl;
  late TextEditingController _ketCtrl;
  final _formKey = GlobalKey<FormState>();

  // Pilihan hari cepat
  static const _hariOptions = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    'Senin – Jumat', 'Senin – Sabtu', 'Selasa – Kamis', 'Selasa – Sabtu',
  ];

  @override
  void initState() {
    super.initState();
    _hariCtrl = TextEditingController(text: widget.initial?.hari ?? '');
    _jamCtrl  = TextEditingController(text: widget.initial?.jam  ?? '');
    _ketCtrl  = TextEditingController(text: widget.initial?.keterangan ?? '');
  }

  @override
  void dispose() {
    _hariCtrl.dispose();
    _jamCtrl.dispose();
    _ketCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(RoomScheduleItem(
      hari: _hariCtrl.text.trim(),
      jam:  _jamCtrl.text.trim(),
      keterangan: _ketCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hari — bisa pilih dari chip atau ketik bebas
            TextFormField(
              controller: _hariCtrl,
              decoration: const InputDecoration(
                labelText: 'Hari *',
                hintText: 'Senin / Senin – Jumat / dst.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            // Chip pilihan hari cepat
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _hariOptions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final h = _hariOptions[i];
                  return ActionChip(
                    label: Text(h, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _hariCtrl.text = h),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Jam
            TextFormField(
              controller: _jamCtrl,
              decoration: const InputDecoration(
                labelText: 'Jam *',
                hintText: '09.00 / 10.00 – 11.30 WIB',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            // Keterangan
            TextFormField(
              controller: _ketCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Nama film, kegiatan, atau info tambahan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(isEdit ? 'Simpan' : 'Tambahkan'),
        ),
      ],
    );
  }
}

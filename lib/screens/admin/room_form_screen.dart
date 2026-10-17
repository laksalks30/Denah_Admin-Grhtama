import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../main.dart';
import '../../models/room_model.dart';
import '../../services/room_repository.dart';
import '../../services/storage_service.dart';
import '../../utils/floor_label.dart';
import '../../utils/image_url_resolver.dart';
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
      final images = await StorageService.instance.pickMultiImages();
      if (images.isEmpty) return;

      setState(() {
        _isUploadingImage = true;
        _uploadStatusText = 'Mempersiapkan ${images.length} foto...';
      });

      int successCount = 0;
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        if (!mounted) break;
        setState(() {
          _uploadStatusText = 'Mengunggah (${i + 1}/${images.length})...';
        });

        final bytes = await img.readAsBytes();
        final publicUrl = await StorageService.instance.uploadImageBytes(
          bytes: bytes,
          originalFileName: img.name,
          roomCode: _codeController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _images.add(publicUrl);
          });
        }
        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunggah $successCount foto ke Supabase Storage.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('[RoomFormScreen] Upload error: $e');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('BUCKET_NOT_FOUND')) {
        _showBucketInstructionDialog();
      } else if (msg.contains('STORAGE_RLS_RESTRICTED')) {
        _showStorageRlsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
      final img = await StorageService.instance.pickImageFromCamera();
      if (img == null) return;

      setState(() {
        _isUploadingImage = true;
        _uploadStatusText = 'Mengunggah foto kamera...';
      });

      final bytes = await img.readAsBytes();
      final publicUrl = await StorageService.instance.uploadImageBytes(
        bytes: bytes,
        originalFileName: img.name,
        roomCode: _codeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _images.add(publicUrl);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto kamera berhasil diunggah.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('[RoomFormScreen] Camera upload error: $e');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('BUCKET_NOT_FOUND')) {
        _showBucketInstructionDialog();
      } else if (msg.contains('STORAGE_RLS_RESTRICTED')) {
        _showStorageRlsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil/mengunggah foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadStatusText = null;
        });
      }
    }
  }

  void _showBucketInstructionDialog() {
    const sqlScript = '''-- 1. Buat bucket room-images
INSERT INTO storage.buckets (id, name, public)
VALUES ('room-images', 'room-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Kebijakan akses upload & baca untuk publik
CREATE POLICY "Allow public all" ON storage.objects
FOR ALL TO public
USING (bucket_id = 'room-images')
WITH CHECK (bucket_id = 'room-images');''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bucket Storage Belum Siap',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supabase Storage membutuhkan bucket bernama "room-images" agar foto dari galeri atau folder dapat disimpan.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cara Mengaktifkan (1 Menit):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                '1. Buka Supabase Dashboard > SQL Editor\n2. Tempel dan jalankan script SQL berikut:',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: const SelectableText(
                  sqlScript,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Script SQL'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sqlScript));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Script SQL disalin! Jalankan di SQL Editor Supabase Anda.'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showStorageRlsDialog() {
    const sqlScript = '''-- Berikan izin upload dan baca ke storage.objects
CREATE POLICY "Allow public all" ON storage.objects
FOR ALL TO public
USING (bucket_id = 'room-images')
WITH CHECK (bucket_id = 'room-images');''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Izin Upload Ditolak (RLS)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supabase Storage memblokir upload karena Row-Level Security (RLS) pada storage.objects belum mengizinkan upload publik.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Solusi: Jalankan SQL ini di SQL Editor Supabase:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: const SelectableText(
                  sqlScript,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin SQL'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sqlScript));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Script SQL disalin! Jalankan di SQL Editor Supabase.'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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

                          Row(
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
                              ElevatedButton.icon(
                                onPressed: _addImageUrl,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                          if (_images.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _images.asMap().entries.map((entry) {
                                final index = entry.key;
                                final img = entry.value;
                                final resolved = resolveImageUrl(img);
                                final isNetwork = resolved.startsWith('http') || resolved.startsWith('blob:');
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 100,
                                        height: 80,
                                        color: isDark ? Colors.white10 : Colors.black12,
                                        child: isNetwork
                                            ? Image.network(
                                                resolved,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (ctx, err, _) {
                                                  debugPrint('[RoomFormScreen] Gagal memuat $resolved: $err');
                                                  return const Center(
                                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                resolved,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Center(
                                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                                ),
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

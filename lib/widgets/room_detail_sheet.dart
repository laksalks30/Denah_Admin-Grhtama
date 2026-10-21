import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../utils/floor_label.dart';
import 'app_image_view.dart';

/// Bottom sheet detail ruangan ala Google Maps.
/// [onShowOnMap] dipanggil ketika tombol "Lihat di Peta" ditekan.
class RoomDetailSheet extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onShowOnMap;

  const RoomDetailSheet({
    super.key,
    required this.room,
    this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSec = isDark ? Colors.white60 : Colors.black54;
    final divider = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.07);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 2),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white24
                  : Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Konten scroll ────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: room.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            room.code,
                            style: TextStyle(
                              color: room.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _CategoryBadge(room: room),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(color: divider),
                  const SizedBox(height: 14),

                  // Foto slot
                  _PhotoSection(room: room, isDark: isDark),

                  const SizedBox(height: 18),

                  // Deskripsi
                  Text(
                    'Tentang Ruangan',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.desc,
                    style: TextStyle(
                      color: textSec,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.layers_rounded,
                        label: floorLabelFull(room.floor),
                        isDark: isDark,
                      ),
                      _InfoChip(
                        icon: Icons.door_front_door_outlined,
                        label: 'Kode ${room.code}',
                        color: room.color,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  // ── Jadwal ──────────────────────────────────────────────
                  if (room.schedule.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: divider),
                    const SizedBox(height: 14),
                    _ScheduleSection(room: room, isDark: isDark),
                  ],

                  // Tombol "Lihat di Peta" — hanya tampil kalau callback ada
                  if (onShowOnMap != null) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: room.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onShowOnMap!();
                        },
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text(
                          'Lihat di Peta',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category badge ────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final RoomModel room;
  const _CategoryBadge({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: room.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: room.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: room.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            RoomColors.labelFromCategory(room.category),
            style: TextStyle(
              color: room.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Foto section ──────────────────────────────────────────────────────────────
// ── Foto section (Interactive Carousel Slider) ──────────────────────────────
class _PhotoSection extends StatefulWidget {
  final RoomModel room;
  final bool isDark;
  const _PhotoSection({required this.room, required this.isDark});

  @override
  State<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<_PhotoSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) => _PhotoViewerPage(
          images: widget.room.images,
          initialIndex: initialIndex,
          roomName: widget.room.name,
        ),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.room.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.room.images;
    final total = images.length;

    if (total == 0) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: widget.isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 6),
            Text(
              'Foto belum tersedia',
              style: TextStyle(
                color: widget.isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris Header Foto
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Foto Ruangan',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.room.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total foto',
                    style: TextStyle(
                      color: widget.room.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (total > 1)
              Flexible(
                child: Text(
                  'Geser untuk foto lain',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Slider Container
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. PageView Slider Utama (Mendukung Geser / Swipe HP & Drag)
                PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _openViewer(i),
                    child: Hero(
                      tag: 'photo_${widget.room.code}_$i',
                      child: AppImageView(
                        imagePath: images[i],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: double.infinity,
                          height: 220,
                          color: widget.isDark ? Colors.white10 : Colors.black12,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          width: double.infinity,
                          height: 220,
                          color: widget.isDark ? Colors.white10 : Colors.black12,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.white38, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Gradient Overlay di bawah agar indikator terlihat kontras
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Counter Badge (Pojok Kanan Atas)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_back_outlined,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentIndex + 1} / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Tombol Layar Penuh (Pojok Kiri Atas)
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () => _openViewer(_currentIndex),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // 5. Tombol Panah Kiri (<) untuk PC & HP
                if (total > 1 && _currentIndex > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _previousPage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 6. Tombol Panah Kanan (>) untuk PC & HP
                if (total > 1 && _currentIndex < total - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 7. Dot Indicators di Tengah Bawah
                if (total > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final active = i == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                if (active)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 2,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Full screen photo viewer ──────────────────────────────────────────────────
class _PhotoViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String roomName;

  const _PhotoViewerPage({
    required this.images,
    required this.initialIndex,
    required this.roomName,
  });

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView foto ──────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => _ZoomablePage(
              imagePath: widget.images[i],
              heroTag: 'photo_${widget.roomName}_$i',
            ),
          ),

          // ── Tombol tutup ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── Counter foto (X / N) ───────────────────────────────────────
          if (total > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),


          // ── Tombol Navigasi Kiri (<) ──
          if (total > 1 && _current > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),

          // ── Tombol Navigasi Kanan (>) ──
          if (total > 1 && _current < total - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),

          // ── Dot indicator & Nama Ruangan di Bawah ──────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (total > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  widget.roomName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single zoomable photo page ────────────────────────────────────────────────
class _ZoomablePage extends StatefulWidget {
  final String imagePath;
  final String heroTag;

  const _ZoomablePage({required this.imagePath, required this.heroTag});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _ctrl = TransformationController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Double tap untuk reset zoom
      onDoubleTap: () {
        if (_ctrl.value != Matrix4.identity()) {
          _ctrl.value = Matrix4.identity();
        } else {
          // Zoom in 2.5x ke tengah
          final m = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
          _ctrl.value = m;
        }
      },
      child: InteractiveViewer(
        transformationController: _ctrl,
        minScale: 0.8,
        maxScale: 5.0,
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            child: AppImageView(
                imagePath: widget.imagePath,
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white30, size: 48),
                ),
              ),
          ),
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white54 : Colors.black54);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jadwal section (publik) ───────────────────────────────────────────────────
class _ScheduleSection extends StatelessWidget {
  final RoomModel room;
  final bool isDark;

  const _ScheduleSection({required this.room, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSec     = isDark ? Colors.white60 : Colors.black54;
    final headerBg    = room.color.withValues(alpha: 0.1);
    final rowEven     = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.02);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: room.color),
            const SizedBox(width: 8),
            Text(
              'Jadwal',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: room.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${room.schedule.length} sesi',
                style: TextStyle(
                  color: room.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabel jadwal
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header tabel
              Container(
                color: headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        'Hari',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: room.color,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      child: Text(
                        'Jam',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: room.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Keterangan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: room.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Baris jadwal
              ...room.schedule.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                return Container(
                  color: i.isEven ? rowEven : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(
                          item.hari,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 54,
                        child: Text(
                          item.jam,
                          style: TextStyle(
                            fontSize: 12,
                            color: room.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.keterangan,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSec,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

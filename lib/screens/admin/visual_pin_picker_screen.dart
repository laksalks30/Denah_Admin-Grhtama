import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/room_model.dart';
import '../../services/room_repository.dart';
import '../../utils/floor_label.dart';

class VisualPinPickerScreen extends StatefulWidget {
  final int initialFloor;
  final double initialX;
  final double initialY;
  final String roomCode;
  final String roomName;
  final RoomCategory category;

  const VisualPinPickerScreen({
    super.key,
    required this.initialFloor,
    required this.initialX,
    required this.initialY,
    required this.roomCode,
    required this.roomName,
    required this.category,
  });

  @override
  State<VisualPinPickerScreen> createState() => _VisualPinPickerScreenState();
}

class _VisualPinPickerScreenState extends State<VisualPinPickerScreen>
    with SingleTickerProviderStateMixin {
  late int _floor;
  late double _xRatio;
  late double _yRatio;

  final double originalWidth = 1200.0;
  final double originalHeight = 900.0;

  final TransformationController _transformController = TransformationController();
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _floor = widget.initialFloor.clamp(1, 3);
    _xRatio = widget.initialX.clamp(0.0, 1.0);
    _yRatio = widget.initialY.clamp(0.0, 1.0);

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onMapTapped(TapDownDetails details) {
    setState(() {
      _xRatio = double.parse((details.localPosition.dx / originalWidth).clamp(0.0, 1.0).toStringAsFixed(3));
      _yRatio = double.parse((details.localPosition.dy / originalHeight).clamp(0.0, 1.0).toStringAsFixed(3));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _xRatio = double.parse(((_xRatio * originalWidth + details.delta.dx) / originalWidth).clamp(0.0, 1.0).toStringAsFixed(3));
      _yRatio = double.parse(((_yRatio * originalHeight + details.delta.dy) / originalHeight).clamp(0.0, 1.0).toStringAsFixed(3));
    });
  }

  void _savePosition() {
    Navigator.of(context).pop({
      'xRatio': _xRatio,
      'yRatio': _yRatio,
      'floor': _floor,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherRooms = RoomRepository.instance
        .getRoomsByFloor(_floor)
        .where((r) => r.code != widget.roomCode)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atur Titik Pin Denah', style: TextStyle(fontSize: 16)),
            Text(
              '${widget.roomCode.isNotEmpty ? widget.roomCode : "Baru"} - ${widget.roomName.isNotEmpty ? widget.roomName : "Ruangan"} (${floorLabelFull(_floor)})',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Zoom',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              _transformController.value = Matrix4.identity();
            },
          ),
          ElevatedButton.icon(
            onPressed: _savePosition,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Gunakan Posisi Ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Peta Interaktif dengan Tap Detector
          InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.8,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(200),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: originalWidth,
                  height: originalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gambar Denah Lantai
                      GestureDetector(
                        onTapDown: _onMapTapped,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/lantai$_floor.png',
                            width: originalWidth,
                            height: originalHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Marker Ruangan Lain (Transparan / Abu-abu untuk referensi posisi)
                      for (final room in otherRooms)
                        Positioned(
                          left: (room.xRatio * originalWidth) - 15,
                          top: (room.yRatio * originalHeight) - 15,
                          child: IgnorePointer(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: room.color.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white70, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  room.code,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // PIN AKTIF YANG SEDANG DIATUR
                      Positioned(
                        left: (_xRatio * originalWidth) - 24,
                        top: (_yRatio * originalHeight) - 24,
                        child: GestureDetector(
                          onPanUpdate: _onPanUpdate,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ring Glowing
                                  Container(
                                    width: 48 + (_pulseAnim.value * 16),
                                    height: 48 + (_pulseAnim.value * 16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: RoomColors.fromCategory(widget.category)
                                          .withValues(alpha: 0.3 - (_pulseAnim.value * 0.15)),
                                      border: Border.all(
                                        color: RoomColors.fromCategory(widget.category),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // Pin Inti
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: RoomColors.fromCategory(widget.category),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.roomCode.isNotEmpty ? widget.roomCode : 'PIN',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pilihan Lantai Vertikal
          Positioned(
            right: 16,
            top: 24,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [3, 2, 1].map((f) {
                    final isCurrent = _floor == f;
                    return InkWell(
                      onTap: () => setState(() => _floor = f),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f == 1 ? 'Dasar' : 'Lt. ${f - 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // HUD Petunjuk & Koordinat di Bawah
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Center(
              child: Card(
                elevation: 6,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Klik di mana saja pada denah atau seret pin',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Lantai: ${floorLabelFull(_floor)} | xRatio: ${_xRatio.toStringAsFixed(3)} | yRatio: ${_yRatio.toStringAsFixed(3)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _savePosition,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

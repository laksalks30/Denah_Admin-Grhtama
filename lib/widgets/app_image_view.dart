import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/image_url_resolver.dart';

/// Widget serbaguna untuk menampilkan gambar dari berbagai sumber:
/// 1. Base64 Data URI (data:image/jpeg;base64,...)
/// 2. URL Internet (Supabase Storage, Google Drive direct, Unsplash, dsb.)
/// 3. Asset lokal aplikasi (assets/...)
class AppImageView extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImageView({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imagePath.trim();
    if (raw.isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    // 1. Base64 Data URI
    if (raw.startsWith('data:image')) {
      try {
        final commaIdx = raw.indexOf(',');
        final base64Str = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _defaultErrorWidget(),
        );
      } catch (e) {
        debugPrint('[AppImageView] Gagal decode base64: $e');
        return errorWidget ?? _defaultErrorWidget();
      }
    }

    final resolved = resolveImageUrl(raw);

    // 2. Network Image (HTTP / HTTPS / BLOB)
    if (resolved.startsWith('http://') ||
        resolved.startsWith('https://') ||
        resolved.startsWith('blob:')) {
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.black12,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        },
        errorBuilder: (ctx, err, stack) {
          debugPrint('[AppImageView] Gagal memuat $resolved: $err');
          return errorWidget ?? _defaultErrorWidget();
        },
      );
    }

    // 3. Local Asset
    return Image.asset(
      resolved,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? _defaultErrorWidget(),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Drop-in replacement for Image.network that:
/// 1. Transparently handles SVG URLs via SvgPicture.network.
/// 2. Pre-downloads and validates raster images BEFORE passing them
///    to the Flutter engine, preventing JNI-level decode errors
///    ("Failed to decode image / unimplemented") on Android.
/// 3. Caches validated image bytes in memory for instant re-display.
class SmartNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const SmartNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  State<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<SmartNetworkImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _hasError = false;

  /// In-memory cache: URL → validated image bytes.
  /// Keeps already-validated images so we never re-download or re-validate.
  static final Map<String, Uint8List> _cache = {};

  /// URLs that failed validation – skip immediately on next encounter.
  static final Set<String> _failed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SmartNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _load();
  }

  Future<void> _load() async {
    final url = widget.url;

    // Empty or SVG → handled in build(), not here.
    if (url.isEmpty || _isSvg(url)) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Already known to fail.
    if (_failed.contains(url)) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
      return;
    }

    // Already cached & validated.
    if (_cache.containsKey(url)) {
      if (mounted) setState(() { _bytes = _cache[url]; _loading = false; });
      return;
    }

    // Show loading state.
    if (mounted) setState(() { _loading = true; _hasError = false; _bytes = null; });

    try {
      // 1. Download raw bytes via HttpClient (dart:io, zero extra deps).
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Check Content-Type.  Reject obvious non-images (HTML 404 pages, etc.)
      final contentType = response.headers.contentType?.mimeType ?? '';
      if (contentType.isNotEmpty &&
          !contentType.startsWith('image/') &&
          contentType != 'application/octet-stream') {
        throw Exception('Non-image content-type: $contentType');
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = builder.toBytes();
      client.close(force: false);

      if (bytes.isEmpty) throw Exception('Empty response body');

      // 2. Validate: try instantiating an image codec at the Dart level.
      //    This uses the same engine decoder but exceptions bubble up to
      //    Dart rather than crashing at JNI with an ugly logcat line.
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose(); // We only needed it for validation.

      // 3. Cache validated bytes.
      _cache[url] = bytes;

      // Limit cache size (LRU-ish: just evict oldest when too large).
      if (_cache.length > 200) {
        _cache.remove(_cache.keys.first);
      }

      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    } catch (_) {
      _failed.add(url);
      if (mounted) setState(() { _hasError = true; _loading = false; });
    }
  }

  bool _isSvg(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.svg');
  }

  Widget _fallback(BuildContext context) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, Exception('Image load failed'), null);
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 22,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;

    // ── Empty URL ──
    if (url.isEmpty) return _fallback(context);

    // ── SVG ── (handled separately, no JNI issue)
    if (_isSvg(url)) {
      return SvgPicture.network(
        url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholderBuilder: (_) => SizedBox(width: widget.width, height: widget.height),
      );
    }

    // ── Loading ──
    if (_loading) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    // ── Error ──
    if (_hasError || _bytes == null) {
      return _fallback(context);
    }

    // ── Validated image bytes → safe to render ──
    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (ctx, err, st) => _fallback(ctx),
    );
  }
}

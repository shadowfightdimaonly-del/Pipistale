import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PipistaleSprite extends StatefulWidget {
  const PipistaleSprite({
    super.key,
    required this.x,
    required this.y,
    required this.frame,
    required this.row,
  });

  final double x;
  final double y;
  final int frame;
  final int row;

  @override
  State<PipistaleSprite> createState() => _PipistaleSpriteState();
}

class _PipistaleSpriteState extends State<PipistaleSprite> {
  late final Future<ui.Image> _imageFuture = _loadImage();

  Future<ui.Image> _loadImage() async {
    final data = await rootBundle.load('assets/pipistale_walk_sheet.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(
        -1 + 2 * (0.06 + 0.88 * widget.x),
        -1 + 2 * (0.10 + 0.80 * widget.y),
      ),
      child: SizedBox(
        width: 48,
        height: 75,
        child: FutureBuilder<ui.Image>(
          future: _imageFuture,
          builder: (context, snapshot) {
            final image = snapshot.data;
            if (image == null) return const SizedBox.expand();
            return CustomPaint(
              painter: _SpriteSheetPainter(
                image: image,
                frame: widget.frame,
                row: widget.row,
              ),
              size: const Size(48, 75),
            );
          },
        ),
      ),
    );
  }
}

class _SpriteSheetPainter extends CustomPainter {
  const _SpriteSheetPainter({
    required this.image,
    required this.frame,
    required this.row,
  });

  final ui.Image image;
  final int frame;
  final int row;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      frame.clamp(0, 3) * 48.0,
      row.clamp(0, 3) * 75.0,
      48.0,
      75.0,
    );
    final destination = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.none;
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frame != frame ||
        oldDelegate.row != row;
  }
}

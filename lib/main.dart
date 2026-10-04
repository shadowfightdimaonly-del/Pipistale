import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const PipistaleApp());
}

class PipistaleApp extends StatelessWidget {
  const PipistaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipistale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const PrototypeScreen(),
    );
  }
}

class PrototypeScreen extends StatefulWidget {
  const PrototypeScreen({super.key});

  @override
  State<PrototypeScreen> createState() => _PrototypeScreenState();
}

class _PrototypeScreenState extends State<PrototypeScreen> {
  final FocusNode _focusNode = FocusNode();
  Offset _player = const Offset(0.5, 0.5);

  static const double _playerSize = 22;
  static const double _speed = 0.018;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _move(LogicalKeyboardKey key) {
    var dx = 0.0;
    var dy = 0.0;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) dx = -_speed;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) dx = _speed;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) dy = -_speed;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) dy = _speed;

    final next = Offset(
      (_player.dx + dx).clamp(0.06, 0.94),
      (_player.dy + dy).clamp(0.10, 0.90),
    );

    if (next != _player) {
      setState(() => _player = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  _move(event.logicalKey);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: CustomPaint(
                painter: _RoomPainter(player: _player),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter({required this.player});

  final Offset player;

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.10,
      size.width * 0.88,
      size.height * 0.80,
    );

    final roomPaint = Paint()..color = const Color(0xFF101010);
    final wallPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(room, roomPaint);
    canvas.drawRect(room, wallPaint);

    final playerPosition = Offset(
      room.left + room.width * player.dx,
      room.top + room.height * player.dy,
    );

    final playerPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromCenter(
        center: playerPosition,
        width: _PrototypeScreenState._playerSize,
        height: _PrototypeScreenState._playerSize,
      ),
      playerPaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'WASD / стрелки  •  Первый прототип комнаты',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        math.max(8, size.width / 2 - textPainter.width / 2),
        size.height - textPainter.height - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) {
    return oldDelegate.player != player;
  }
}

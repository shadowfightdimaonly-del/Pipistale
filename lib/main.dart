import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const PipistaleApp());
  });
}

enum ControlMode { arrows, joystick }

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
  static const _controlKey = 'control_mode';
  static const _movementInterval = Duration(milliseconds: 16);

  final FocusNode _focusNode = FocusNode();
  Timer? _movementTimer;
  Timer? _animationTimer;

  Offset _player = const Offset(0.5, 0.5);
  ControlMode _controlMode = ControlMode.arrows;
  bool _showControlChoice = true;
  Offset _heldDirection = Offset.zero;
  Offset _joystickVector = Offset.zero;
  int _animationFrame = 0;
  int _facingRow = 2; // 0 right, 1 left, 2 down, 3 up.

  // Roughly normal Undertale-like walking speed.
  // Movement is applied by a fixed 60-ish FPS timer, not by gesture frequency.
  static const double _speedPerSecond = 0.24;

  @override
  void initState() {
    super.initState();
    _loadControlMode();
    _movementTimer = Timer.periodic(_movementInterval, (_) {
      _tickMovement();
    });
    _animationTimer = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!mounted) return;
      if (_heldDirection == Offset.zero) {
        if (_animationFrame != 0) {
          setState(() => _animationFrame = 0);
        }
        return;
      }
      setState(() => _animationFrame = (_animationFrame + 1) % 4);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _tickMovement() {
    final direction = _heldDirection;
    if (direction == Offset.zero || !mounted) return;

    final length = direction.distance;
    final normalized = length > 1 ? direction / length : direction;
    final delta = _speedPerSecond * (_movementInterval.inMicroseconds / 1000000);
    final next = Offset(
      (_player.dx + normalized.dx * delta).clamp(0.06, 0.94),
      (_player.dy + normalized.dy * delta).clamp(0.10, 0.90),
    );

    if (next != _player) {
      setState(() => _player = next);
    }
  }

  void _setHeldDirection(Offset direction) {
    if (direction == Offset.zero) {
      _heldDirection = Offset.zero;
      return;
    }

    final length = direction.distance;
    final normalized = length > 1 ? direction / length : direction;
    _heldDirection = normalized;

    // The sprite sheet has four cardinal views. For diagonal movement we
    // choose the dominant axis so the character never points at a diagonal
    // that does not exist in the artwork.
    if (normalized.dx.abs() > normalized.dy.abs()) {
      _facingRow = normalized.dx > 0 ? 0 : 1;
    } else if (normalized.dy != 0) {
      _facingRow = normalized.dy > 0 ? 2 : 3;
    }
  }

  void _startButtonMovement(Offset direction) {
    _setHeldDirection(direction);
  }

  void _stopButtonMovement() {
    if (_controlMode == ControlMode.arrows) {
      _setHeldDirection(Offset.zero);
    }
  }

  void _moveKeyboard(LogicalKeyboardKey key, bool pressed) {
    final current = _keyboardDirections[key] ?? Offset.zero;
    if (current == Offset.zero) return;

    if (pressed) {
      _setHeldDirection(current);
    } else if (_heldDirection == current) {
      _setHeldDirection(Offset.zero);
    }
  }

  // This must not be const because LogicalKeyboardKey instances do not
  // have primitive equality, which Dart requires for const map keys.
  static final Map<LogicalKeyboardKey, Offset> _keyboardDirections = {
    LogicalKeyboardKey.arrowLeft: const Offset(-1, 0),
    LogicalKeyboardKey.keyA: const Offset(-1, 0),
    LogicalKeyboardKey.arrowRight: const Offset(1, 0),
    LogicalKeyboardKey.keyD: const Offset(1, 0),
    LogicalKeyboardKey.arrowUp: const Offset(0, -1),
    LogicalKeyboardKey.keyW: const Offset(0, -1),
    LogicalKeyboardKey.arrowDown: const Offset(0, 1),
    LogicalKeyboardKey.keyS: const Offset(0, 1),
  };

  Future<void> _loadControlMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_controlKey);
    if (!mounted) return;
    setState(() {
      if (saved == 'joystick') {
        _controlMode = ControlMode.joystick;
        _showControlChoice = false;
      } else if (saved == 'arrows') {
        _controlMode = ControlMode.arrows;
        _showControlChoice = false;
      }
    });
  }

  Future<void> _setControlMode(ControlMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _controlKey,
      mode == ControlMode.joystick ? 'joystick' : 'arrows',
    );
    _setHeldDirection(Offset.zero);
    _joystickVector = Offset.zero;
    if (!mounted) return;
    setState(() {
      _controlMode = mode;
      _showControlChoice = false;
    });
  }

  void _showControls() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ControlMode>(
              value: ControlMode.arrows,
              groupValue: _controlMode,
              title: const Text('Стрелочки'),
              subtitle: const Text('8 направлений'),
              onChanged: (value) {
                if (value != null) {
                  _setControlMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ControlMode>(
              value: ControlMode.joystick,
              groupValue: _controlMode,
              title: const Text('Джойстик'),
              subtitle: const Text('Круговое управление'),
              onChanged: (value) {
                if (value != null) {
                  _setControlMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _animationTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
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
                final isDown = event is KeyDownEvent;
                final isUp = event is KeyUpEvent;
                if (isDown || isUp) {
                  _moveKeyboard(event.logicalKey, isDown);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoomPainter(player: _player),
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      -1 + 2 * (0.06 + 0.88 * _player.dx),
                      -1 + 2 * (0.10 + 0.80 * _player.dy),
                    ),
                    child: ClipRect(
                      child: SizedBox(
                        width: 48,
                        height: 75,
                        child: Transform.translate(
                          offset: Offset(
                            -48.0 * _animationFrame,
                            -75.0 * _facingRow,
                          ),
                          child: Image.asset(
                            'assets/pipistale_walk_sheet.png',
                            width: 192,
                            height: 300,
                            fit: BoxFit.none,
                            alignment: Alignment.topLeft,
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_showControlChoice)
                    Positioned.fill(
                      child: _controlMode == ControlMode.arrows
                          ? _ArrowControls(
                              onMoveStart: _startButtonMovement,
                              onMoveEnd: _stopButtonMovement,
                            )
                          : _JoystickControl(
                              onChanged: (vector) {
                                _joystickVector = vector;
                                _setHeldDirection(vector);
                              },
                              onReleased: () {
                                _joystickVector = Offset.zero;
                                _setHeldDirection(Offset.zero);
                              },
                            ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton(
                      tooltip: 'Управление',
                      onPressed: _showControls,
                      icon: const Icon(Icons.gamepad_outlined),
                    ),
                  ),
                  if (_showControlChoice)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.86),
                        child: Center(
                          child: Card(
                            color: const Color(0xFF151515),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Как управлять?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ControlChoiceButton(
                                        icon: Icons.control_camera_outlined,
                                        title: 'Стрелочки',
                                        subtitle: '8 направлений',
                                        onPressed: () => _setControlMode(
                                          ControlMode.arrows,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      _ControlChoiceButton(
                                        icon: Icons.gamepad_outlined,
                                        title: 'Джойстик',
                                        subtitle: 'Круговое управление',
                                        onPressed: () => _setControlMode(
                                          ControlMode.joystick,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

class _ControlChoiceButton extends StatelessWidget {
  const _ControlChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 120,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34),
            const SizedBox(height: 8),
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowControls extends StatelessWidget {
  const _ArrowControls({
    required this.onMoveStart,
    required this.onMoveEnd,
  });

  final void Function(Offset) onMoveStart;
  final VoidCallback onMoveEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 0, 22),
        child: SizedBox(
          width: 190,
          height: 150,
          child: Stack(
            children: [
              _ArrowButton(left: 70, top: 0, icon: Icons.keyboard_arrow_up, direction: const Offset(0, -1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 0, top: 52, icon: Icons.keyboard_arrow_left, direction: const Offset(-1, 0), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 70, top: 52, icon: Icons.keyboard_arrow_down, direction: const Offset(0, 1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 140, top: 52, icon: Icons.keyboard_arrow_right, direction: const Offset(1, 0), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 18, top: 104, icon: Icons.keyboard_arrow_down, direction: const Offset(-1, 1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 122, top: 104, icon: Icons.keyboard_arrow_down, direction: const Offset(1, 1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 18, top: 0, icon: Icons.keyboard_arrow_up, direction: const Offset(-1, -1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
              _ArrowButton(left: 122, top: 0, icon: Icons.keyboard_arrow_up, direction: const Offset(1, -1), onMoveStart: onMoveStart, onMoveEnd: onMoveEnd),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.left,
    required this.top,
    required this.icon,
    required this.direction,
    required this.onMoveStart,
    required this.onMoveEnd,
  });

  final double left;
  final double top;
  final IconData icon;
  final Offset direction;
  final void Function(Offset) onMoveStart;
  final VoidCallback onMoveEnd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => onMoveStart(direction),
        onLongPressStart: (_) => onMoveStart(direction),
        onLongPressEnd: (_) => onMoveEnd(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
      ),
    );
  }
}

class _JoystickControl extends StatefulWidget {
  const _JoystickControl({
    required this.onChanged,
    required this.onReleased,
  });

  final void Function(Offset) onChanged;
  final VoidCallback onReleased;

  @override
  State<_JoystickControl> createState() => _JoystickControlState();
}

class _JoystickControlState extends State<_JoystickControl> {
  Offset _knob = Offset.zero;

  void _update(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var delta = local - center;
    final maxRadius = size.width / 2 - 24;
    if (delta.distance > maxRadius) {
      delta = Offset.fromDirection(delta.direction, maxRadius);
    }
    final normalized = maxRadius == 0 ? Offset.zero : delta / maxRadius;
    setState(() => _knob = delta);
    widget.onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 28, bottom: 28),
        child: GestureDetector(
          onPanStart: (details) {
            _update(details.localPosition, const Size(170, 170));
          },
          onPanUpdate: (details) {
            _update(details.localPosition, const Size(170, 170));
          },
          onPanEnd: (_) {
            setState(() => _knob = Offset.zero);
            widget.onReleased();
          },
          onPanCancel: () {
            setState(() => _knob = Offset.zero);
            widget.onReleased();
          },
          child: SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _JoystickPainter(knob: _knob),
            ),
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter({required this.knob});

  final Offset knob;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = Paint()..color = Colors.white.withOpacity(0.14);
    final outline = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.5);

    canvas.drawCircle(center, size.width / 2 - 4, base);
    canvas.drawCircle(center, size.width / 2 - 4, outline);
    canvas.drawCircle(center + knob, 32, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.knob != knob;
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

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Pipistale • прототип комнаты',
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

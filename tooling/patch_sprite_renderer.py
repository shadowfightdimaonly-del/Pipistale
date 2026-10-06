from pathlib import Path

main = Path('lib/main.dart')
s = main.read_text(encoding='utf-8')

import_line = "import 'package:shared_preferences/shared_preferences.dart';"
new_import = import_line + "\nimport 'sprite_sheet_widget.dart';"
if "import 'sprite_sheet_widget.dart';" not in s:
    if import_line not in s:
        raise SystemExit('shared_preferences import not found')
    s = s.replace(import_line, new_import, 1)

old = """                  Align(\n                    alignment: Alignment(\n                      -1 + 2 * (0.06 + 0.88 * _player.dx),\n                      -1 + 2 * (0.10 + 0.80 * _player.dy),\n                    ),\n                    child: SizedBox(\n                      width: 48,\n                      height: 75,\n                      child: FittedBox(\n                        fit: BoxFit.none,\n                        alignment: Alignment(\n                          -1.0 + (2.0 * _animationFrame / 3.0),\n                          -1.0 + (2.0 * _facingRow / 3.0),\n                        ),\n                        clipBehavior: Clip.hardEdge,\n                        child: Image.asset(\n                          'assets/pipistale_walk_sheet.png',\n                          width: 192,\n                          height: 300,\n                          filterQuality: FilterQuality.none,\n                          isAntiAlias: false,\n                        ),\n                      ),\n                    ),\n                  ),\n"""
new = """                  PipistaleSprite(\n                    x: _player.dx,\n                    y: _player.dy,\n                    frame: _animationFrame,\n                    row: _facingRow,\n                  ),\n"""
if old not in s:
    raise SystemExit('old sprite renderer block not found')
s = s.replace(old, new, 1)
main.write_text(s, encoding='utf-8')
print('sprite renderer patched')

import 'dart:io';

import 'package:window_manager/window_manager.dart';

import '../../Logger.dart';

bool _wasMaximized = false;

Future<void> setDesktopFullscreen(bool value) async {
  if (Platform.isWindows) {
    await _setWindowsFullscreen(value);
    return;
  }
  if (Platform.isLinux || Platform.isMacOS) {
    await windowManager.setFullScreen(value);
  }
}

Future<void> toggleDesktopFullscreen() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
  await setDesktopFullscreen(!await windowManager.isFullScreen());
}

Future<void> _setWindowsFullscreen(bool value) async {
  if (await windowManager.isFullScreen() == value) return;
  if (!value) {
    await windowManager.setFullScreen(false);
    if (_wasMaximized) {
      _wasMaximized = false;
      await windowManager.maximize();
    }
    return;
  }
  final wasMaximized = await windowManager.isMaximized();
  if (wasMaximized) {
    await windowManager.unmaximize();
    final restored = await _waitUntilNotMaximized();
    if (!restored) {
      logWarn('window stayed maximized; caption bar may remain', tag: 'WINDOW');
    }
  }
  await windowManager.setFullScreen(true);
  _wasMaximized = wasMaximized;
}

Future<bool> _waitUntilNotMaximized() async {
  for (var i = 0; i < 40; i++) {
    if (!await windowManager.isMaximized()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  return false;
}

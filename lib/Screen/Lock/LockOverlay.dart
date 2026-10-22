import 'dart:async';

import 'package:flutter/material.dart';

import '../../Core/Security/AppLock.dart';
import '../../Core/State/State.dart';
import '../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../Utils/Extensions/ContextExtensions.dart';
import '../../Utils/Extensions/Responsive.dart';
import 'PinPad.dart';

class LockOverlay extends StatelessWidget {
  final Widget child;

  const LockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final lock = find<AppLock>();
    return Watch(
      () => Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(excluding: lock.locked.value, child: child),
          if (lock.locked.value) const _LockScreen(),
        ],
      ),
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final _message = Live<String?>(null);
  Timer? _timer;

  bool _submit(String pin) {
    final lock = find<AppLock>();
    if (lock.unlock(pin)) return true;
    _tick();
    return false;
  }

  void _tick() {
    _timer?.cancel();
    final wait = find<AppLock>().blocked;
    if (wait <= Duration.zero) {
      _message.value = getString.appLockWrong;
      return;
    }
    _message.value = getString.appLockWait('${wait.inSeconds + 1}');
    _timer = Timer(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Watch(() => _build(context));

  Widget _build(BuildContext context) {
    final scheme = context.colorScheme;
    return PopScope(
      canPop: false,
      child: Material(
        color: scheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Dimens.pagePad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 40, color: scheme.primary),
                  SizedBox(height: Dimens.gap),
                  Text(
                    getString.appLockUnlock,
                    style: context.textTheme.titleLarge,
                  ),
                  SizedBox(height: Dimens.gapLg),
                  PinPad(onSubmit: _submit, message: _message.value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

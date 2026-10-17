import 'package:flutter/material.dart';

import '../../Core/State/State.dart';
import '../../Utils/Animation/WidgetAnimations.dart';

class ScrollTopButton extends StatefulWidget {
  final Widget child;

  const ScrollTopButton({super.key, required this.child});

  @override
  State<ScrollTopButton> createState() => _ScrollTopButtonState();
}

class _ScrollTopButtonState extends State<ScrollTopButton> {
  final shown = false.live;
  ScrollPosition? _position;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final far = n.metrics.pixels > n.metrics.viewportDimension * 1.2;
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _position = Scrollable.maybeOf(n.context!)?.position;
      if (shown.value != far) shown.value = far;
    }
    return false;
  }

  void _top() {
    final p = _position;
    if (p == null || !p.hasPixels) return;
    p.animateTo(0, duration: animDuration(450), curve: Curves.easeOutCubic);
  }

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            right: 16,
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
            child: IgnorePointer(
              ignoring: !shown.value,
              child: AnimatedScale(
                scale: shown.value ? 1 : 0.6,
                duration: animDuration(180),
                child: AnimatedOpacity(
                  opacity: shown.value ? 1 : 0,
                  duration: animDuration(180),
                  child: FloatingActionButton.small(
                    heroTag: null,
                    elevation: 2,
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    onPressed: _top,
                    child: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Watch(() => _build(context));
}

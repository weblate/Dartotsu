import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeekProgressBar extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final Color? activeColor;
  final Color? trackColor;
  final double thickness;

  const SeekProgressBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 0.05,
    this.activeColor,
    this.trackColor,
    this.thickness = 6,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = activeColor ?? scheme.primary;
    final track = trackColor ?? Colors.white.withValues(alpha: 0.28);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        double at(double dx) {
          final f = (dx / box.maxWidth).clamp(0.0, 1.0);
          return direction == TextDirection.rtl ? 1 - f : f;
        }

        return Focus(
          onKeyEvent: (node, event) {
            if (event is KeyUpEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            final forward = direction == TextDirection.rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight;
            final back = direction == TextDirection.rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft;
            if (key == forward) {
              onChanged((value + step).clamp(0.0, 1.0));
              return KeyEventResult.handled;
            }
            if (key == back) {
              onChanged((value - step).clamp(0.0, 1.0));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => onChanged(at(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) => onChanged(at(d.localPosition.dx)),
            child: SizedBox(
              height: 28,
              width: double.infinity,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(thickness),
                  child: SizedBox(
                    height: thickness,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: track),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0.0, 1.0),
                            child: ColoredBox(color: active),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../Core/Fonts/AppFonts.dart';
import '../Engine/PlayerSettings.dart';
import '../Engine/SubtitleMarkup.dart';
import '../../../Core/State/State.dart';
import '../../../Utils/Animation/WidgetAnimations.dart';

class PlayerSubtitleView extends StatelessWidget {
  final List<String> lines;
  final PlayerSettings settings;
  final bool controlsVisible;

  const PlayerSubtitleView({
    super.key,
    required this.lines,
    required this.settings,
    required this.controlsVisible,
  });

  @override
  Widget build(BuildContext context) => Watch(() => _build(context));

  Widget _build(BuildContext context) {
    fontsTick.value;

    final family = fontFamilyOf(settings.subtitleFont);
    final text = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.trim(),
    ].join('\n');

    if (text.isEmpty || !settings.showSubtitle) {
      return const SizedBox.shrink();
    }

    final outline = Color(settings.subtitleOutlineColor);

    return _positioned(context, text, family, outline);
  }

  Widget _positioned(
    BuildContext context,
    String text,
    String? family,
    Color outline,
  ) {
    return AnimatedPositioned(
      duration: animDuration(200),
      left: 16,
      right: 16,
      top: 0,
      bottom: controlsVisible
          ? 110 + settings.subtitleBottomPadding.toDouble()
          : settings.subtitleBottomPadding.toDouble(),
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = ((box.maxWidth + 32) / 720).clamp(0.55, 1.0);

          return RepaintBoundary(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(settings.subtitleBackgroundColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _outlined(text, family, outline, scale),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _outlined(String text, String? family, Color outline, double scale) {
    final size = settings.subtitleSize * scale;
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.values[settings.subtitleWeight.clamp(0, 8)],
      fontFamily: family,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (size * 0.16).clamp(2.0, 6.0)
      ..color = outline;
    return Stack(
      children: [
        Text.rich(
          TextSpan(children: subtitleSpans(text, stroke: stroke)),
          textAlign: TextAlign.center,
          style: base.copyWith(foreground: stroke),
        ),
        Text.rich(
          TextSpan(children: subtitleSpans(text)),
          textAlign: TextAlign.center,
          style: base.copyWith(color: Color(settings.subtitleColor)),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../../Widgets/Components/SeekProgressBar.dart';
import 'package:flutter/services.dart';

import '../../../Core/Fonts/AppFonts.dart';
import '../Engine/NovelText.dart';
import '../Engine/ReaderRequest.dart';
import '../Engine/ReaderSettings.dart';
import '../../../Core/State/State.dart';
import '../../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../../Model/Setting.dart';
import '../../../Utils/Extensions/ContextExtensions.dart';
import '../../../Utils/Extensions/Responsive.dart';
import '../../../Utils/Functions/NavigateToScreen.dart';
import '../../../Widgets/Components/AppSheet.dart';
import '../../../Widgets/Components/CachedNetworkImage.dart';
import '../../../Widgets/Components/CustomBottomDialog.dart';
import '../../../Widgets/Components/EmptyState.dart';
import '../../../Widgets/Components/ScreenState.dart';
import '../../Settings/Categories/ReaderSettings.dart';
import '../../Settings/Widgets/SettingsGroup.dart';
import '../Components/BookmarksSheet.dart';
import '../Components/ReaderSheets.dart';
import 'NovelState.dart';
import '../../../Utils/Animation/WidgetAnimations.dart';

class NovelScreen extends StatefulWidget {
  final ReaderRequest request;

  const NovelScreen({super.key, required this.request});

  @override
  State<NovelScreen> createState() => _NovelScreenState();
}

class _NovelScreenState extends State<NovelScreen>
    with ScreenStateHost<NovelScreen, NovelState> {
  final _focus = FocusNode();

  @override
  NovelState buildState() => NovelState(widget.request);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Watch(() => _build(context));

  (Color, Color) _colors(BuildContext context, String id) => switch (id) {
    'light' => (const Color(0xFFFAFAFA), const Color(0xFF1E1E1E)),
    'sepia' => (const Color(0xFFF4ECD8), const Color(0xFF5B4636)),
    'dark' => (const Color(0xFF1B1B1F), const Color(0xFFD7D7DC)),
    'black' => (Colors.black, const Color(0xFFBDBDBD)),
    _ => (context.colorScheme.surface, context.colorScheme.onSurface),
  };

  Widget _build(BuildContext context) {
    state.settingsVersion.value;
    fontsTick.value;
    final settings = state.settings;
    final (background, foreground) = _colors(context, settings.novelTheme);
    final body = state.loading.value
        ? const Center(child: CircularProgressIndicator())
        : state.error.value != null
        ? EmptyState(
            icon: Icons.error_outline_rounded,
            failed: true,
            title: getString.readerFailed,
            message: state.error.value,
            actionLabel: getString.retry,
            onAction: state.retry,
          )
        : _text(context, settings, foreground);
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(color: foreground),
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: foreground, displayColor: foreground),
      ),
      child: Scaffold(
        backgroundColor: background,
        body: KeyboardListener(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _key,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: body),
              if (!state.loading.value && state.error.value == null)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, box) => GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (d) {
                        if (state.speaking.value &&
                            !state.controlsVisible.value) {
                          final at = state.blockAt(d.globalPosition);
                          if (at != null) {
                            unawaited(state.startSpeaking(from: at));
                            return;
                          }
                        }
                        if (!settings.novelTapPaging ||
                            state.controlsVisible.value) {
                          state.toggleControls();
                          return;
                        }
                        final x = d.localPosition.dx / box.maxWidth;
                        if (x < 0.25) {
                          state.pageBy(-1);
                        } else if (x > 0.75) {
                          state.pageBy(1);
                        } else {
                          state.toggleControls();
                        }
                      },
                    ),
                  ),
                ),
              Watch(() => _bar(context, background, foreground, top: true)),
              Watch(() => _bar(context, background, foreground, top: false)),
              Watch(() => _audioBar(context, background, foreground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context, ReaderSettings s, Color foreground) {
    final blocks = state.blocks.toList();
    final base = TextStyle(
      fontFamily: fontFamilyOf(s.novelFont),
      fontSize: s.novelSize.toDouble(),
      height: s.novelLineHeight,
      color: foreground,
      fontWeight: s.novelBold ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: s.novelLetterSpacing / 10,
    );
    final margin = s.novelMargin.toDouble();
    return SelectionArea(
      child: ListView.builder(
        controller: state.scroll,
        padding: EdgeInsets.fromLTRB(
          margin,
          MediaQuery.paddingOf(context).top + 56,
          margin,
          MediaQuery.paddingOf(context).bottom + 96,
        ),
        itemCount: blocks.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) return _heading(context, base);
          if (i == blocks.length + 1) return _end(context);
          final key = state.blockKeys.putIfAbsent(i - 1, GlobalKey.new);
          final source = state.original;
          final bilingual =
              s.translateBilingual &&
              state.translated.value != null &&
              source.length == blocks.length &&
              source[i - 1] is NovelParagraph &&
              blocks[i - 1] is NovelParagraph;
          final block = bilingual
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(
                      context,
                      source[i - 1],
                      base,
                      s.copy()..novelParagraph = 4,
                    ),
                    _block(
                      context,
                      blocks[i - 1],
                      base.copyWith(color: base.color?.withValues(alpha: 0.6)),
                      s,
                    ),
                  ],
                )
              : _block(context, blocks[i - 1], base, s);
          return KeyedSubtree(
            key: key,
            child: Watch(
              () => state.speakingAt.value == i - 1
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius: Dimens.borderSm,
                      ),
                      child: block,
                    )
                  : block,
            ),
          );
        },
      ),
    );
  }

  Widget _heading(BuildContext context, TextStyle base) => Padding(
    padding: EdgeInsets.only(bottom: Dimens.gapLg),
    child: Text(
      state.title,
      style: base.copyWith(
        fontSize: base.fontSize! * 1.4,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _block(
    BuildContext context,
    NovelBlock block,
    TextStyle base,
    ReaderSettings s,
  ) {
    final gap = s.novelParagraph.toDouble();
    switch (block) {
      case NovelParagraph p:
        final scale = switch (p.heading) {
          1 => 1.5,
          2 => 1.35,
          3 => 1.2,
          0 => 1.0,
          _ => 1.1,
        };
        return Padding(
          padding: EdgeInsets.only(bottom: gap, top: p.heading > 0 ? gap : 0),
          child: Text(
            p.heading == 0 && s.novelIndent ? '\u2003\u2003${p.text}' : p.text,
            textAlign: s.novelJustify ? TextAlign.justify : TextAlign.start,
            style: p.heading > 0
                ? base.copyWith(
                    fontSize: base.fontSize! * scale,
                    fontWeight: FontWeight.w700,
                  )
                : base,
          ),
        );
      case NovelPicture p:
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: !p.url.startsWith('http') && File(p.url).isAbsolute
              ? Image.file(
                  File(p.url),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                )
              : cachedNetworkImage(
                  imageUrl: p.url,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
        );
      case NovelRule():
        return Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: Divider(color: base.color?.withValues(alpha: 0.3)),
        );
    }
  }

  Widget _end(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Dimens.gapLg),
    child: Center(
      child: state.hasNext
          ? FilledButton.icon(
              onPressed: state.next,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(getString.readerNextChapter),
            )
          : Text(getString.readerLastChapter),
    ),
  );

  Widget _bar(
    BuildContext context,
    Color background,
    Color foreground, {
    required bool top,
  }) {
    final visible = state.controlsVisible.value || state.speaking.value && !top;
    final solid = background.withValues(alpha: 0.99);
    final clear = background.withValues(alpha: 0);
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [solid, solid, clear],
          stops: const [0, 0.72, 1],
        ),
      ),
      child: SafeArea(
        top: top,
        bottom: !top,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, top ? 4 : 20, 8, top ? 20 : 8),
          child: top
              ? _topRow(context, foreground)
              : _bottomRow(context, foreground),
        ),
      ),
    );
    return PositionedDirectional(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      start: 0,
      end: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(0, top ? -1 : 1),
          duration: animDuration(220),
          curve: Curves.easeOutCubic,
          child: bar,
        ),
      ),
    );
  }

  Widget _icon(
    Color foreground,
    IconData icon,
    VoidCallback? onTap, {
    String? tooltip,
    bool active = false,
  }) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    color: active ? context.colorScheme.primary : foreground,
    disabledColor: foreground.withValues(alpha: 0.3),
    visualDensity: VisualDensity.compact,
    style: IconButton.styleFrom(
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: foreground.withValues(alpha: 0.08),
    ),
    icon: Icon(icon),
  );

  Widget _topRow(BuildContext context, Color foreground) => Row(
    children: [
      _icon(
        foreground,
        Icons.arrow_back_ios_new_rounded,
        () => popPage(context),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              state.request.media.mainName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
      if (state.canSpeak)
        _icon(
          foreground,
          Icons.record_voice_over_rounded,
          state.toggleSpeaking,
          active: state.speaking.value,
          tooltip: state.speaking.value
              ? getString.novelSpeakStop
              : getString.novelSpeak,
        ),
      _icon(
        foreground,
        Icons.g_translate_rounded,
        state.translating.value ? null : state.toggleTranslation,
        active: state.translated.value != null,
        tooltip: state.translated.value != null
            ? getString.novelTranslateShowOriginal
            : getString.novelTranslate,
      ),
      _icon(
        foreground,
        state.autoScrolling.value
            ? Icons.pause_circle_outline_rounded
            : Icons.play_circle_outline_rounded,
        state.toggleAutoScroll,
        tooltip: state.autoScrolling.value
            ? getString.readerAutoScrollStop
            : getString.readerAutoScroll,
      ),
      _icon(
        foreground,
        state.bookmarked
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
        state.toggleBookmark,
        tooltip: state.bookmarked
            ? getString.readerBookmarkRemove
            : getString.readerBookmarkAdd,
      ),
      if (state.record.bookmarks.isNotEmpty)
        _icon(
          foreground,
          Icons.bookmarks_outlined,
          () => showBookmarks(
            context,
            record: state.record,
            tick: state.bookmarkTick,
            detail: (b) => '${(b.position * 100 / b.total).round()}%',
            onOpen: state.openBookmark,
            onRemove: state.removeBookmark,
          ),
          tooltip: getString.readerBookmarks,
        ),
      _icon(
        foreground,
        Icons.format_list_numbered_rounded,
        () => showChapterList(
          context,
          request: state.request,
          current: state.index.value,
          onPick: state.openChapter,
        ),
        tooltip: getString.readerChapters,
      ),
      _icon(
        foreground,
        Icons.settings_rounded,
        () => _options(context),
        tooltip: getString.readerSettingsTitle,
      ),
    ],
  );

  Widget _bottomRow(BuildContext context, Color foreground) {
    final controls = state.controlsVisible.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.translating.value)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: state.translateProgress.value == 0
                  ? null
                  : state.translateProgress.value,
            ),
          ),
        if (state.speaking.value) _speech(context, foreground),
        if (controls && state.autoScrolling.value) _speed(context, foreground),
        if (controls)
          Row(
            children: [
              _icon(
                foreground,
                Icons.skip_previous_rounded,
                state.hasPrevious ? state.previous : null,
                tooltip: getString.readerPreviousChapter,
              ),
              Expanded(
                child: Watch(() {
                  final fraction = state.fraction.value;
                  return Row(
                    children: [
                      Text(
                        '${(fraction * 100).round()}%',
                        style: context.textTheme.labelLarge,
                      ),
                      Expanded(
                        child: SeekProgressBar(
                          value: fraction.clamp(0.0, 1.0),
                          activeColor: foreground,
                          trackColor: foreground.withValues(alpha: 0.2),
                          onChanged: state.seekTo,
                        ),
                      ),
                      Text(
                        getString.novelMinutesLeft(
                          (state.wordsLeft / 230).ceil(),
                        ),
                        style: context.textTheme.labelLarge?.copyWith(
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              _icon(
                foreground,
                Icons.skip_next_rounded,
                state.hasNext ? state.next : null,
                tooltip: getString.readerNextChapter,
              ),
            ],
          ),
      ],
    );
  }

  Widget _audioBar(BuildContext context, Color background, Color foreground) {
    final speaking = state.speaking.value;
    final scrolling = state.autoScrolling.value;
    if (state.controlsVisible.value || (!speaking && !scrolling)) {
      return const SizedBox.shrink();
    }
    final scheme = context.colorScheme;
    final paused = speaking ? state.speechPaused.value : state.autoPaused.value;
    final settings = state.settings;
    final label = speaking
        ? '${settings.speechRate}%'
        : '${settings.autoScrollSpeed.clamp(1, 10)}';
    void speed(int delta) {
      if (speaking) {
        final next = (settings.speechRate + delta * 10).clamp(50, 200);
        state.updateSettings((s) => s.speechRate = next);
        state.restartSpeaking();
      } else {
        final next = (settings.autoScrollSpeed + delta).clamp(1, 10);
        state.updateSettings((s) => s.autoScrollSpeed = next);
      }
    }

    Widget button(IconData icon, VoidCallback onTap, {bool filled = false}) =>
        IconButton(
          onPressed: onTap,
          color: filled ? scheme.onPrimary : foreground,
          style: IconButton.styleFrom(
            backgroundColor: filled ? scheme.primary : Colors.transparent,
          ),
          icon: Icon(icon),
        );

    return PositionedDirectional(
      start: 16,
      end: 16,
      bottom: 12 + MediaQuery.paddingOf(context).bottom,
      child: Center(
        child: Material(
          color: Color.alphaBlend(
            foreground.withValues(alpha: 0.14),
            background,
          ),
          elevation: 3,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (speaking)
                  button(
                    Icons.skip_previous_rounded,
                    () => state.speakStep(-1),
                  ),
                button(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  speaking ? state.toggleSpeechPause : state.toggleAutoPause,
                  filled: true,
                ),
                if (speaking)
                  button(Icons.skip_next_rounded, () => state.speakStep(1)),
                const SizedBox(width: 4),
                button(Icons.remove_rounded, () => speed(-1)),
                SizedBox(
                  width: 48,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                button(Icons.add_rounded, () => speed(1)),
                const SizedBox(width: 4),
                button(
                  Icons.close_rounded,
                  speaking
                      ? state.stopSpeaking
                      : () => state.setAutoScroll(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _speech(BuildContext context, Color foreground) {
    final rate = state.settings.speechRate;
    void set(int v) =>
        state.updateSettings((s) => s.speechRate = v.clamp(50, 200));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _icon(
            foreground,
            Icons.remove_rounded,
            rate > 50 ? () => set(rate - 10) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$rate%',
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge,
            ),
          ),
          _icon(
            foreground,
            Icons.add_rounded,
            rate < 200 ? () => set(rate + 10) : null,
          ),
          const SizedBox(width: 16),
          _icon(
            foreground,
            Icons.skip_previous_rounded,
            () => state.speakStep(-1),
            tooltip: getString.novelSpeakPrevious,
          ),
          const SizedBox(width: 8),
          _icon(
            foreground,
            Icons.stop_rounded,
            state.stopSpeaking,
            active: true,
            tooltip: getString.novelSpeakStop,
          ),
          const SizedBox(width: 8),
          _icon(
            foreground,
            Icons.skip_next_rounded,
            () => state.speakStep(1),
            tooltip: getString.novelSpeakNext,
          ),
        ],
      ),
    );
  }

  Widget _speed(BuildContext context, Color foreground) {
    final speed = state.settings.autoScrollSpeed.clamp(1, 10);
    void set(int v) =>
        state.updateSettings((s) => s.autoScrollSpeed = v.clamp(1, 10));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _icon(
            foreground,
            Icons.remove_rounded,
            speed > 1 ? () => set(speed - 1) : null,
          ),
          SizedBox(
            width: 72,
            child: Text(
              '$speed',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _icon(
            foreground,
            Icons.add_rounded,
            speed < 10 ? () => set(speed + 1) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _options(BuildContext context) => showCustomBottomDialog<void>(
    context,
    AppSheet(
      title: getString.readerSettingsTitle,
      heightFactor: 0.85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        child: Watch(() {
          state.settingsVersion.value;
          final perTitle = state.perTitle.value;
          return SettingsGroup(
            key: ValueKey(perTitle),
            settings: [
              Setting.switchType(
                name: getString.readerPerTitle,
                description: getString.readerPerTitleDesc,
                icon: Icons.bookmark_rounded,
                isChecked: perTitle,
                onSwitchChange: state.setPerTitle,
              ),
              ...novelReaderRows(
                context,
                settings: state.settings,
                update: state.updateSettings,
              ),
            ],
          );
        }),
      ),
    ),
  );

  void _key(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.pageDown) {
      state.pageBy(1);
    } else if (key == LogicalKeyboardKey.pageUp) {
      state.pageBy(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      state.next();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      state.previous();
    } else if (key == LogicalKeyboardKey.keyM) {
      state.toggleControls();
    }
  }
}

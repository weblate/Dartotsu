import 'package:flutter/material.dart';

import '../../Core/State/State.dart';
import '../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../Utils/Extensions/ContextExtensions.dart';
import '../../Utils/Extensions/Responsive.dart';
import 'TogetherController.dart';

class TogetherChatPanel extends StatefulWidget {
  final TogetherController session;

  const TogetherChatPanel({super.key, required this.session});

  @override
  State<TogetherChatPanel> createState() => _TogetherChatPanelState();
}

class _TogetherChatPanelState extends State<TogetherChatPanel> {
  TogetherController get s => widget.session;

  final _message = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    s.unread.value = 0;
    s.sheetOpen = true;
  }

  @override
  void dispose() {
    s.sheetOpen = false;
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    s.sendChat(_message.text);
    _message.clear();
    _toEnd();
  }

  void _toEnd() {
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Watch(() {
    final scheme = context.colorScheme;
    final lines = s.chat.toList();
    return Column(
      children: [
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    getString.togetherNoChat,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.all(Dimens.pagePad),
                  itemCount: lines.length,
                  itemBuilder: (_, i) => TogetherChatLine(line: lines[i]),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimens.pagePad,
            Dimens.gapXs,
            Dimens.gapSm,
            Dimens.gapSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _message,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: getString.togetherChatHint,
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Dimens.gapXs),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                onPressed: s.connected ? _send : null,
              ),
            ],
          ),
        ),
      ],
    );
  });
}

class TogetherChatLine extends StatelessWidget {
  final ChatLine line;

  const TogetherChatLine({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    if (line.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            line.text,
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final mine = line.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine)
              Text(
                line.user,
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              line.text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: mine ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

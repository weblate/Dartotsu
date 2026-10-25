import 'dart:async';

import 'package:flutter/material.dart';

import '../../../Core/Cast/CastService.dart';
import '../../../Core/State/State.dart';
import '../../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../../Utils/Extensions/ContextExtensions.dart';
import '../../../Utils/Extensions/Responsive.dart';
import '../../../Widgets/Components/AppSheet.dart';
import '../../../Widgets/Components/CustomBottomDialog.dart';
import '../../../Widgets/Components/SheetTile.dart';
import '../PlayerState.dart';
import 'PlayerSeekBar.dart';

Future<void> showCastSheet(BuildContext context, PlayerState state) {
  final cast = state.cast;
  if (!cast.active) unawaited(cast.discover());
  return showCustomBottomDialog<void>(
    context,
    AppSheet(
      title: getString.castTitle,
      child: _CastPanel(state: state),
    ),
  );
}

String _protocolLabel(CastProtocol protocol) => switch (protocol) {
  CastProtocol.chromecast => getString.castProtocolChromecast,
  CastProtocol.dlna => getString.castProtocolDlna,
  CastProtocol.roku => getString.castProtocolRoku,
};

class _CastPanel extends StatelessWidget {
  final PlayerState state;

  const _CastPanel({required this.state});

  CastService get cast => state.cast;

  @override
  Widget build(BuildContext context) =>
      Watch(() => cast.active ? _controls(context) : _devices(context));

  Widget _devices(BuildContext context) {
    final scheme = context.colorScheme;
    final list = cast.devices.toList();
    final searching = cast.searching.value;
    return ListView(
      shrinkWrap: true,
      padding: Dimens.sheetInsets,
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getString.castSearching,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final device in list)
          SheetTile(
            tinted: true,
            leading: Icon(
              device.protocol == CastProtocol.roku
                  ? Icons.live_tv_rounded
                  : Icons.cast_rounded,
              color: scheme.primary,
            ),
            title: Text(device.name),
            subtitle: Text(_protocolLabel(device.protocol)),
            onTap: () {
              Navigator.of(context).pop();
              unawaited(state.castTo(device));
            },
          ),
        if (!searching && list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              getString.castNoDevices,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (!searching)
          Align(
            child: TextButton.icon(
              onPressed: () => unawaited(cast.discover()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(getString.castRefresh),
            ),
          ),
      ],
    );
  }

  Widget _controls(BuildContext context) {
    final scheme = context.colorScheme;
    final device = cast.device.value!;
    final position = cast.position.value;
    final total = cast.duration.value;
    final seekable = cast.canSeek && total > Duration.zero;
    final failure = cast.failure.value;
    return Padding(
      padding: Dimens.sheetInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cast_connected_rounded, size: 36, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            getString.castNowCasting(device.name),
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                failure,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          if (!cast.canSeek)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                getString.castRokuNote,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Slider(
            value: seekable
                ? position.inSeconds.clamp(0, total.inSeconds).toDouble()
                : 0,
            max: seekable ? total.inSeconds.toDouble() : 1,
            onChanged: seekable
                ? (v) => unawaited(cast.seek(Duration(seconds: v.round())))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatClock(position.inSeconds)),
                Text(total > Duration.zero ? formatClock(total.inSeconds) : ''),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                onPressed: cast.canSeek
                    ? () => unawaited(cast.seekBy(const Duration(seconds: -10)))
                    : null,
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 40,
                onPressed: () => unawaited(cast.toggle()),
                icon: Icon(
                  cast.playing.value
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 32,
                onPressed: cast.canSeek
                    ? () => unawaited(cast.seekBy(const Duration(seconds: 10)))
                    : null,
                icon: const Icon(Icons.forward_10_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(state.stopCasting());
            },
            icon: const Icon(Icons.cast_rounded),
            label: Text(getString.castStop),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

import '../../Core/State/State.dart';
import '../../Logger.dart';
import '../../Utils/Animation/WidgetAnimations.dart';
import '../../Utils/Lru.dart';

class BlurredImage extends StatefulWidget {
  final String url;
  final String? fallback;
  final double saturation;

  const BlurredImage({
    super.key,
    required this.url,
    this.fallback,
    this.saturation = 1,
  });

  static final _done = Lru<String, Uint8List>(24);
  static final _pending = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> load(String url, double saturation) {
    final key = '$saturation|$url';
    final hit = _done[key];
    if (hit != null) return SynchronousFuture(hit);
    return _pending[key] ??= () async {
      try {
        final file = File(url).isAbsolute
            ? File(url)
            : await DefaultCacheManager().getSingleFile(url);
        final bytes = await file.readAsBytes();
        final out = await compute(_blur, (bytes, saturation));
        _done[key] = out;
        return out;
      } catch (e) {
        logger('Blurred image failed: $e');
        return null;
      } finally {
        unawaited(_pending.remove(key));
      }
    }();
  }

  @override
  State<BlurredImage> createState() => _BlurredImageState();
}

Uint8List _blur((Uint8List, double) input) {
  final (bytes, saturation) = input;
  final source = img.decodeImage(bytes);
  if (source == null) throw StateError('decode');
  final portrait = source.height > source.width;
  var small = img.copyResize(
    source,
    width: portrait ? 128 : null,
    height: portrait ? null : 128,
    interpolation: img.Interpolation.average,
  );
  small = img.gaussianBlur(small, radius: 4);
  if (saturation != 1) small = img.adjustColor(small, saturation: saturation);
  return img.encodePng(small, level: 1);
}

class _BlurredImageState extends State<BlurredImage> {
  final _bytes = Live<Uint8List?>(null);
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(BlurredImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.saturation != widget.saturation) {
      _start();
    }
  }

  void _start() {
    final run = ++_run;
    final url = widget.url;
    final fallback = widget.fallback;
    unawaited(() async {
      var out = await BlurredImage.load(url, widget.saturation);
      if (out == null && fallback != null && fallback != url) {
        out = await BlurredImage.load(fallback, widget.saturation);
      }
      if (mounted && run == _run && out != null) _bytes.value = out;
    }());
  }

  @override
  Widget build(BuildContext context) => Watch(() {
    final bytes = _bytes.value;
    return AnimatedOpacity(
      opacity: bytes == null ? 0 : 1,
      duration: animDuration(350),
      child: bytes == null
          ? const SizedBox.expand()
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
    );
  });
}

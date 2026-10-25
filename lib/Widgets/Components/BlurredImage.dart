import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

import '../../Core/State/State.dart';
import '../../Utils/Functions/RefreshController.dart' show routeObserver;
import 'GlassSurface.dart';
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

  static final _done = Lru<String, ui.Image>(24);
  static final _pending = <String, Future<ui.Image?>>{};

  static ui.Image? peek(String url, double saturation) =>
      _done['$saturation|$url'];

  static Future<ui.Image?> load(String url, double saturation) {
    final key = '$saturation|$url';
    final hit = _done[key];
    if (hit != null) return SynchronousFuture(hit);
    return _pending[key] ??= () async {
      try {
        final file = File(url).isAbsolute
            ? File(url)
            : await DefaultCacheManager().getSingleFile(url);
        final bytes = await file.readAsBytes();
        final raw = await compute(_blur, (bytes, saturation));
        final out = await _decode(raw);
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

typedef _Raw = (int, int, Uint8List);

Future<ui.Image> _decode(_Raw raw) {
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    raw.$3,
    raw.$1,
    raw.$2,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  return done.future;
}

_Raw _blur((Uint8List, double) input) {
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
  final rgba = small.convert(numChannels: 4, alpha: 255);
  return (rgba.width, rgba.height, rgba.getBytes(order: img.ChannelOrder.rgba));
}

class _BlurredImageState extends State<BlurredImage> with RouteAware {
  final _image = Live<ui.Image?>(null);
  ModalRoute<dynamic>? _route;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() => _publish();

  @override
  void didPush() => _publish();

  void _publish() {
    final image = _image.value;
    if (image != null) GlassField.show(image);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
      if (mounted && run == _run && out != null) {
        _image.value = out;
        if (_route?.isCurrent ?? true) GlassField.show(out);
      }
    }());
  }

  @override
  Widget build(BuildContext context) => Watch(() {
    final image = _image.value;
    return AnimatedOpacity(
      opacity: image == null ? 0 : 1,
      duration: animDuration(350),
      child: image == null
          ? const SizedBox.expand()
          : RawImage(
              image: image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
            ),
    );
  });
}

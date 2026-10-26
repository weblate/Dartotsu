import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';

import '../../../Utils/Animation/WidgetAnimations.dart';
import '../../../Core/State/State.dart';
import 'ReaderImage.dart';
import 'ReaderPinch.dart';

class ReaderZoom extends StatefulWidget {
  final PageUrl page;
  final String scale;
  final bool doubleTap;
  final ValueChanged<bool> onZoom;

  const ReaderZoom({
    super.key,
    required this.page,
    required this.scale,
    required this.doubleTap,
    required this.onZoom,
  });

  @override
  State<ReaderZoom> createState() => _ReaderZoomState();
}

class _ReaderZoomState extends State<ReaderZoom>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _tween;
  Offset _tapAt = Offset.zero;
  bool _zoomed = false;
  final _pinching = false.live;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: animDuration(220))
      ..addListener(() {
        final t = _tween;
        if (t != null) _transform.value = t.value;
      });
  }

  @override
  void dispose() {
    widget.onZoom(false);
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _report() {
    final zoomed = (_transform.value.getMaxScaleOnAxis() - 1).abs() > 0.02;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoom(zoomed);
    }
  }

  void _release() {
    _report();
    if (_transform.value.getMaxScaleOnAxis() >= 1) return;
    _tween = Matrix4Tween(
      begin: _transform.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0).whenComplete(_report);
  }

  void _toggle() {
    final end = _zoomed
        ? Matrix4.identity()
        : Matrix4(
            2.5,
            0,
            0,
            0,
            0,
            2.5,
            0,
            0,
            0,
            0,
            1,
            0,
            -_tapAt.dx * 1.5,
            -_tapAt.dy * 1.5,
            0,
            1,
          );
    _tween = Matrix4Tween(
      begin: _transform.value,
      end: end,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0).whenComplete(_report);
  }

  Widget _pinch(Axis axis, Widget image) => ReaderPinch(
    pinching: _pinching,
    onZoom: widget.onZoom,
    pan: axis == Axis.vertical,
    child: Watch(
      () => SingleChildScrollView(
        scrollDirection: axis,
        physics: _pinching.value ? const NeverScrollableScrollPhysics() : null,
        child: image,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height >= size.width;
    final scale = widget.scale == 'smart'
        ? (portrait ? 'width' : 'fit')
        : widget.scale;
    if (scale == 'width') {
      return _pinch(
        Axis.vertical,
        ReaderImage(page: widget.page, fit: BoxFit.fitWidth, width: size.width),
      );
    }
    if (scale == 'height') {
      return _pinch(
        Axis.horizontal,
        ReaderImage(
          page: widget.page,
          fit: BoxFit.fitHeight,
          height: size.height,
        ),
      );
    }
    final image = ReaderImage(
      page: widget.page,
      fit: scale == 'original' ? BoxFit.none : BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
    return GestureDetector(
      onDoubleTapDown: widget.doubleTap
          ? (d) => _tapAt = d.localPosition
          : null,
      onDoubleTap: widget.doubleTap ? _toggle : null,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 0.5,
        maxScale: 5,
        onInteractionUpdate: (_) => _report(),
        onInteractionEnd: (_) => _release(),
        child: SizedBox.expand(child: image),
      ),
    );
  }
}

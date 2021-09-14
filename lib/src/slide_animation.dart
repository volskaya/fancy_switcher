import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// An animation widget for the [SwitchingImage] slide variant.
class SlideAnimation extends AnimatedWidget {
  /// Creates [SlideAnimation].
  const SlideAnimation({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key, listenable: animation);

  /// The animation to listen to.
  final Animation<double> animation;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = ui.lerpDouble(-24.0, 0.0, animation.value)!;
    final toggled = animation.value != 1.0;

    return ClipRect(
      clipBehavior: toggled ? Clip.hardEdge : Clip.none,
      clipper: _Clipper(value: animation.value),
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: child,
        toggled: toggled,
      ),
    );
  }
}

/// A clipper for the slide animation.
class _Clipper extends CustomClipper<Rect> {
  /// Creates [_Clipper].
  _Clipper({required this.value});

  /// The animation this clipper clips to.
  final double value;

  @override
  Rect getClip(Size size) => Offset.zero & Size(size.width * value, size.height);

  @override
  bool shouldReclip(_Clipper oldClipper) => value != oldClipper.value;
}

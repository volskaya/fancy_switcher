import 'package:fancy_switcher/fancy_switcher.dart';
import 'package:flutter/material.dart';

/// [SwitchingImage] wrapped around a [Material].
///
/// It's hard to paint a transitioning [Image] widget lookalike on
/// a material's canvas, so this is the next best thing.
class SwitchingMaterialImage extends StatelessWidget {
  /// Creates [SwitchingMaterialImage].
  const SwitchingMaterialImage({
    Key key,
    @required this.imageProvider,
    @required this.child,
    this.idleChild,
    this.layoutChildren = const <Widget>[],
    this.shape,
    this.duration = const Duration(milliseconds: 300),
    this.filterQuality = FilterQuality.low,
    this.fit = BoxFit.cover,
    this.elevation = 0,
    this.shadowColor,
  }) : super(key: key);

  /// [ImageProvider] to switch to.
  final ImageProvider imageProvider;

  /// While [SwitchingImage.imageProvider] is not loaded an optional
  /// [idleChild] will be built instead.
  final Widget idleChild;

  /// Clip shape of the animated switcher box.
  final ShapeBorder shape;

  /// Duration of the switch transition.
  final Duration duration;

  /// Filter quality of the image.
  final FilterQuality filterQuality;

  /// Box fit of the image.
  final BoxFit fit;

  /// Child [Widget] of the [Material].
  final Widget child;

  /// Children [Widget]'s on top of the [Material], in the switcher's layout builder.
  final Iterable<Widget> layoutChildren;

  /// [Material] elevation.
  final double elevation;

  /// [Material]'s shadow color.
  final Color shadowColor;

  @override
  Widget build(BuildContext context) => SwitchingImage(
        imageProvider: imageProvider,
        idleChild: idleChild,
        shape: shape,
        duration: duration,
        filterQuality: filterQuality,
        fit: fit,
        layoutChildren: [
          Material(
            type: MaterialType.transparency,
            shape: shape,
            child: child,
            elevation: elevation,
            shadowColor: shadowColor,
          ),
          ...layoutChildren,
        ],
      );
}

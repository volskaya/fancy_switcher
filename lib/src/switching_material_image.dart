import 'package:fancy_switcher/fancy_switcher.dart';
import 'package:flutter/material.dart';

/// [SwitchingImage] wrapped around a [Material].
///
/// It's hard to paint a transitioning [Image] widget lookalike on
/// a material's canvas, so this is the next best thing.
class SwitchingMaterialImage extends StatelessWidget {
  /// Creates [SwitchingMaterialImage].
  const SwitchingMaterialImage({
    Key? key,
    required this.imageProvider,
    required this.child,
    this.idleChild,
    this.layoutChildren = const <Widget>[],
    this.borderRadius,
    this.type,
    this.shape,
    this.duration,
    this.curve,
    this.filterQuality = FilterQuality.low,
    this.fit = BoxFit.cover,
    this.color,
    this.elevation = 0,
    this.shadowColor,
    this.resize = false,
    this.expandBox = true,
  }) : super(key: key);

  /// [ImageProvider] to switch to.
  final ImageProvider? imageProvider;

  /// While [SwitchingImage.imageProvider] is not loaded an optional
  /// [idleChild] will be built instead.
  final Widget? idleChild;

  /// Clip rect shape of the animated switcher box.
  final BorderRadius? borderRadius;

  /// Clip path shape of the animated switcher box.
  final ShapeBorder? shape;

  /// Duration of the switch transition.
  final Duration? duration;

  /// Curve of the switch transition.
  final Curve? curve;

  /// Filter quality of the image.
  final FilterQuality filterQuality;

  /// Box fit of the image.
  final BoxFit fit;

  /// Transition type used by the animated switcher within [SwitchingImage].
  final SwitchingImageType? type;

  /// Child [Widget] of the [Material].
  final Widget child;

  /// Children [Widget]'s on top of the [Material], in the switcher's layout builder.
  final Iterable<Widget> layoutChildren;

  /// [Material]'s elevation. Must define [color] to draw elevation.
  final double elevation;

  /// [Material]'s color. Must be defined to draw elevation.
  final Color? color;

  /// [Material]'s shadow color.
  final Color? shadowColor;

  /// Whether to use [ResizeImage] & [LayoutBuilder] on the image provider.
  final bool resize;

  /// Whether to wrap the widget in [SizedBox.expand].
  final bool expandBox;

  @override
  Widget build(BuildContext context) => SwitchingImage(
        imageProvider: imageProvider,
        idleChild: idleChild,
        borderRadius: borderRadius,
        shape: shape,
        duration: duration,
        filterQuality: filterQuality,
        fit: fit,
        curve: curve,
        type: type,
        expandBox: expandBox,
        layoutChildren: [
          RepaintBoundary(
            child: Material(
              type: color != null ? MaterialType.canvas : MaterialType.transparency,
              color: color,
              elevation: elevation,
              borderRadius: color != null ? borderRadius : null,
              shape: color != null ? shape : null,
              child: child,
              shadowColor: shadowColor,
            ),
          ),
          ...layoutChildren,
        ],
      );
}

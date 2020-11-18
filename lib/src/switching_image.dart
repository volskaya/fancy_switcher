import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fancy_switcher/src/fancy_switcher.dart';
import 'package:transparent_image/transparent_image.dart';

/// Transition types of the interal animated switcher of [SwitchingImage].
enum SwitchingImageType {
  /// Transitions with a fade in animation. Animation will try to optimize
  /// by animating images with their alpha color, when possible.
  fade,

  /// Transitions with the material scale switching animation from the
  /// animations package.
  scale,
}

/// Gapless image switcher.
///
/// HACK: Requires custom flutter patches to allow differentiating generated [RawImage]s.
class SwitchingImage extends StatelessWidget {
  /// Creates [SwitchingImage].
  const SwitchingImage({
    Key key,
    @required this.imageProvider,
    this.idleChild,
    this.idleOnly = false,
    this.layoutChildren = const <Widget>[],
    this.shape,
    this.duration,
    this.filterQuality = FilterQuality.low,
    this.fit = BoxFit.cover,
    this.type = SwitchingImageType.fade,
    this.opacity,
    this.alignment = AlignmentDirectional.topStart,
  }) : super(key: key);

  /// The default duration of transitions. Feel free to reassign this.
  static Duration transitionDuration = const Duration(milliseconds: 300);

  /// The default curve of transitions. Feel free to reassign this.
  /// This only works for [SwitchingImageType.fade] as the other types use transitions from the animations package.
  static Curve transitionCurve = decelerateEasing;

  /// [ImageProvider] to switch to.
  final ImageProvider imageProvider;

  /// While [SwitchingImage.imageProvider] is not loaded an optional
  /// [idleChild] will be built instead.
  final Widget idleChild;

  /// Children [Widget]'s on top of the [Material], in the switcher's layout builder.
  final Iterable<Widget> layoutChildren;

  /// Convenience boolean to return early, with no animated switching logic.
  final bool idleOnly;

  /// Clip shape of the animated switcher box.
  final ShapeBorder shape;

  /// Duration of the switch transition.
  final Duration duration;

  /// Filter quality of the image.
  final FilterQuality filterQuality;

  /// Box fit of the image.
  final BoxFit fit;

  /// Transition type used by the animated switcher within [SwitchingImage].
  final SwitchingImageType type;

  /// Opacity override when you wish to animate the image without having to overlap
  /// multiple opacity shaders.
  final ValueListenable<double> opacity;

  /// Alignment of the children in the switchers.
  final AlignmentGeometry alignment;

  /// Transparent image used as an identifier for when there's no actual image loaded.
  static final transparentImage = MemoryImage(kTransparentImage, scale: 1);

  /// Creates a copy of [SwitchingImage].
  SwitchingImage copyWith({
    ImageProvider imageProvider,
    Widget idleChild,
    bool idleOnly,
    Duration duration,
    FilterQuality filterQuality,
    ShapeBorder shape,
    BoxFit fit,
    SwitchingImageType type,
    ValueListenable<double> opacity,
  }) =>
      SwitchingImage(
        key: key,
        imageProvider: imageProvider ?? this.imageProvider,
        idleChild: idleChild ?? this.idleChild,
        idleOnly: idleOnly ?? this.idleOnly,
        duration: duration ?? this.duration,
        filterQuality: filterQuality ?? this.filterQuality,
        shape: shape ?? this.shape,
        fit: fit ?? this.fit,
        type: type ?? this.type,
        opacity: opacity ?? this.opacity,
      );

  /// Default fade transition of [SwitchingImage].
  static Widget fadeTransition(
    Widget widget,
    Animation<double> animation, [
    ValueListenable<double> opacity,
    Widget Function(Widget child) wrap,
  ]) {
    // If a switched in object animates out,
    // its animation will be at 1.0 - isCompleted
    if (animation.isCompleted && opacity == null) {
      return widget is RawImage
          ? RepaintBoundary(
              key: widget.key,
              child: wrap?.call(widget) ?? widget,
            )
          : wrap?.call(widget) ?? widget;
    }

    // No shader opacity optimization by setting the color opacity on the image.
    if (widget is RawImage) {
      return AnimatedBuilder(
        animation: opacity != null ? Listenable.merge([animation, opacity]) : animation,
        builder: (_, __) {
          // Copy the [RawImage] with a new color.
          final value = opacity != null ? math.min(opacity.value, animation.value) : animation.value;
          final image = RawImage(
            key: widget.key,
            height: widget.height,
            width: widget.width,
            alignment: widget.alignment,
            fit: widget.fit,
            scale: widget.scale,
            repeat: widget.repeat,
            centerSlice: widget.centerSlice,
            isAntiAlias: widget.isAntiAlias,
            invertColors: widget.invertColors,
            filterQuality: widget.filterQuality,
            debugImageLabel: widget.debugImageLabel,
            matchTextDirection: widget.matchTextDirection,
            image: widget.image,
            colorBlendMode: BlendMode.modulate,
            color: Color.fromRGBO(255, 255, 255, value),
          );

          return RepaintBoundary(
            key: widget.key,
            child: wrap?.call(image) ?? image,
          );
        },
      );
    } else {
      return FadeTransition(
        opacity: animation,
        child: RepaintBoundary(key: widget.key, child: wrap?.call(widget) ?? widget),
      );
    }
  }

  /// Default layout builder of [SwitchingImage].
  static Widget layoutBuilder(
    Widget currentChild,
    Iterable<Widget> previousChildren, [
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    Iterable<Widget> layoutChildren = const <Widget>[],
  ]) =>
      Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        alignment: alignment,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
          ...layoutChildren,
        ],
      );

  /// If [SwitchingImage.shape] is not null, wrap the image in [ClipPath].
  Widget _withClipper({@required Widget child}) => shape != null
      ? ClipPath(
          key: child?.key ?? ValueKey(child.runtimeType),
          clipper: ShapeBorderClipper(shape: shape),
          child: child,
        )
      : child;

  /// HACK: Raw image keys require a patch for flutter source.
  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int frame,
    bool wasSynchronouslyLoaded,
  ) {
    final rawImage = child as RawImage;
    final hasFrames = frame != null || wasSynchronouslyLoaded;
    final hasGaplessImage = rawImage.image != null;
    final key = rawImage?.key as ObjectKey;
    final isNotTransparent = key?.value != SwitchingImage.transparentImage;
    final switcherChild = isNotTransparent && (hasFrames || hasGaplessImage) ? rawImage : _idleChild;

    // assert(
    //   switcherChild.key != null,
    //   'Missing flutter patch with keys on [RawImage] objects',
    // );

    switch (type) {
      case SwitchingImageType.scale:
        return FancySwitcher(
          duration: duration ?? SwitchingImage.transitionDuration,
          alignment: alignment,
          addRepaintBoundary: false,
          wrapChildrenInRepaintBoundary: false,
          child: _withClipper(child: switcherChild),
        );
      case SwitchingImageType.fade:
        return AnimatedSwitcher(
          duration: duration ?? SwitchingImage.transitionDuration,
          switchInCurve: SwitchingImage.transitionCurve,
          switchOutCurve: const Threshold(0),
          child: switcherChild,
          layoutBuilder: (child, children) => SwitchingImage.layoutBuilder(child, children, alignment, layoutChildren),
          transitionBuilder: (context, animation) => SwitchingImage.fadeTransition(
            context,
            animation,
            opacity,
            (child) => _withClipper(child: child),
          ),
        );
      default:
        throw UnimplementedError();
    }
  }

  Widget get _idleChild => SizedBox.expand(child: idleChild);

  @override
  Widget build(BuildContext context) {
    if (idleOnly) _idleChild;

    return SizedBox.expand(
      child: RepaintBoundary(
        child: Image(
          image: imageProvider ?? SwitchingImage.transparentImage,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          filterQuality: filterQuality,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          frameBuilder: _frameBuilder,
        ),
      ),
    );
  }
}

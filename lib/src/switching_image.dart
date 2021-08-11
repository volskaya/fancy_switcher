import 'dart:math' as math;

import 'package:fancy_switcher/src/fancy_switcher.dart';
import 'package:fancy_switcher/src/slide_animation.dart';
import 'package:fancy_switcher/src/transparent_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Transition types of the interal animated switcher of [SwitchingImage].
enum SwitchingImageType {
  /// Transitions with a fade in animation. Animation will try to optimize
  /// by animating images with their alpha color, when possible.
  fade,

  /// Transitions with the material scale switching animation from the
  /// animations package.
  scale,

  /// A slide animation, that also "clips" the picture open.
  slide,
}

/// Gapless image switcher.
///
/// HACK: Requires custom flutter patches to allow differentiating generated [RawImage]s.
class SwitchingImage extends StatelessWidget {
  /// Creates [SwitchingImage].
  const SwitchingImage({
    Key? key,
    required this.imageProvider,
    this.idleChild,
    this.layoutChildren = const <Widget>[],
    this.borderRadius,
    this.shape,
    this.duration,
    this.curve,
    this.filterQuality = FilterQuality.low,
    this.fit = BoxFit.cover,
    this.type,
    this.opacity,
    this.alignment = AlignmentDirectional.topStart,
    this.addRepaintBoundary = true,
    this.resize = false,
    this.expandBox = false,
    this.optimizeFade,
    this.areSimilar,
  })  : colorBlendMode = null,
        color = null,
        filter = false,
        super(key: key);

  /// Creates a fading [SwitchingImage] with a filter.
  /// The filter is only applied to the [RawImage]s.
  const SwitchingImage.filter({
    Key? key,
    required this.imageProvider,
    required this.color,
    this.colorBlendMode = BlendMode.saturation,
    this.idleChild,
    this.layoutChildren = const <Widget>[],
    this.borderRadius,
    this.shape,
    this.duration,
    this.curve,
    this.filterQuality = FilterQuality.low,
    this.fit = BoxFit.cover,
    this.opacity,
    this.alignment = AlignmentDirectional.topStart,
    this.addRepaintBoundary = true,
    this.resize = false,
    this.expandBox = false,
    this.optimizeFade,
    this.areSimilar,
  })  : type = SwitchingImageType.fade,
        filter = true,
        super(key: key);

  /// The default duration of transitions. Feel free to reassign this.
  static Duration transitionDuration = const Duration(milliseconds: 300);

  /// The default curve of transitions. Feel free to reassign this.
  /// This only works for [SwitchingImageType.fade] as the other types use transitions from the animations package.
  static Curve transitionCurve = decelerateEasing;

  /// The default type of [SwitchingImage]s.
  static SwitchingImageType transitionType = SwitchingImageType.fade;

  static bool skipAnimationForSimilarImages = false;

  /// When this is set to `true`, the image switching animation will animate
  /// the alpha color of the image, if the animating child is [RawImage].
  static bool enableRawImageOptimization = true;

  /// Transparent image used as an identifier for when there's no actual image loaded.
  static final transparentImage = MemoryImage(kTransparentImage, scale: 1);

  /// [ImageProvider] to switch to.
  final ImageProvider? imageProvider;

  /// While [SwitchingImage.imageProvider] is not loaded an optional
  /// [idleChild] will be built instead.
  final Widget? idleChild;

  /// Children [Widget]'s on top of the [Material], in the switcher's layout builder.
  final Iterable<Widget> layoutChildren;

  /// Clip rect shape of the animated switcher box.
  final BorderRadius? borderRadius;

  /// Clip shape of the animated switcher box.
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

  /// Opacity override when you wish to animate the image without having to overlap
  /// multiple opacity shaders.
  final ValueListenable<double>? opacity;

  /// Alignment of the children in the switchers.
  final AlignmentGeometry alignment;

  /// Blend mode of the internal [ColorFiltered] filter.
  final BlendMode? colorBlendMode;

  /// Color of the internal [ColorFiltered] filter.
  final Color? color;

  /// Whether to wrap images in a [ColorFiltered] widget.
  final bool filter;

  /// Whether to wrap images in a [RepaintBoundary] widget.
  final bool addRepaintBoundary;

  /// Whether to use [ResizeImage] & [LayoutBuilder] on the image provider.
  final bool resize;

  /// Whether to wrap the widget in [SizedBox.expand].
  final bool expandBox;

  /// Override for [SwitchingImage.enableRawImageOptimization].
  final bool? optimizeFade;

  /// [Image] widget similarity check.
  final SimilarImageEqualityCallback? areSimilar;

  /// Default fade transition of [SwitchingImage].
  static Widget fadeTransition(
    SwitchingImageType type,
    Widget widget,
    Animation<double> animation, {
    ValueListenable<double>? opacity,
    Widget Function(Widget child)? wrap,
    BlendMode? colorBlendMode,
    Color? color,
    bool filter = false,
    bool optimizeFade = false,
  }) {
    final isSimilar = widget is RawImage && widget.wasSimilar;

    // If a switched in object animates out,
    // its animation will be at 1.0 - isCompleted.
    //
    // FIXME: This causes a relayout.
    if (isSimilar && skipAnimationForSimilarImages) {
      return wrap?.call(widget) ?? widget;
    }

    // If the image is similar, fallback to fade animations.
    if (!isSimilar) {
      switch (type) {
        case SwitchingImageType.slide:
          return SlideAnimation(
            animation: animation,
            child: wrap?.call(widget) ?? widget,
          );
        default: // Pass through.
      }
    }

    // No shader opacity optimization by setting the color opacity on the image.
    if (optimizeFade && widget is RawImage) {
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
            colorBlendMode: value != 1 ? BlendMode.modulate : null,
            color: value != 1 ? Color.fromRGBO(255, 255, 255, value) : null,
          );

          return wrap?.call(image) ?? image;
        },
      );
    } else {
      return FadeTransition(
        opacity: animation,
        child: wrap?.call(widget) ?? widget,
      );
    }
  }

  /// Default layout builder of [SwitchingImage].
  static Widget layoutBuilder(
    Widget? currentChild,
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

  /// If [SwitchingImage.borderRadius] is not null, wrap the image in [ClipPath].
  Widget _withWrap(Widget _child, {bool useFilter = false}) {
    final shouldFilter = useFilter && filter && _child is RawImage;
    final shouldShape = shape != null || borderRadius != null;

    Widget child = _child;

    // Both `colorBlendMode` and `color` will be passed, if [SwitchingImage]
    // is supposed to use the filter.
    if (shouldFilter && color != null && colorBlendMode != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, colorBlendMode!),
        child: child,
      );
    }

    if (shouldShape) {
      child = shape != null
          ? ClipPath(clipper: ShapeBorderClipper(shape: shape!), child: child)
          : ClipRRect(borderRadius: borderRadius, child: child);
    }

    return RepaintBoundary(key: _child.key, child: child);
  }

  /// HACK: Raw image keys require a patch for Flutter.
  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    final type = this.type ?? transitionType;
    final rawImage = child as RawImage?;
    final hasFrames = frame != null || wasSynchronouslyLoaded;
    final hasGaplessImage = rawImage?.image != null;
    final key = rawImage?.key as ObjectKey?;
    final isNotTransparent = key?.value != SwitchingImage.transparentImage;
    final switcherChild = isNotTransparent && (hasFrames || hasGaplessImage) ? rawImage : _idleChild;

    switch (type) {
      case SwitchingImageType.scale:
        return FancySwitcher(
          duration: duration ?? SwitchingImage.transitionDuration,
          alignment: alignment,
          addRepaintBoundary: false,
          wrapChildrenInRepaintBoundary: false, // Handled by the wrap.
          child: switcherChild != null ? _withWrap(switcherChild, useFilter: true) : null,
        );
      case SwitchingImageType.slide:
      case SwitchingImageType.fade:
        final switcher = AnimatedSwitcher(
          duration: duration ?? SwitchingImage.transitionDuration,
          switchInCurve: curve ?? SwitchingImage.transitionCurve,
          switchOutCurve: const Threshold(0),
          child: switcherChild,
          layoutBuilder: (child, children) => SwitchingImage.layoutBuilder(child, children, alignment, layoutChildren),
          transitionBuilder: (context, animation) => SwitchingImage.fadeTransition(
            type,
            context,
            animation,
            opacity: opacity,
            wrap: _withWrap,
            colorBlendMode: colorBlendMode,
            color: color,
            filter: filter,
            optimizeFade: optimizeFade ?? SwitchingImage.enableRawImageOptimization,
          ),
        );

        return filter
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(color!, colorBlendMode!),
                child: switcher,
              )
            : switcher;
    }
  }

  Widget get _idleChild => SizedBox.expand(child: idleChild);

  Widget _buildImage(BuildContext _, [BoxConstraints? constraints]) => Image(
        fit: fit,
        width: expandBox ? double.infinity : null,
        height: expandBox ? double.infinity : null,
        filterQuality: filterQuality,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        frameBuilder: _frameBuilder,
        areSimilar: areSimilar,
        image: imageProvider != null
            ? constraints != null
                ? ResizeImage(
                    imageProvider!,
                    width: (constraints.biggest.width * WidgetsBinding.instance!.window.devicePixelRatio).round(),
                    height: (constraints.biggest.height * WidgetsBinding.instance!.window.devicePixelRatio).round(),
                  )
                : imageProvider!
            : SwitchingImage.transparentImage,
      );

  @override
  Widget build(BuildContext context) {
    final image = resize ? LayoutBuilder(builder: _buildImage) : _buildImage(context);
    final repaintBoundary = addRepaintBoundary ? RepaintBoundary(child: image) : image;
    return expandBox ? SizedBox.expand(child: repaintBoundary) : repaintBoundary;
  }
}

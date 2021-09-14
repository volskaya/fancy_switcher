// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This builder allows passing in an external opacity override and
/// also inheriting the opacity from [InheritedAnimation].
class SwitchingImageOpacityBuilder extends StatefulWidget {
  const SwitchingImageOpacityBuilder({
    Key? key,
    required this.builder,
    this.transition,
    this.opacityOverride,
  }) : super(key: key);

  final Animation<double>? transition;
  final Animation<double>? opacityOverride;
  final Widget Function(BuildContext context, Animation<double> opacity) builder;

  @override
  _SwitchingImageOpacityBuilderState createState() => _SwitchingImageOpacityBuilderState();
}

class _SwitchingImageOpacityBuilderState extends State<SwitchingImageOpacityBuilder> with InheritedAnimationMixin {
  late _OpacityAnimation _animation;

  void _handleAnimationChange() {
    _animation = _OpacityAnimation(
      transition: widget.transition,
      opacityOverride: widget.opacityOverride,
      inherited: inheritedAnimation,
    );
  }

  @override
  void didChangeInheritedAnimation(InheritedAnimation? oldAnimation, InheritedAnimation? animation) {
    super.didChangeInheritedAnimation(oldAnimation, animation);
    _handleAnimationChange();
  }

  @override
  void initState() {
    _handleAnimationChange();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SwitchingImageOpacityBuilder oldWidget) {
    final changedTransition = oldWidget.transition != widget.transition;
    final changedOpacityOverride = oldWidget.opacityOverride != widget.opacityOverride;

    if (changedTransition != changedOpacityOverride) {
      _handleAnimationChange();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.transition?.removeListener(markNeedsBuild);
    widget.opacityOverride?.removeListener(markNeedsBuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _animation);
}

/// A single animation for [SwitchingImageOpacityBuilder] to pass down
/// to [RawImage].
///
/// There are some similarities with [CompoundAnimation].
class _OpacityAnimation extends Animation<double>
    with AnimationLazyListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  _OpacityAnimation({
    this.transition,
    this.opacityOverride,
    this.inherited,
  });

  final Animation<double>? transition;
  final Animation<double>? opacityOverride;
  final InheritedAnimation? inherited;

  @override
  double get value {
    final value = transition?.value ?? 1.0;
    final transitionOpacity = opacityOverride != null ? math.min(opacityOverride!.value, value) : value;
    final effectiveOpacity = inherited != null ? math.min(inherited!.opacity, transitionOpacity) : transitionOpacity;

    return effectiveOpacity;
  }

  /// Gets the status of this animation based on the [transition] and [override?] status.
  ///
  /// The default is that if the [override] animation is moving, use its status.
  /// Otherwise, default to [transition].
  @override
  AnimationStatus get status {
    if (opacityOverride?.status == AnimationStatus.forward || opacityOverride?.status == AnimationStatus.reverse) {
      return opacityOverride!.status;
    }
    return transition?.status ?? AnimationStatus.completed;
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CompoundAnimation')}($transition, $override?)';
  }

  AnimationStatus? _lastStatus;
  void _maybeNotifyStatusListeners(AnimationStatus _) {
    if (status != _lastStatus) {
      _lastStatus = status;
      notifyStatusListeners(status);
    }
  }

  double? _lastValue;
  void _maybeNotifyListeners() {
    if (value != _lastValue) {
      _lastValue = value;
      notifyListeners();
    }
  }

  @override
  void didStartListening() {
    transition?.addListener(_maybeNotifyListeners);
    transition?.addStatusListener(_maybeNotifyStatusListeners);
    opacityOverride?.addListener(_maybeNotifyListeners);
    opacityOverride?.addStatusListener(_maybeNotifyStatusListeners);
    inherited?.addListener(_maybeNotifyListeners);
  }

  @override
  void didStopListening() {
    transition?.removeListener(_maybeNotifyListeners);
    transition?.removeStatusListener(_maybeNotifyStatusListeners);
    opacityOverride?.removeListener(_maybeNotifyListeners);
    opacityOverride?.removeStatusListener(_maybeNotifyStatusListeners);
    inherited?.removeListener(_maybeNotifyListeners);
  }
}

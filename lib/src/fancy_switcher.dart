import 'dart:async';

import 'package:await_route/await_route.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/scheduler.dart';

enum _FancySwitcherType { fade, axisVertical, axisHorizontal, scaled }

/// Fancy switcher that wraps transitions of the `animations` package
class FancySwitcher extends StatefulWidget {
  /// Creates a [FancySwitcher] with the material fade transition.
  const FancySwitcher({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
  }) : _type = _FancySwitcherType.fade;

  /// Creates a [FancySwitcher] with the material vertical axis transition.
  const FancySwitcher.vertical({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
  }) : _type = _FancySwitcherType.axisVertical;

  /// Creates a [FancySwitcher] with the material horizontal axis transition.
  const FancySwitcher.horizontal({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
  }) : _type = _FancySwitcherType.axisHorizontal;

  /// Creates a [FancySwitcher] with the material scale transition;
  const FancySwitcher.scaled({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
  }) : _type = _FancySwitcherType.scaled;

  /// Animated child of [FancySwitcher].
  final Widget child;

  /// Temporary child to build when using [delay], before the real [child] is built.
  final Widget placeholder;

  /// Box alignment of children within the animated switcher.
  final AlignmentGeometry alignment;

  /// Callback when the transation ends.
  final VoidCallback onEnd;

  /// The duration of the switch animation.
  final Duration duration;

  /// Delay of the switch.
  final Duration delay;

  /// The type of the switcher.
  final _FancySwitcherType _type;

  /// Wrap the transition in a [RepaintBoundary].
  final bool addRepaintBoundary;

  /// Wrap the child widgets in a [RepaintBoundary].
  final bool wrapChildrenInRepaintBoundary;

  /// Show a placeholder widget, until the route has animated in.
  final bool awaitRoute;

  @override
  _FancySwitcherState createState() => _FancySwitcherState();
}

class _FancySwitcherState extends State<FancySwitcher> {
  Widget _child;
  Widget get _placeholder => widget.placeholder ?? const SizedBox(key: ValueKey('placeholder'));

  Future _scheduleChild(Widget child) async {
    assert(widget.awaitRoute || widget.delay > Duration.zero);

    if (widget.awaitRoute) await AwaitRoute.of(context);
    if (widget.delay > Duration.zero) await Future<void>.delayed(widget.delay);
    if (mounted && widget.child == child) setState(() => _child = widget.child);
  }

  @override
  void didChangeDependencies() {
    if (_child == null) {
      if (widget.delay > Duration.zero || widget.awaitRoute) {
        _child = _placeholder;
        if (widget.child != null) _scheduleChild(widget.child);
      } else {
        _child = widget.child ?? _placeholder;
      }
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant FancySwitcher oldWidget) {
    final oldComparable = oldWidget.child?.key ?? oldWidget.child;
    final newComparable = widget.child?.key ?? widget.child;

    if (oldComparable != newComparable) {
      if (widget.delay > Duration.zero || widget.awaitRoute) {
        _scheduleChild(widget.child);
      } else {
        _child = widget.child ?? _placeholder;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget _transition(
    Widget child,
    Animation<double> primaryAnimation,
    Animation<double> secondaryAnimation,
  ) {
    switch (widget._type) {
      case _FancySwitcherType.fade:
        return FadeThroughTransition(
          child: child,
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          onEnd: widget.onEnd,
          fillColor: Colors.transparent,
        );
      case _FancySwitcherType.axisVertical:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          onEnd: widget.onEnd,
          fillColor: Colors.transparent,
        );
      case _FancySwitcherType.axisHorizontal:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
          onEnd: widget.onEnd,
          fillColor: Colors.transparent,
        );
      case _FancySwitcherType.scaled:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
          onEnd: widget.onEnd,
          fillColor: Colors.transparent,
        );
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _child != null
        ? widget.wrapChildrenInRepaintBoundary
            ? RepaintBoundary(
                key: FancySwitcherTag.maybeGetKey(_child),
                child: _child,
              )
            : KeyedSubtree(
                key: FancySwitcherTag.maybeGetKey(_child),
                child: _child,
              )
        : null;

    final transition = PageTransitionSwitcher(
      transitionBuilder: _transition,
      alignment: widget.alignment,
      child: child,
      duration: widget.duration,
    );

    return widget.addRepaintBoundary ? RepaintBoundary(child: transition) : transition;
  }
}

/// Tag widget that allows [FancySwitcher] to differentiate the same animating widget types.
///
/// Flutter recently changed the behavior of keys - when the key doesn't change, the widget won't rebuild
/// on prop changes as well. Note, this might be a bug. I can't reproduce this behavior on a vanilla flutter project.
///
/// FIXME: Remove usage of [FancySwitcherTag] when regular keys are fixed.
class FancySwitcherTag extends StatelessWidget {
  /// Creates [FancySwitcherTag].
  const FancySwitcherTag({
    Key key,
    @required this.tag,
    @required this.child,
  }) : super(key: key);

  /// The tag that's gonna be compared against another switcher child.
  final dynamic tag;

  /// Child [Widget] of this [FancySwitcherTag].
  final Widget child;

  /// Attempts to extract [FancySwitcherTag] tag as a [ValueKey] from the [child].
  /// If the child is not a [FancySwitcherTag], default to it's own key or runtime key.
  static Key maybeGetKey(Widget child) => child != null
      ? child is FancySwitcherTag
          ? ValueKey<dynamic>(child.tag)
          : (child.key ?? ValueKey(child.runtimeType))
      : null;

  @override
  Widget build(BuildContext context) => child;
}

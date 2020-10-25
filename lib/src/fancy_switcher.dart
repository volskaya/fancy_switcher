import 'dart:async';

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
  }) : _type = _FancySwitcherType.fade;

  /// Creates a [FancySwitcher] with the material vertical axis transition.
  const FancySwitcher.vertical({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
  }) : _type = _FancySwitcherType.axisVertical;

  /// Creates a [FancySwitcher] with the material horizontal axis transition.
  const FancySwitcher.horizontal({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
  }) : _type = _FancySwitcherType.axisHorizontal;

  /// Creates a [FancySwitcher] with the material scale transition;
  const FancySwitcher.scaled({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.placeholder,
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

  @override
  _FancySwitcherState createState() => _FancySwitcherState();
}

class _FancySwitcherState extends State<FancySwitcher> {
  Widget _child;
  Timer _timer;

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleChildSwap() {
    assert(widget.delay > Duration.zero);
    _timer = Timer(widget.delay * timeDilation, () => setState(() => _child = widget.child));
  }

  @override
  void initState() {
    if (widget.delay > Duration.zero) {
      _child = widget.placeholder ?? const SizedBox();
      _scheduleChildSwap();
    } else {
      _child = widget.child;
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FancySwitcher oldWidget) {
    _cancelTimer();

    final oldComparable = oldWidget.child?.key ?? oldWidget.child;
    final newComparable = widget.child?.key ?? widget.child;

    if (oldComparable != newComparable) widget.delay > Duration.zero ? _scheduleChildSwap() : _child = widget.child;
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
  Widget build(BuildContext context) => RepaintBoundary(
        child: PageTransitionSwitcher(
          transitionBuilder: _transition,
          alignment: widget.alignment,
          child: _child,
          duration: widget.duration,
        ),
      );
}

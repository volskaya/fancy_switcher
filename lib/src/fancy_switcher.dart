import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

enum _FancySwitcherType { fade, axisVertical, axisHorizontal, scaled }

/// Fancy switcher that wraps transitions of the `animations` package
class FancySwitcher extends StatefulWidget {
  /// Creates a [FancySwitcher] with the material fade transition.
  const FancySwitcher({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.onEnd,
  }) : _type = _FancySwitcherType.fade;

  /// Creates a [FancySwitcher] with the material vertical axis transition.
  const FancySwitcher.vertical({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.onEnd,
  }) : _type = _FancySwitcherType.axisVertical;

  /// Creates a [FancySwitcher] with the material horizontal axis transition.
  const FancySwitcher.horizontal({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.onEnd,
  }) : _type = _FancySwitcherType.axisHorizontal;

  /// Creates a [FancySwitcher] with the material scale transition;
  const FancySwitcher.scaled({
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.onEnd,
  }) : _type = _FancySwitcherType.scaled;

  /// Animated child of [FancySwitcher].
  final Widget child;

  /// Box alignment of children within the animated switcher.
  final Alignment alignment;

  /// Callback when the transation ends.
  final VoidCallback onEnd;

  /// The duration of the switch animation.
  final Duration duration;

  /// The type of the switcher.
  final _FancySwitcherType _type;

  @override
  _FancySwitcherState createState() => _FancySwitcherState();
}

class _FancySwitcherState extends State<FancySwitcher> {
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
          child: widget.child,
          duration: widget.duration,
        ),
      );
}

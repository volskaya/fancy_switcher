import 'dart:async';

import 'package:await_route/await_route.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/scheduler.dart';

enum _FancySwitcherType { fade, axisVertical, axisHorizontal, scaled }

class _ChildEntry {
  /// If the widget is a [FancySwitcherTag] and its tag is an int,
  /// it's assumed as an index to support reverse switches.
  factory _ChildEntry.fromWidget(Widget widget) {
    final dynamic tag = FancySwitcherTag.getTag(widget);
    final key = FancySwitcherTag.getKey(widget);
    final index = tag is int ? tag : null;

    return _ChildEntry._(widget, key, index);
  }

  _ChildEntry._(this.widget, this.key, [this.index]);

  final Widget widget;
  final Key key;
  final int index;
}

/// Fancy switcher that wraps transitions of the `animations` package
class FancySwitcher extends StatefulWidget {
  /// Creates a [FancySwitcher] with the material fade transition.
  const FancySwitcher({
    Key key,
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = true,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
  })  : _type = _FancySwitcherType.fade,
        super(key: key);

  /// Creates a [FancySwitcher] with the material vertical axis transition.
  const FancySwitcher.vertical({
    Key key,
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = true,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
  })  : _type = _FancySwitcherType.axisVertical,
        super(key: key);

  /// Creates a [FancySwitcher] with the material horizontal axis transition.
  const FancySwitcher.horizontal({
    Key key,
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = true,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
  })  : _type = _FancySwitcherType.axisHorizontal,
        super(key: key);

  /// Creates a [FancySwitcher] with the material scale transition;
  const FancySwitcher.scaled({
    Key key,
    @required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = true,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
  })  : _type = _FancySwitcherType.scaled,
        super(key: key);

  /// Animated child of [FancySwitcher].
  final Widget child;

  /// Temporary child to build when using [delay], before the real [child] is built.
  final Widget placeholder;

  /// Box alignment of children within the animated switcher.
  final AlignmentGeometry alignment;

  /// Callback when the transation ends.
  final VoidCallback onEnd;

  /// Callback when the animation status changes. This is called before [onEnd].
  final ValueChanged<AnimationStatus> onStatusChanged;

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

  /// Fill color built into some transitions. Setting this makes the animation look more materialy, I guess…
  ///
  /// Should usually either be transparent or match the background of the switchers container.
  final Color fillColor;

  @override
  _FancySwitcherState createState() => _FancySwitcherState();
}

class _FancySwitcherState extends State<FancySwitcher> {
  _ChildEntry _child;
  bool _reverse = false;
  Widget get _placeholder => widget.placeholder ?? const SizedBox(key: ValueKey('placeholder'));

  static bool _compareChildren(Widget a, Widget b) => (a?.key ?? a) == (b?.key ?? b);

  // When the entries are swapped, their index is compared to determine if
  // the next switch should animate in reverse.
  void _swapChildEntries(Widget child) {
    final entry = child != null ? _ChildEntry.fromWidget(child) : null;
    if (_child?.index != null && entry?.index != null) {
      assert(entry.index != _child.index);
      _reverse = entry.index < _child.index ? true : false;
    } else {
      _reverse = false;
    }
    _child = entry;
  }

  Future _scheduleChild(Widget child) async {
    assert(widget.awaitRoute || widget.delay > Duration.zero);

    if (widget.awaitRoute) await AwaitRoute.of(context);
    if (widget.delay > Duration.zero) await Future<void>.delayed(widget.delay * timeDilation);
    if (mounted && _compareChildren(widget.child, child)) setState(() => _swapChildEntries(widget.child));
  }

  @override
  void didChangeDependencies() {
    if (_child == null) {
      if (widget.delay > Duration.zero || widget.awaitRoute) {
        _swapChildEntries(_placeholder);
        if (widget.child != null) _scheduleChild(widget.child);
      } else {
        _swapChildEntries(widget.child ?? _placeholder);
      }
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant FancySwitcher oldWidget) {
    if (!_compareChildren(oldWidget.child, widget.child)) {
      if (widget.delay > Duration.zero || widget.awaitRoute) {
        _scheduleChild(widget.child);
      } else {
        _swapChildEntries(widget.child ?? _placeholder);
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
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case _FancySwitcherType.axisVertical:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case _FancySwitcherType.axisHorizontal:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case _FancySwitcherType.scaled:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _child != null
        ? true && widget.wrapChildrenInRepaintBoundary
            ? RepaintBoundary(key: _child.key, child: _child.widget)
            : KeyedSubtree(key: _child.key, child: _child.widget)
        : null;

    final transition = PageTransitionSwitcher(
      transitionBuilder: _transition,
      alignment: widget.alignment,
      child: child,
      duration: widget.duration,
      reverse: _reverse,
    );

    return true && widget.addRepaintBoundary ? RepaintBoundary(child: transition) : transition;
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
  static Key getKey(Widget child) => child != null
      ? child is FancySwitcherTag
          ? ValueKey<dynamic>(child.tag)
          : (child.key ?? ValueKey(child.runtimeType))
      : null;

  /// Attempt to get the dynamic tag out of [FancySwitcherTag].
  static dynamic getTag(Widget child) => child != null && child is FancySwitcherTag ? child.tag : null;

  @override
  Widget build(BuildContext context) => child;
}

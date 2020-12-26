import 'dart:async';

import 'package:await_route/await_route.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/scheduler.dart';

enum FancySwitcherType { fade, axisVertical, axisHorizontal, scaled }

class _ChildEntry {
  /// If the widget is a [FancySwitcherTag] and its tag is an int,
  /// it's assumed as an index to support reverse switches.
  ///
  /// Also unwrap [FancySwitcherTag]'s child.
  factory _ChildEntry.fromWidget(Widget widget) => _ChildEntry._(
        widget is FancySwitcherTag ? widget.child : widget,
        FancySwitcherTag.getKey(widget),
        FancySwitcherTag.getIndex(widget),
      );

  _ChildEntry._(this.widget, this.key, this.index);

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
  })  : _type = FancySwitcherType.fade,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
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
  })  : _type = FancySwitcherType.axisVertical,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
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
  })  : _type = FancySwitcherType.axisHorizontal,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
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
  })  : _type = FancySwitcherType.scaled,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
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
  final FancySwitcherType _type;

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
  dynamic _reverseKey;
  Widget get _placeholder => widget.placeholder != null
      ? FancySwitcherTag(tag: -1, child: widget.placeholder)
      : const FancySwitcherTag(tag: -1, child: SizedBox.shrink());

  static bool _compareChildren(Widget a, Widget b) => (a?.key ?? a) == (b?.key ?? b);

  // When the entries are swapped, their index is compared to determine if
  // the next switch should animate in reverse.
  void _swapChildEntries(Widget child) {
    final entry = child != null ? _ChildEntry.fromWidget(child) : null;

    if ((entry?.index ?? 0) == (_child?.index ?? 0)) {
      // Indexes default to 0. If swapping entries with the same indexes, check if the new
      // key matches the previous childs key, to determine whether to reverse the animation.
      _reverse = entry?.key == _reverseKey;
      if (!_reverse) _reverseKey = _child?.key;
    } else {
      _reverse = (entry?.index ?? 0) < (_child?.index ?? 0) ? true : false;
      _reverseKey = null;
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
      case FancySwitcherType.fade:
        return FadeThroughTransition(
          child: child,
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case FancySwitcherType.axisVertical:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case FancySwitcherType.axisHorizontal:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
          onEnd: widget.onEnd,
          onStatusChanged: widget.onStatusChanged,
          fillColor: widget.fillColor,
        );
      case FancySwitcherType.scaled:
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
    @required this.child,
    this.tag,
    this.index,
  }) : super(key: key);

  /// The tag that's gonna be compared against another switcher child.
  final dynamic tag;

  /// Child [Widget] of this [FancySwitcherTag].
  final Widget child;

  /// Optional index of this [FancySwitcherTag] to allow [FancySwitcher] to know when
  /// to run the animation in reverse.
  ///
  /// If this is null and the [tag] is an int, the tag is used as the index instead.
  ///
  /// You should only use [index] if you don't want the [FancySwitcher] to switch based on the index.
  final int index;

  /// Attempts to extract [FancySwitcherTag] tag as a [ValueKey] from the [child].
  /// If the child is not a [FancySwitcherTag], default to it's own key or runtime key.
  static Key getKey(Widget child) => child != null
      ? (child is FancySwitcherTag && child.tag != null)
          ? ValueKey<dynamic>(child.tag)
          : (child.key ?? ValueKey(child.runtimeType))
      : null;

  /// Attempt to get the dynamic tag out of [FancySwitcherTag].
  static int getIndex(Widget child) => child != null && child is FancySwitcherTag
      ? child.index ?? (child.tag != null && child.tag is int ? child.tag as int : 0)
      : 0;

  @override
  Widget build(BuildContext context) => child;
}

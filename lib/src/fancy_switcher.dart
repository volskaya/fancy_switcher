import 'dart:async';

import 'package:animations/animations.dart';
import 'package:await_route/await_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Type of the material animation used in the fancy switcher widgets.
enum FancySwitcherType {
  /// Material fade.
  fade,

  /// Material axis swipe vertical.
  axisVertical,

  /// Material axis swipe horizontal.
  axisHorizontal,

  /// Material axis scale center.
  scaled,
}

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
  final Key? key;
  final int index;
}

/// Fancy switcher that wraps transitions of the `animations` package
class FancySwitcher extends StatefulWidget {
  /// Creates a [FancySwitcher] with the material fade transition.
  const FancySwitcher({
    Key? key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.shouldDelay,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = true,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
    this.sliver = false,
    this.reverse = true,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
    this.delayInitialChild = true,
    this.instantSize = false,
  })  : _type = FancySwitcherType.fade,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
        assert(!paintInheritedAnimations || inherit),
        super(key: key);

  /// Creates a [FancySwitcher] with the material vertical axis transition.
  const FancySwitcher.vertical({
    Key? key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.shouldDelay,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
    this.sliver = false,
    this.reverse = true,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
    this.delayInitialChild = true,
    this.instantSize = false,
  })  : _type = FancySwitcherType.axisVertical,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
        super(key: key);

  /// Creates a [FancySwitcher] with the material horizontal axis transition.
  const FancySwitcher.horizontal({
    Key? key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.shouldDelay,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
    this.sliver = false,
    this.reverse = true,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
    this.delayInitialChild = true,
    this.instantSize = false,
  })  : _type = FancySwitcherType.axisHorizontal,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
        assert(!paintInheritedAnimations || inherit),
        super(key: key);

  /// Creates a [FancySwitcher] with the material scale transition;
  const FancySwitcher.scaled({
    Key? key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 250),
    this.delay = Duration.zero,
    this.shouldDelay,
    this.onEnd,
    this.onStatusChanged,
    this.placeholder,
    this.addRepaintBoundary = false,
    this.wrapChildrenInRepaintBoundary = true,
    this.awaitRoute = false,
    this.fillColor = Colors.transparent,
    this.sliver = false,
    this.reverse = false,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
    this.delayInitialChild = true,
    this.instantSize = false,
  })  : _type = FancySwitcherType.scaled,
        assert(placeholder == null || placeholder is! FancySwitcherTag),
        assert(!paintInheritedAnimations || inherit),
        super(key: key);

  /// Animated child of [FancySwitcher].
  final Widget? child;

  /// Temporary child to build when using [delay], before the real [child] is built.
  final Widget? placeholder;

  /// Box alignment of children within the animated switcher.
  final AlignmentGeometry alignment;

  /// Callback when the transation ends.
  final VoidCallback? onEnd;

  /// Callback when the animation status changes. This is called before [onEnd].
  final ValueChanged<AnimationStatus>? onStatusChanged;

  /// The duration of the switch animation.
  final Duration duration;

  /// Delay of the switch.
  final Duration delay;

  /// Optional callback to control when the switch should be delayed.
  final bool Function()? shouldDelay;

  /// The type of the switcher.
  final FancySwitcherType _type;

  /// Wrap the transition in a [RepaintBoundary].
  final bool addRepaintBoundary;

  /// Wrap the child widgets in a [RepaintBoundary].
  final bool wrapChildrenInRepaintBoundary;

  /// Show a placeholder widget, until the route has animated in.
  final bool awaitRoute;

  /// Whether to apply [delay] to the initial child.
  final bool delayInitialChild;

  /// Fill color built into some transitions. Setting this makes the animation look more materialy, I guess…
  ///
  /// Should usually either be transparent or match the background of the switchers container.
  final Color fillColor;

  /// When `true`, the layout will size it to the last child's size, even if any
  /// other children are still animating out.
  ///
  /// This doesn't support [sliver] layout.
  final bool instantSize;

  /// Whether to use sliver layout builder.
  ///
  /// This must be toggled, if the switcher is built within a scroll view.
  final bool sliver;

  /// Whether to allow the switcher to animate in reverse.
  ///
  /// Reverse animation would happen if the same widget got switched back or a
  /// [FancySwitcherTag] was built with a lower index.
  ///
  /// Most material transitions are supposed to support reverse except the
  /// fade through animation.
  final bool reverse;

  /// Whether to defer the animations to [InheritedAnimationCoordinator].
  ///
  /// If this is toggled, you are responsible for building [InheritedAnimation]
  /// somewhere down the widget tree.
  final bool inherit;

  /// Whether to paint any deferred animations before the child.
  final bool paintInheritedAnimations;

  /// Whether to add an [InheritedAnimationCoordinator.boundary] to avoid inheriting parent animations.
  final bool wrapInheritBoundary;

  /// Layout builder for slivers.
  static Widget sliverLayoutBuilder(List<Widget> entries, [AlignmentGeometry alignment = Alignment.center]) =>
      SliverStack(children: entries, positionedAlignment: alignment);

  @override
  _FancySwitcherState createState() => _FancySwitcherState();
}

class _FancySwitcherState extends State<FancySwitcher> {
  _ChildEntry? _child;
  bool _reverse = false;
  dynamic _reverseKey;
  Widget get _placeholder => widget.placeholder != null
      ? FancySwitcherTag(tag: FancySwitcherTag.placeholderTag, child: widget.placeholder!)
      : const FancySwitcherTag(tag: FancySwitcherTag.placeholderTag, child: SizedBox.shrink());

  static bool _compareChildren(Widget? a, Widget? b) => FancySwitcherTag.canUpdate(a, b);

  // When the entries are swapped, their index is compared to determine if
  // the next switch should animate in reverse.
  void _swapChildEntries(Widget? child, {bool canUpdate = false}) {
    final entry = child != null ? _ChildEntry.fromWidget(child) : null;

    if (widget.reverse) {
      if (!canUpdate) {
        if ((entry?.index ?? 0) == (_child?.index ?? 0)) {
          // Indexes default to 0. If swapping entries with the same indexes, check if the new
          // key matches the previous childs key, to determine whether to reverse the animation.
          _reverse = entry?.key == _reverseKey;
          if (!_reverse) _reverseKey = _child?.key;
        } else {
          _reverse = (entry?.index ?? 0) < (_child?.index ?? 0) ? true : false;
        }
      }
    } else {
      _reverse = false;
      _reverseKey = null;
    }

    _child = entry;
    markNeedsBuild();
  }

  Future _scheduleChild(Widget child) async {
    assert(widget.awaitRoute || widget.delay > Duration.zero);

    if (widget.awaitRoute) await AwaitRoute.of(context);
    if (mounted && widget.delay > Duration.zero && (widget.shouldDelay?.call() ?? true)) {
      await Future<void>.delayed(widget.delay * timeDilation);
    }
    if (mounted && _compareChildren(widget.child, child)) {
      _swapChildEntries(widget.child);
    }
  }

  void _handleChildChange(Widget? old, Widget? current, {bool isInitial = false}) {
    if (!_compareChildren(old, current) || isInitial) {
      final shouldDelay = widget.delay > Duration.zero && (widget.shouldDelay?.call() ?? true);
      final willDelay = isInitial
          ? widget.delayInitialChild
              ? shouldDelay
              : false
          : shouldDelay;

      if (willDelay || widget.awaitRoute) {
        if (isInitial) {
          _swapChildEntries(_placeholder);
          if (current != null) _scheduleChild(current);
        } else {
          _scheduleChild(current ?? _placeholder);
        }
      } else {
        _swapChildEntries(current ?? _placeholder);
      }
    } else if (old != current) {
      _swapChildEntries(current ?? _placeholder, canUpdate: true);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_child == null) _handleChildChange(null, widget.child, isInitial: true);
  }

  @override
  void didUpdateWidget(covariant FancySwitcher oldWidget) {
    _handleChildChange(oldWidget.child, widget.child);
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
          sliver: widget.sliver,
          inherit: widget.inherit,
          paintInheritedAnimations: widget.paintInheritedAnimations,
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
          sliver: widget.sliver,
          inherit: widget.inherit,
          paintInheritedAnimations: widget.paintInheritedAnimations,
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
          sliver: widget.sliver,
          inherit: widget.inherit,
          paintInheritedAnimations: widget.paintInheritedAnimations,
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
          sliver: widget.sliver,
          inherit: widget.inherit,
          paintInheritedAnimations: widget.paintInheritedAnimations,
        );
    }
  }

  Widget _buildLayout(List<Widget> entries, [AlignmentGeometry alignment = Alignment.center]) => widget.sliver
      ? FancySwitcher.sliverLayoutBuilder(entries, alignment)
      : PageTransitionSwitcher.defaultLayoutBuilder(
          // entries,
          // (!_reverse ? entries.take(2) : entries.reversed.take(2)).toList(growable: false),
          entries.take(2).toList(growable: false),
          alignment,
          widget.instantSize
              ? _reverse
                  ? StackSizeTarget.firstChild
                  : StackSizeTarget.lastChild
              : StackSizeTarget.expand,
        );

  @override
  Widget build(BuildContext context) {
    assert(widget.reverse || !_reverse);

    Widget? child = _child != null
        ? !widget.sliver && widget.wrapChildrenInRepaintBoundary
            ? RepaintBoundary(key: _child!.key, child: _child!.widget)
            : KeyedSubtree(key: _child!.key, child: _child!.widget)
        : null;

    child = PageTransitionSwitcher(
      transitionBuilder: _transition,
      alignment: widget.alignment,
      child: child,
      duration: widget.duration,
      reverse: _reverse,
      layoutBuilder: _buildLayout,
    );

    if (!widget.sliver && widget.addRepaintBoundary) {
      child = RepaintBoundary(child: child);
    }

    if (widget.wrapInheritBoundary) {
      child = InheritedAnimationCoordinator.boundary(child: child);
    }

    return child;
  }
}

/// Tag widget that allows [FancySwitcher] to differentiate the same animating widget types.
///
/// Flutter recently changed the behavior of keys - when the key doesn't change, the widget won't rebuild
/// on prop changes as well. Note, this might be a bug. I can't reproduce this behavior on a vanilla flutter project.
class FancySwitcherTag extends StatelessWidget {
  /// Creates [FancySwitcherTag].
  const FancySwitcherTag({
    Key? key,
    required this.child,
    this.tag,
    this.index,
  }) : super(key: key);

  /// Tag of the placeholder widget used in [FancySwicher].
  static const placeholderTag = -1;

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
  final int? index;

  /// Attempts to extract [FancySwitcherTag] tag as a [ValueKey] from the [child].
  /// If the child is not a [FancySwitcherTag], default to it's own key or runtime key.
  static Key? getKey(Widget? child) => child != null
      ? (child is FancySwitcherTag && child.tag != null)
          ? ValueKey<dynamic>(child.tag)
          : (child.key ?? ValueKey(child.runtimeType))
      : null;

  /// Vairant of [Widget.canUpdate] that also factors in [FancySwitcherTag]'s props.
  static bool canUpdate(Widget? a, Widget? b) {
    final dynamic aTag = a is FancySwitcherTag ? a.tag : null;
    final dynamic bTag = b is FancySwitcherTag ? b.tag : null;

    final dynamic aChild = a is FancySwitcherTag ? a.child : a;
    final dynamic bChild = b is FancySwitcherTag ? b.child : b;

    return aTag == bTag && ((aChild?.key ?? aChild?.runtimeType) == (bChild?.key ?? bChild?.runtimeType));
  }

  /// Attempt to get the dynamic tag out of [FancySwitcherTag].
  static int getIndex(Widget? child) => child != null && child is FancySwitcherTag
      ? child.index ?? (child.tag != null && child.tag is int ? child.tag as int : 0)
      : 0;

  @override
  Widget build(BuildContext context) {
    assert(false, 'FancySwitcherTag is not supposed to be included in the widget tree');
    return child;
  }
}

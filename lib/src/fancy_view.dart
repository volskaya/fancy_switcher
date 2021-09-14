// ignore_for_file:invalid_use_of_protected_member

import 'package:animations/animations.dart';
import 'package:fancy_switcher/src/fancy_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum _Position { reverse, idle, forward }
enum _Direction { incoming, outgoing }

/// Item builder for [FancyView] children.
typedef FancyViewItemBuilder = Widget Function(BuildContext contex, int index);

const _kPagePhysics = PageScrollPhysics();

/// Page view with material transition animations, instead of linear swipe animation.
/// Similar to how pages transition in the google play app.
class FancyView extends StatelessWidget {
  /// Creates material fade variant of [FancyView].
  const FancyView.fade({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    this.fillColor = Colors.transparent,
    this.swipeDirection = Axis.horizontal,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
    this.onPageChanged,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.allowImplicitScrolling = false,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
  })  : _type = FancySwitcherType.fade,
        super(key: key);

  /// Creates material shared axis vertical variant of [FancyView].
  const FancyView.vertical({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
    this.onPageChanged,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.allowImplicitScrolling = false,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
  })  : _type = FancySwitcherType.axisVertical,
        swipeDirection = Axis.vertical,
        super(key: key);

  /// Creates material shared axis horizontal variant of [FancyView].
  const FancyView.horizontal({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
    this.onPageChanged,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.allowImplicitScrolling = false,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
  })  : _type = FancySwitcherType.axisHorizontal,
        swipeDirection = Axis.horizontal,
        super(key: key);

  /// Creates material shared axis scaled variant of [FancyView].
  const FancyView.scaled({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    this.fillColor = Colors.transparent,
    this.swipeDirection = Axis.horizontal,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
    this.onPageChanged,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.allowImplicitScrolling = false,
    this.inherit = false,
    this.paintInheritedAnimations = false,
    this.wrapInheritBoundary = false,
  })  : _type = FancySwitcherType.scaled,
        super(key: key);

  /// Child builder.
  final FancyViewItemBuilder itemBuilder;

  /// Child widget count.
  final int itemCount;

  /// Type of the material transition animation.
  final FancySwitcherType _type;

  /// Fill color built into some transitions. Setting this makes the animation look more materialy, I guess…
  ///
  /// Should usually either be transparent or match the background of the switchers container.
  final Color fillColor;

  /// Swipe direction of this [FancyView].
  final Axis swipeDirection;

  /// Page controller of the inner [PageView].
  final PageController? controller;

  /// Whether to wrap child widget in repaint boundaries.
  final bool addRepaintBoundaries;

  /// Clip behavior of the [PageView].
  final Clip clipBehavior;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  /// [ScrollPhysics] of the inner [PageView].
  final ScrollPhysics physics;

  /// Allow implicit scrolling on iOS. While this is enabled, the cache extent is set
  /// to 1 viewport, which means other the surrounding pages will get prebuilt.
  final bool allowImplicitScrolling;

  /// Whether to defer the animations to [InheritedAnimationCoordinator].
  ///
  /// If this is toggled, you are responsible for building [InheritedAnimation]
  /// somewhere down the widget tree.
  final bool inherit;

  /// Whether to paint any deferred animations before the child.
  final bool paintInheritedAnimations;

  /// Whether to add an [InheritedAnimationCoordinator.boundary] to avoid inheriting parent animations.
  final bool wrapInheritBoundary;

  Widget _transition(
    Widget child,
    Animation<double> primaryAnimation,
    Animation<double> secondaryAnimation,
  ) {
    switch (_type) {
      case FancySwitcherType.fade:
        return FadeThroughTransition(
          child: child,
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          fillColor: fillColor,
          inherit: inherit,
          paintInheritedAnimations: paintInheritedAnimations,
        );
      case FancySwitcherType.axisVertical:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          fillColor: fillColor,
          inherit: inherit,
          paintInheritedAnimations: paintInheritedAnimations,
        );
      case FancySwitcherType.axisHorizontal:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
          fillColor: fillColor,
          inherit: inherit,
          paintInheritedAnimations: paintInheritedAnimations,
        );
      case FancySwitcherType.scaled:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
          fillColor: fillColor,
          inherit: inherit,
          paintInheritedAnimations: paintInheritedAnimations,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget view = _FancyPageView(
      controller: controller,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      swipeDirection: swipeDirection,
      transitionBuilder: _transition,
      addRepaintBoundaries: addRepaintBoundaries,
      fillColor: fillColor,
      clipBehavior: clipBehavior,
      onPageChanged: onPageChanged,
      physics: physics,
      allowImplicitScrolling: allowImplicitScrolling,
    );

    if (wrapInheritBoundary) {
      view = InheritedAnimationCoordinator.boundary(child: view);
    }

    return view;
  }
}

class _FancyPageView extends StatefulWidget {
  const _FancyPageView({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    required this.transitionBuilder,
    this.swipeDirection = Axis.horizontal,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
    this.onPageChanged,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.allowImplicitScrolling = true,
    this.scrollBehavior,
    this.reverse = false,
    this.pageSnapping = true,
  }) : super(key: key);

  final FancyViewItemBuilder itemBuilder;
  final int itemCount;
  final Axis swipeDirection;
  final PageTransitionSwitcherTransitionBuilder transitionBuilder;
  final Color fillColor;
  final PageController? controller;
  final bool addRepaintBoundaries;
  final Clip clipBehavior;
  final ValueChanged<int>? onPageChanged;
  final ScrollPhysics physics;
  final bool allowImplicitScrolling;
  final ScrollBehavior? scrollBehavior;
  final bool reverse;
  final bool pageSnapping;

  @override
  __FancyPageViewState createState() => __FancyPageViewState();
}

class __FancyPageViewState extends State<_FancyPageView> {
  final _goingReverse = ValueNotifier<bool?>(null);

  late PageController _controller;
  bool _disposeController = false;
  int _lastReportedPage = 0;
  double _lastValue = 0.0;

  void _handleChange({double? value}) {
    final _value = value ?? (_controller.positions.isNotEmpty ? _controller.page : _controller.initialPage.toDouble());

    if (_lastValue != _value) {
      final isStopped = _value?.toInt() == _value;
      if (isStopped) {
        _goingReverse.value = null;
      } else {
        _goingReverse.value ??= (_value ?? 0.0) < _lastValue;
      }
      _lastValue = _value ?? 0.0;
      // markNeedsBuild();
    }

    // Report page change.
    final currentPage = _value?.round() ?? _controller.initialPage;
    if (currentPage != _lastReportedPage) {
      _lastReportedPage = currentPage;
      widget.onPageChanged?.call(currentPage);
    }
  }

  @override
  void initState() {
    _disposeController = widget.controller == null;
    _controller = widget.controller ?? PageController();
    _controller.addListener(_handleChange);
    _lastValue = _controller.initialPage.toDouble();
    _handleChange(value: _controller.initialPage.toDouble());
    super.initState();
  }

  @override
  void dispose() {
    if (_disposeController) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleChange);
    }

    super.dispose();
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.swipeDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  Widget _buildItem(BuildContext context, int i) => _FancyViewTransformedChildBuilder(
        index: i,
        controller: _controller,
        reverse: _goingReverse,
        axis: widget.swipeDirection,
        builder: widget.transitionBuilder,
        child: widget.itemBuilder(context, i),
      );

  @override
  Widget build(BuildContext context) {
    final axisDirection = _getDirection(context);
    final scrollPhysics = widget.scrollBehavior?.getScrollPhysics(context) ?? const AlwaysScrollableScrollPhysics();
    final physics = ForceImplicitScrollPhysics(
      allowImplicitScrolling: widget.allowImplicitScrolling,
    ).applyTo(widget.pageSnapping ? _kPagePhysics.applyTo(scrollPhysics) : scrollPhysics);
    final childrenDelegate = SliverChildBuilderDelegate(
      _buildItem,
      childCount: widget.itemCount,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: widget.addRepaintBoundaries,
    );

    return Scrollable(
      axisDirection: axisDirection,
      controller: _controller,
      physics: physics,
      scrollBehavior: widget.scrollBehavior ?? ScrollConfiguration.of(context).copyWith(scrollbars: false),
      viewportBuilder: (context, position) => Viewport(
        cacheExtent: widget.allowImplicitScrolling ? 1.0 : 0.0,
        cacheExtentStyle: CacheExtentStyle.viewport,
        axisDirection: axisDirection,
        offset: position,
        clipBehavior: widget.clipBehavior,
        slivers: <Widget>[
          SliverFillViewport(
            viewportFraction: _controller.viewportFraction,
            delegate: childrenDelegate,
            moveChildren: false,
            padEnds: true,
          ),
        ],
      ),
    );
  }
}

/// Widget that builds the children for [FancyView].
///
/// It handles syncing of primary & secondary material transition animations
/// to the [PageController] in the [FancyView].
class _FancyViewTransformedChildBuilder extends StatefulWidget {
  /// Creates [_FancyViewTransformedChildBuilder].
  const _FancyViewTransformedChildBuilder({
    Key? key,
    required this.controller,
    required this.builder,
    required this.index,
    required this.child,
    required this.reverse,
    this.axis = Axis.horizontal,
    this.debug = false,
  }) : super(key: key);

  /// [PageController] that's gonna drive the primary and secondary animation
  /// of the children switcher animations.
  final PageController controller;

  /// Child widget that's wrapped in a material transition.
  final Widget child;

  /// Index of this child, for syncing the animation value, relative to the page
  /// in the [PageController].
  final int index;

  /// Whether the [FancyView] is being reversed in reverse.
  final ValueNotifier<bool?> reverse;

  /// The scroll direction.
  final Axis axis;

  /// Builder of the material transition.
  final PageTransitionSwitcherTransitionBuilder builder;

  /// Whether to overlay animation debug info over the children.
  final bool debug;

  @override
  _FancyViewTransformedChildBuilderState createState() => _FancyViewTransformedChildBuilderState();
}

class _FancyViewTransformedChildBuilderState extends State<_FancyViewTransformedChildBuilder>
    with TickerProviderStateMixin<_FancyViewTransformedChildBuilder> {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;

  double _relativeValue = 0.0;

  _Position get _position {
    if (widget.reverse.value == true) {
      return _Position.reverse;
    } else if (widget.reverse.value == false) {
      return _Position.forward;
    }

    if (_relativeValue < 0.0) {
      return _Position.reverse;
    } else if (_relativeValue > 0.0) {
      return _Position.forward;
    } else {
      return _Position.idle;
    }
  }

  _Direction get _direction {
    if (_relativeValue < 0.0) {
      return widget.reverse.value == true ? _Direction.outgoing : _Direction.incoming;
    } else {
      return widget.reverse.value != true ? _Direction.outgoing : _Direction.incoming;
    }
  }

  void _handleValueChange() {
    switch (_position) {
      case _Position.idle:
        _primaryController.value = 1.0;
        _secondaryController.value = 0.0;
        break;
      case _Position.forward:
        switch (_direction) {
          case _Direction.incoming:
            _primaryController.value = 1.0 - _relativeValue.abs();
            _secondaryController.value = 0.0;
            break;
          case _Direction.outgoing:
            _primaryController.value = 1.0;
            _secondaryController.value = _relativeValue.abs();
            break;
        }
        break;
      case _Position.reverse:
        switch (_direction) {
          case _Direction.incoming:
            _secondaryController.value = _relativeValue.abs();
            _primaryController.value = 1.0;
            break;
          case _Direction.outgoing:
            _primaryController.value = 1.0 - _relativeValue.abs();
            _secondaryController.value = 0.0;
            break;
        }
        break;
    }
  }

  void _handlePageController({double? value}) {
    final relativeValue = (value ??
                (widget.controller.positions.isNotEmpty
                    ? widget.controller.page ?? widget.controller.initialPage.toDouble()
                    : widget.controller.initialPage.toDouble()))
            .clamp(widget.index - 1, widget.index + 1)
            .toDouble() -
        widget.index;

    if (_relativeValue != relativeValue) {
      _relativeValue = relativeValue;
      _handleValueChange();
    }
  }

  @override
  void initState() {
    _primaryController = AnimationController(vsync: this);
    _secondaryController = AnimationController(vsync: this);
    widget.reverse.addListener(_handlePageController);
    widget.controller.addListener(_handlePageController);
    _handlePageController(value: widget.controller.initialPage.toDouble());
    _handleValueChange();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _FancyViewTransformedChildBuilder oldWidget) {
    assert(oldWidget.controller == widget.controller);
    if (oldWidget.reverse != widget.reverse) _handlePageController();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.reverse.removeListener(_handlePageController);
    widget.controller.removeListener(_handlePageController);
    _primaryController.dispose();
    _secondaryController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.child, _primaryController, _secondaryController);
}

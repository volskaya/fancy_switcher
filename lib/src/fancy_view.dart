// ignore_for_file:invalid_use_of_protected_member

import 'package:animations/animations.dart';
import 'package:fancy_switcher/src/fancy_switcher.dart';
import 'package:flutter/material.dart';

enum _Position { reverse, idle, forward }
enum _Direction { incoming, outgoing }

/// Item builder for [FancyView] children.
typedef FancyViewItemBuilder = Widget Function(BuildContext contex, int index);

/// Page view with material transition animations, instead of linear swipe animation.
/// Similar to how pages transition in the google play app.
class FancyView extends StatelessWidget {
  /// Creates material fade variant of [FancyView].
  const FancyView.fade({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.fillColor = Colors.transparent,
    this.swipeDirection = Axis.horizontal,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
  })  : _type = FancySwitcherType.fade,
        super(key: key);

  /// Creates material shared axis vertical variant of [FancyView].
  const FancyView.vertical({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
  })  : _type = FancySwitcherType.axisVertical,
        swipeDirection = Axis.vertical,
        super(key: key);

  /// Creates material shared axis horizontal variant of [FancyView].
  const FancyView.horizontal({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
  })  : _type = FancySwitcherType.axisHorizontal,
        swipeDirection = Axis.horizontal,
        super(key: key);

  /// Creates material shared axis scaled variant of [FancyView].
  const FancyView.scaled({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.fillColor = Colors.transparent,
    this.swipeDirection = Axis.horizontal,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
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
  final PageController controller;

  /// Whether to wrap child widget in repaint boundaries.
  final bool addRepaintBoundaries;

  /// Clip behavior of the [PageView].
  final Clip clipBehavior;

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
        );
      case FancySwitcherType.axisVertical:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          fillColor: fillColor,
        );
      case FancySwitcherType.axisHorizontal:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
          fillColor: fillColor,
        );
      case FancySwitcherType.scaled:
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
          fillColor: fillColor,
        );
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: _FancyPageView(
          controller: controller,
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          swipeDirection: swipeDirection,
          transitionBuilder: _transition,
          addRepaintBoundaries: addRepaintBoundaries,
          fillColor: fillColor,
          clipBehavior: clipBehavior,
        ),
      );
}

class _FancyPageView extends StatefulWidget {
  const _FancyPageView({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    @required this.transitionBuilder,
    this.swipeDirection = Axis.horizontal,
    this.fillColor = Colors.transparent,
    this.controller,
    this.addRepaintBoundaries = true,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  final FancyViewItemBuilder itemBuilder;
  final int itemCount;
  final Axis swipeDirection;
  final PageTransitionSwitcherTransitionBuilder transitionBuilder;
  final Color fillColor;
  final PageController controller;
  final bool addRepaintBoundaries;
  final Clip clipBehavior;

  @override
  __FancyPageViewState createState() => __FancyPageViewState();
}

class __FancyPageViewState extends State<_FancyPageView> {
  final _goingReverse = ValueNotifier<bool>(null);

  bool _disposeController = false;
  PageController _controller;
  double _lastValue = 0.0;

  void _handleChange({double value}) {
    final _value = value ?? (_controller.positions.isNotEmpty ? _controller.page : _controller.initialPage.toDouble());
    if (_lastValue == _value) return; // Redundant.
    final isStopped = _value.floor() == _value;
    if (isStopped) {
      _goingReverse.value = null;
    } else {
      _goingReverse.value ??= _value < _lastValue;
    }
    _lastValue = _value;
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
      _controller?.dispose();
    } else {
      _controller?.removeListener(_handleChange);
    }

    super.dispose();
  }

  Widget _buildItem(BuildContext context, int i) => _ChildAnimationBuilder(
        index: i,
        controller: _controller,
        reverse: _goingReverse,
        axis: widget.swipeDirection,
        builder: widget.transitionBuilder,
        child: widget.addRepaintBoundaries
            ? RepaintBoundary(child: widget.itemBuilder(context, i))
            : widget.itemBuilder(context, i),
      );

  @override
  Widget build(BuildContext context) => PageView.custom(
        controller: _controller,
        scrollDirection: widget.swipeDirection,
        clipBehavior: widget.clipBehavior,
        childrenDelegate: SliverChildBuilderDelegate(
          _buildItem,
          childCount: widget.itemCount,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
        ),
      );
}

class _ChildAnimationBuilder extends StatefulWidget {
  const _ChildAnimationBuilder({
    Key key,
    @required this.controller,
    @required this.builder,
    @required this.index,
    this.child,
    this.reverse,
    this.axis = Axis.horizontal,
  }) : super(key: key);

  final PageController controller;
  final Widget child;
  final int index;
  final ValueNotifier<bool> reverse;
  final Axis axis;
  final PageTransitionSwitcherTransitionBuilder builder;

  @override
  __ChildAnimationBuilderState createState() => __ChildAnimationBuilderState();
}

class __ChildAnimationBuilderState extends State<_ChildAnimationBuilder>
    with TickerProviderStateMixin<_ChildAnimationBuilder> {
  final _relativeValue = ValueNotifier<double>(0);

  AnimationController _primaryController;
  AnimationController _secondaryController;

  _Position get _position {
    if (widget.reverse.value == true) {
      return _Position.reverse;
    } else if (widget.reverse.value == false) {
      return _Position.forward;
    }

    if (_relativeValue.value < 0) {
      return _Position.reverse;
    } else if (_relativeValue.value > 0) {
      return _Position.forward;
    } else {
      return _Position.idle;
    }
  }

  _Direction get _direction {
    if (_relativeValue.value < 0) {
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
            _primaryController.value = 1.0 - _relativeValue.value.abs();
            _secondaryController.value = 0.0;
            break;
          case _Direction.outgoing:
            _primaryController.value = 1.0;
            _secondaryController.value = _relativeValue.value.abs();
            break;
        }
        break;
      case _Position.reverse:
        switch (_direction) {
          case _Direction.incoming:
            _secondaryController.value = _relativeValue.value.abs();
            _primaryController.value = 1.0;
            break;
          case _Direction.outgoing:
            _primaryController.value = 1.0 - _relativeValue.value.abs();
            _secondaryController.value = 0.0;
            break;
        }
        break;
    }
  }

  void _handlePageController({double value}) => _relativeValue.value = (value ??
              (widget.controller.positions.isNotEmpty
                  ? widget.controller.page
                  : widget.controller.initialPage.toDouble()))
          .clamp(widget.index - 1, widget.index + 1)
          .toDouble() -
      widget.index;

  @override
  void initState() {
    _primaryController = AnimationController(vsync: this);
    _secondaryController = AnimationController(vsync: this);
    _relativeValue.addListener(_handleValueChange);
    widget.reverse.addListener(_handlePageController);
    widget.controller.addListener(_handlePageController);
    _handlePageController(value: widget.controller.initialPage.toDouble());
    _handleValueChange();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ChildAnimationBuilder oldWidget) {
    assert(oldWidget.controller == widget.controller);
    if (oldWidget.reverse != widget.reverse) _handlePageController();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.reverse.removeListener(_handlePageController);
    widget.controller.removeListener(_handlePageController);
    _relativeValue.dispose();
    _primaryController?.dispose();
    _secondaryController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: _relativeValue,
        child: widget.builder(widget.child, _primaryController, _secondaryController),
        builder: (_, relativeValue, child) {
          Offset offset = Offset.zero;

          switch (widget.axis) {
            case Axis.horizontal:
              offset = Offset(relativeValue, 0);
              break;
            case Axis.vertical:
              offset = Offset(0, relativeValue);
              break;
          }

          return FractionalTranslation(translation: offset, child: child);
        },
      );
}

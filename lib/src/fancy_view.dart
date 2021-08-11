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
          onPageChanged: onPageChanged,
          physics: physics,
        ),
      );
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

  @override
  __FancyPageViewState createState() => __FancyPageViewState();
}

class __FancyPageViewState extends State<_FancyPageView> {
  final _goingReverse = ValueNotifier<bool?>(null);

  late PageController _controller;
  bool _disposeController = false;
  double _lastValue = 0.0;

  void _handleChange({double? value}) {
    final _value = value ?? (_controller.positions.isNotEmpty ? _controller.page : _controller.initialPage.toDouble());
    if (_lastValue == _value) return; // Redundant.
    final isStopped = _value?.toInt() == _value;
    if (isStopped) {
      _goingReverse.value = null;
    } else {
      _goingReverse.value ??= (_value ?? 0.0) < _lastValue;
    }
    _lastValue = _value ?? 0.0;
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

  Widget _buildItem(BuildContext context, int i) => _FancyViewTransformedChildBuilder(
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
        onPageChanged: widget.onPageChanged,
        physics: widget.physics,
        pageSnapping: true,
        childrenDelegate: SliverChildBuilderDelegate(
          _buildItem,
          childCount: widget.itemCount,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
        ),
      );
}

/// Widget that builds the children for [FancyView].
///
/// It handles syncing of primary & secondary material transition animations
/// to the [PageController] in the [FancyView].
///
/// This also applies a [FractionalTranslation] to the built children,
/// to keep them in places, as the [PageView] scrolls, since the material
/// animations are the ones, that "switch" between the 2 children. [PageView]
/// is only used for its gesture logic.
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
  final _relativeValue = ValueNotifier<double>(0);

  late AnimationController _primaryController;
  late AnimationController _secondaryController;

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

  void _handlePageController({double? value}) => _relativeValue.value = (value ??
              (widget.controller.positions.isNotEmpty
                  ? widget.controller.page ?? widget.controller.initialPage.toDouble()
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
  void didUpdateWidget(covariant _FancyViewTransformedChildBuilder oldWidget) {
    assert(oldWidget.controller == widget.controller);
    if (oldWidget.reverse != widget.reverse) _handlePageController();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.reverse.removeListener(_handlePageController);
    widget.controller.removeListener(_handlePageController);
    _relativeValue.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();

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

          if (widget.debug) {
            final debugChild = SizedBox.expand(
              child: Center(
                child: Text(
                  'Relative value: ${relativeValue.toStringAsFixed(2)}'
                  '\nDirection: $_direction'
                  '\nPosition: $_position'
                  '\nWidget reverse: ${widget.reverse.value}'
                  '\nPrimary: ${_primaryController.value.toStringAsFixed(2)}'
                  '\nSecondary: ${_secondaryController.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
            );

            return FractionalTranslation(
              translation: offset,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  Column(
                    children: [
                      Flexible(child: widget.index.isEven ? debugChild : const SizedBox.expand()),
                      Flexible(child: widget.index.isOdd ? debugChild : const SizedBox.expand()),
                    ],
                  )
                ],
              ),
            );
          }

          return FractionalTranslation(translation: offset, child: child);
        },
      );
}

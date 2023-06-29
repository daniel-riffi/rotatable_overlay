import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rotatable_overlay/src/angle.dart';
import 'package:rotatable_overlay/src/angle_range.dart';

/// A flutter widget that makes its child rotatable by dragging around its center.
class RotatableOverlay extends StatefulWidget {
  /// A list of angles to which the rotation snaps.
  final List<Angle>? snaps;

  /// Determines how close the rotation has to be to a snap angle in order to snap.
  final Angle? snapDelta;

  /// Whether the rotation will animate to the nearest snap angle when stopped dragging.
  final bool shouldSnapOnEnd;

  /// Sets the initial rotation of the child.
  final Angle? initialRotation;

  /// Child widget that will be rotatable.
  final Widget child;

  /// Determines how long the animation will take if [shouldSnapOnEnd] is true.
  final Duration snapBackDuration;

  /// Callback that is called when the rotation snaps.
  final void Function(Angle)? onSnap;

  /// Callback that is called when the angle of the rotation changes.
  final void Function(Angle)? onAngleChanged;

  /// Callback that is called when animation to the nearest snap angle is finished.
  final VoidCallback? onSnapAnimationEnd;

  RotatableOverlay({
    super.key,
    this.snaps,
    this.snapDelta,
    this.shouldSnapOnEnd = false,
    this.snapBackDuration = const Duration(seconds: 2),
    this.initialRotation,
    this.onSnap,
    this.onAngleChanged,
    this.onSnapAnimationEnd,
    required this.child,
  }) : assert(shouldSnapOnEnd && (snaps?.isNotEmpty ?? false) || !shouldSnapOnEnd);

  @override
  State<RotatableOverlay> createState() => _RotatableOverlayState();
}

class _RotatableOverlayState extends State<RotatableOverlay> with SingleTickerProviderStateMixin {
  Angle _mouseAngle = Angle.zero;

  late Angle _childAngle;
  late Angle? _childAngleSnapped;

  late Angle _snapDelta;

  late Angle _lastChangeAngle;

  late List<Angle> _snaps;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.snapBackDuration, upperBound: 4 * math.pi);

  Offset _centerOfChild = Offset.zero;

  @override
  void initState() {
    _childAngle = widget.initialRotation ?? Angle.zero;
    _childAngleSnapped = widget.initialRotation;
    _lastChangeAngle = _childAngle;

    _snapDelta = widget.snapDelta ?? Angle.zero;

    _snaps = widget.snaps ?? [];
    _snaps.sort((a, b) => a.compareTo(b));

    _controller.addStatusListener((status) {
      if (status.index == 3) {
        //completed
        widget.onSnap?.call(_childAngle);
        widget.onSnapAnimationEnd?.call();
      }
    });

    _controller.addListener(() {
      _childAngle = Angle.radians(_controller.value);
      _childAngleSnapped = _childAngle;

      if ((_childAngle.degrees - _lastChangeAngle.degrees).abs() >= 1) {
        _lastChangeAngle = _childAngle;
        widget.onAngleChanged?.call(_childAngle);
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RotatableOverlay oldWidget) {
    if (oldWidget.initialRotation != widget.initialRotation) {
      _childAngle = widget.initialRotation ?? Angle.zero;
      _childAngleSnapped = widget.initialRotation;
      _lastChangeAngle = _childAngle;
    }
    if (oldWidget.snapDelta != widget.snapDelta) {
      _snapDelta = widget.snapDelta ?? Angle.zero;
    }
    if (!listEquals(oldWidget.snaps, widget.snaps)) {
      _snaps = widget.snaps ?? [];
      _snaps.sort((a, b) => a.compareTo(b));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _centerOfChild = (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero) +
          Offset((context.size!.width / 2), (context.size!.height / 2));
    });

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          var angle = _controller.isAnimating ? Angle.radians(_controller.value) : _childAngleSnapped ?? _childAngle;
          return Transform.rotate(angle: angle.supplement.standardRadians, child: child);
        },
        child: widget.child,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;
    var newMouseAngle = Angle.radians(-math.atan2(dy, dx));
    setState(() {
      _mouseAngle = newMouseAngle;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;
    var newMouseAngle = Angle.radians(-math.atan2(dy, dx));

    var movedAngle = _mouseAngle - newMouseAngle;

    var newChildAngle = _childAngle - movedAngle;

    var newChildAngleSnapped =
        _snaps.where((snap) => AngleRange.fromDelta(snap, _snapDelta).isInRange(newChildAngle)).firstOrNull;

    if (newChildAngleSnapped != null && newChildAngleSnapped != _childAngleSnapped) {
      widget.onSnap?.call(newChildAngleSnapped);
    }

    _controller.value = newChildAngle.radians;

    if ((newChildAngle.degrees - _lastChangeAngle.degrees).abs() >= 1) {
      _lastChangeAngle = newChildAngle;
      widget.onAngleChanged?.call(newChildAngle);
    }

    setState(() {
      _mouseAngle = newMouseAngle;
      _childAngle = newChildAngle;
      _childAngleSnapped = newChildAngleSnapped;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.shouldSnapOnEnd && !_snaps.contains(_childAngleSnapped)) {
      Angle nearestSnap = _snaps.fold(_snaps[0], (previousValue, element) {
        if (_childAngle.difference(element) < _childAngle.difference(previousValue)) {
          return element;
        }
        return previousValue;
      });

      double snap = nearestSnap.radians;

      if ((_childAngle.radians - nearestSnap.radians).abs() > math.pi) {
        // better to go over zero
        if (_childAngle > nearestSnap) {
          snap += 2 * math.pi;
        } else {
          _controller.value += 2 * math.pi;
        }
      }

      _controller.animateTo(snap);
    }
  }
}

import 'dart:math' as math;
import 'package:angle_utils/angle_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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

  /// Determines how long the animation will take if [shouldSnapOnEnd] is true and [shouldUseRelativeSnapDuration] is false.
  /// If [shouldUseRelativeSnapDuration] is true, [snapDuration] determines how long the animation takes for 360 degrees.
  final Duration snapDuration;

  /// Whether the duration of the snap animation is constant or it should be calculated based on the relative angle it has to rotate.
  final bool shouldUseRelativeSnapDuration;

  /// Determines the animation curve to the nearest snap angle.
  final Curve snapCurve;

  /// Callback that is called when the rotation snaps.
  final void Function(Angle)? onSnap;

  /// Callback that is called when the angle of the rotation changes.
  final void Function(Angle)? onAngleChanged;

  /// Callback that is called when the pan gesture ends.
  final void Function(Angle, Angle?)? onAngleChangedPanEnd;

  /// Callback that is called when animation to the nearest snap angle is finished.
  final VoidCallback? onSnapAnimationEnd;

  /// Whether to add inertia to the movement when stopped dragging.
  final bool applyInertia;

  /// The friction coefficient to apply to inertia.
  final double frictionCoefficient;

  /// Whether to limit drag to widget bounds (increase robustness of rotation sign determination).
  final bool limitDragToBounds;
  RotatableOverlay({
    super.key,
    this.snaps,
    this.snapDelta,
    this.shouldSnapOnEnd = false,
    this.snapDuration = const Duration(seconds: 1),
    this.shouldUseRelativeSnapDuration = false,
    this.snapCurve = Curves.linear,
    this.initialRotation,
    this.onSnap,
    this.onAngleChanged,
    this.onAngleChangedPanEnd,
    this.onSnapAnimationEnd,
    this.applyInertia = false,
    this.frictionCoefficient = 0.1,
    this.limitDragToBounds = false,
    required this.child,
  }) : assert(
            shouldSnapOnEnd && (snaps?.isNotEmpty ?? false) || !shouldSnapOnEnd,
            'Snaps must not be empty if shouldSnapOnEnd is true');

  @override
  State<RotatableOverlay> createState() => _RotatableOverlayState();
}

class _RotatableOverlayState extends State<RotatableOverlay>
    with SingleTickerProviderStateMixin {
  Angle _mouseAngle = Angle.zero();

  late Angle _childAngle;
  late Angle? _childAngleSnapped;

  late Angle _snapDelta;

  late Angle _lastChangeAngle;

  late List<Angle> _snaps;
  late List<AngleRange> _snapRanges;

  late bool? isRotationClockwise;

  late final AnimationController _controller;

  Offset _centerOfChild = Offset.zero;

  bool startingAnimation = true;

  @override
  void initState() {
    _controller = AnimationController.unbounded(
      vsync: this,
    );
    _childAngle = widget.initialRotation ?? Angle.zero();
    _childAngleSnapped = widget.initialRotation;
    _lastChangeAngle = _childAngle;

    _snapDelta = widget.snapDelta ?? Angle.zero();

    _snaps = widget.snaps ?? [];
    _snaps.sort((a, b) => a.compareTo(b));

    // Creates ranges from s-Delta to s+Delta
    _snapRanges =
        _snaps.map((s) => AngleRange.fromDelta(s, _snapDelta)).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOfChild =
          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero) +
              Offset((context.size!.width / 2), (context.size!.height / 2));
    });

    _controller.addStatusListener((status) {
      if (status.index == 3) {
        //completed
        widget.onSnap?.call(_childAngle);
        widget.onSnapAnimationEnd?.call();
      }
    });

    _controller.addListener(() {
      _childAngle = Angle.radians(_controller.value).normalized;
      _childAngleSnapped = _childAngle;

      if ((_childAngle.degrees - _lastChangeAngle.degrees).abs() >= 1) {
        _lastChangeAngle = _childAngle;
        widget.onAngleChanged?.call(_childAngle);
      }
    });

    isRotationClockwise = null;

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RotatableOverlay oldWidget) {
    if (oldWidget.initialRotation != widget.initialRotation) {
      _childAngle = widget.initialRotation ?? Angle.zero();
      _childAngleSnapped = widget.initialRotation;
      _lastChangeAngle = _childAngle;
    }
    if (oldWidget.snapDelta != widget.snapDelta) {
      _snapDelta = widget.snapDelta ?? Angle.zero();
      _snapRanges =
          _snaps.map((s) => AngleRange.fromDelta(s, _snapDelta)).toList();
    }
    if (!listEquals(oldWidget.snaps, widget.snaps)) {
      _snaps = widget.snaps ?? [];
      _snaps.sort((a, b) => a.compareTo(b));
      _snapRanges =
          _snaps.map((s) => AngleRange.fromDelta(s, _snapDelta)).toList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOfChild =
          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero) +
              Offset((context.size!.width / 2), (context.size!.height / 2));
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          var angle = _controller.isAnimating
              ? Angle.radians(_controller.value)
              : _childAngleSnapped ?? _childAngle;
          return Transform.rotate(
            angle: (Angle.full() - angle).radians,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Stop any ongoing animations to prevent conflicts
    _controller.stop();
    startingAnimation = true;

    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;
    var newMouseAngle = Angle.atan2(dy, dx);
    setState(() {
      _mouseAngle = newMouseAngle;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.limitDragToBounds) {
      // Ignore updates if the pointer is outside the widget's bounds
      final size = context.size;
      if (size == null) return;
      final bounds = Offset.zero & size;
      if (!bounds.contains(details.localPosition)) {
        return;
      }
    }

    if (startingAnimation) {
      // Calculate the current and previous pointer positions relative to the center
      var currentVector = details.globalPosition - _centerOfChild;
      var previousVector = Offset.fromDirection(_mouseAngle.radians);
      var crossProduct = (previousVector.dx * currentVector.dy) -
          (previousVector.dy * currentVector.dx);
      // Determine the sign of rotation based on the cross product
      isRotationClockwise =
          crossProduct > 0 ? true : (crossProduct < 0 ? false : null);

      startingAnimation = false;
    }

    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;

    var newMouseAngle = Angle.atan2(dy, dx);
    var movedAngle = _mouseAngle - newMouseAngle;
    var newChildAngle = (_childAngle + movedAngle).normalized;

    // Middle of first snap range encompassing the angle (or null if no
    // snap range covers it)
    var newChildAngleSnapped = _snapRanges
        .where((s) => s.includesNormalized(newChildAngle))
        .firstOrNull
        ?.mid;

    if (newChildAngleSnapped != null &&
        newChildAngleSnapped != _childAngleSnapped) {
      // Angle is covered by a snap range and the snap angle
      // differs from previous one
      widget.onSnap?.call(newChildAngleSnapped);
    }

    _controller.value = newChildAngle.radians;

    setState(() {
      _mouseAngle = newMouseAngle;
      _childAngle = newChildAngle;
      _childAngleSnapped = newChildAngleSnapped;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.applyInertia) {
      final rotationDirection =
          isRotationClockwise ?? true; // Default to true if null
      final velocity = rotationDirection
          ? -details.velocity.pixelsPerSecond.distance / 100
          : details.velocity.pixelsPerSecond.distance / 100;
      _startInertiaAnimation(velocity);
    }

    Angle? snap;
    if (widget.shouldSnapOnEnd && !_snaps.contains(_childAngleSnapped)) {
      // Pan gesture ended and we snap, but _childAngleSnapped is null,
      // because current rotation is outside all defined snap ranges.

      snap = _childAngle.getClosest(_snaps);

      if ((_childAngle - snap).abs() > Angle.half()) {
        // better to go over zero
        if (_childAngle > snap) {
          // needs to animate from quadrant IV to I
          snap += Angle.full();
        } else {
          // needs to animate from quadrant I to IV
          _controller.value += 2 * math.pi;
        }
      }

      var duration = widget.snapDuration;
      if (widget.shouldUseRelativeSnapDuration) {
        final minDistance = Angle.getMinimalDistance(_childAngle, snap);
        duration = Duration(
            milliseconds: (minDistance.ratio(Angle.full()) *
                    widget.snapDuration.inMilliseconds)
                .toInt());
      }

      _controller.animateTo(snap.radians,
          duration: duration, curve: widget.snapCurve);
    }
    // Callback providing current rotation angle and snap angle
    widget.onAngleChangedPanEnd?.call(_childAngle, snap);
  }

  void _startInertiaAnimation(double velocity) {
    _controller.stop();

    // Create a friction simulation with the current angle and velocity
    final simulation = FrictionSimulation(
      widget.frictionCoefficient,
      _childAngle.radians,
      velocity,
    );

    // Animate using the simulation
    _controller.animateWith(simulation);
  }
}

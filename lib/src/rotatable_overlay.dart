import 'dart:math' as math;
import 'package:angle_utils/angle_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  /// Whether the duration of the snap animation is constant or it should be calculated based on the relative angle it has to rotate
  final bool shouldUseRelativeSnapDuration;

  /// Determines the animation curve to the nearest snap angle
  final Curve snapCurve;

  /// Callback that is called when the rotation snaps.
  final void Function(Angle)? onSnap;

  /// Callback that is called when the angle of the rotation changes.
  final void Function(Angle)? onAngleChanged;
  
  /// Callback that is called when the pan gesture ends
  final void Function(Angle)? onAngleChangedPanEnd;

  /// Callback that is called when animation to the nearest snap angle is finished.
  final VoidCallback? onSnapAnimationEnd;

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

  late final AnimationController _controller = AnimationController(
    vsync: this,
    upperBound: 4 * math.pi,
  );

  Offset _centerOfChild = Offset.zero;

  @override
  void initState() {
    _childAngle = widget.initialRotation ?? Angle.zero();
    _childAngleSnapped = widget.initialRotation;
    _lastChangeAngle = _childAngle;

    _snapDelta = widget.snapDelta ?? Angle.zero();

    _snaps = widget.snaps ?? [];
    _snaps.sort((a, b) => a.compareTo(b));

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
    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;
    var newMouseAngle = Angle.atan2(dy, dx);
    setState(() {
      _mouseAngle = newMouseAngle;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    var dy = details.globalPosition.dy - _centerOfChild.dy;
    var dx = details.globalPosition.dx - _centerOfChild.dx;

    var newMouseAngle = Angle.atan2(dy, dx);
    var movedAngle = _mouseAngle - newMouseAngle;
    var newChildAngle = (_childAngle + movedAngle).normalized;

    var newChildAngleSnapped = _snapRanges
        .where((s) => s.includesNormalized(newChildAngle))
        .firstOrNull
        ?.mid;

    if (newChildAngleSnapped != null &&
        newChildAngleSnapped != _childAngleSnapped) {
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
    if (widget.shouldSnapOnEnd && !_snaps.contains(_childAngleSnapped)) {
      Angle snap = _childAngle.getClosest(_snaps);

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
    widget.onAngleChangedPanEnd?.call(_childAngle);
  }
}

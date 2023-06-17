import 'package:rotatable_overlay/src/angle.dart';

/// Represents an angle range.
class AngleRange {
  Angle from;
  Angle to;

  Angle get span => from - to;

  AngleRange({required this.from, required this.to});

  /// Constructs an angle range from the given [angle] by adding and substracting [delta].
  factory AngleRange.fromDelta(Angle angle, Angle delta) {
    return AngleRange(from: angle - delta, to: angle + delta);
  }

  /// Checks whether the given [angle] is in this angle range
  /// Note: [from] can be greater than [to], but then the range spans over the angle zero
  bool isInRange(Angle angle) {
    if (from < to) {
      return from < angle && angle < to;
    } else if (from > to) {
      return from < angle || angle < to;
    }
    return angle == from;
  }

  @override
  String toString() {
    return 'AngleRange(from: $from, to: $to)';
  }
}

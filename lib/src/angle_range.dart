import 'package:rotatable_overlay/src/angle.dart';

class AngleRange {
  Angle from;
  Angle to;

  Angle get span => from - to;

  AngleRange({required this.from, required this.to});

  factory AngleRange.fromDelta(Angle angle, Angle delta) {
    return AngleRange(from: angle - delta, to: angle + delta);
  }

  bool isInRange(Angle angle) {
    if(from < to) {
      return from < angle && angle < to;
    }
    return from < angle || angle < to;
  }

  @override
  String toString() {
    return 'AngleRange(from: $from, to: $to)';
  }
}
import 'dart:core';
import 'dart:math' as math;

class Angle implements Comparable<Angle> {
  late double _radians;

  set radians(double radians) {
    var r = radians.remainder(2 * math.pi);
    _radians = r < 0 ? 2 * math.pi + r : r;
  }

  double get radians => _radians;

  double get degrees => _radians / math.pi * 180;

  double get standardRadians => _radians < math.pi ? _radians : -2 * math.pi + _radians;

  Angle get supplement => Angle(radians: 2 * math.pi - _radians);

  Angle({required double radians}) {
    var r = radians.remainder(2 * math.pi);
    _radians = r < 0 ? 2 * math.pi + r : r;
  }

  factory Angle.degrees(final double degrees) {
    return Angle(radians: Angle.degreesToRadians(degrees));
  }

  factory Angle.radians(final double radians) {
    return Angle(radians: radians);
  }

  Angle difference(Angle other) {
    // min{|α−β|, 360° −|α−β|}
    return Angle(radians: math.min((_radians - other.radians).abs(), 2*math.pi - (_radians - other.radians).abs()));
  }

  Angle operator -(Angle other) {
    var newRadians = _radians - other.radians;
    return Angle(radians: newRadians);
  }

  Angle operator +(Angle other) {
    var newRadians =  _radians + other.radians;
    return Angle(radians: newRadians);
  }

  bool operator >(Angle other) {
    return _radians > other.radians;
  }

  bool operator <(Angle other) {
    return _radians < other.radians;
  }

  @override
  bool operator ==(Object other) {
    return (other is Angle) && _radians == other.radians;
  }

  @override
  int compareTo(Angle other) {
    if (this > other) {
      return 1;
    } else if (this < other) {
      return -1;
    }
    return 0;
  }

  @override
  int get hashCode => radians.hashCode;

  @override
  String toString() {
    return 'Angle(radians: $_radians, degrees: $degrees)';
  }

  static double degreesToRadians(double degrees) {
    return degrees / 180 * math.pi;
  }

  static double radiansToDegrees(double radians) {
    return radians / math.pi * 180;
  }

  static final Angle zero = Angle(radians: 0);
  static final Angle half = Angle(radians: math.pi);

  static final Angle a0 = Angle(radians: 0);
  static final Angle a90 = Angle(radians: math.pi / 2);
  static final Angle a180 = Angle(radians: math.pi);
  static final Angle a270 = Angle(radians: 3 * math.pi / 2);
}

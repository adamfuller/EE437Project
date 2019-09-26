/// Class to convert SensorService's angle outputs into a command
/// or string of commands to send over bluetooth.
class SteeringService {
  static SteeringService _steeringService;
  static const double _pi = 3.14159265358979323846264;
  static Map<int, int> _cache = {}; // Map of intent to an extent

  // How far can the device be turned without triggering differential steering.
  static const double steeringPlay = 0.1;

  // How far until the throttle kicks the car out of neutral.
  static const double throttlePlay = 0.05;

  static const int rightForward = DriverConnection.in1;
  static const int rightBackward = DriverConnection.in2;
  static const int leftBackward = DriverConnection.in3;
  static const int leftForward = DriverConnection.in4;
  static const int rightPower = DriverConnection.enA;
  static const int leftPower = DriverConnection.enB;

  static bool isInNeutral = true;

  factory SteeringService() {
    return _steeringService;
  }

  static Map<int, int> get cache => _cache; // Map of intent to an extent

  /// Caches a list of commands depending on the input values.
  ///
  /// x, y, and z should be radians values representing the device's orientation.
  ///
  /// throttle should be a value between -1 and 1 representing the desired throttle.
  ///
  /// Outputs will be the connection name followed by an intensity value between 0 and 1
  ///
  /// ex: IN1 0.5
  static void accept(double x, double y, double z, double throttle) {
    // Put z in the range -2π < z < 2π
    // Full left is π/2
    // Full right is -π/2
    z = (z / z.abs()) * (((z.abs() % (2 * _pi)) > (_pi / 2.0)) ? _pi / 2.0 : z.abs());

    // Don't activate steering until out of play zone.
    bool isStraight = z.abs() <= steeringPlay;

    bool isTurningLeft = !isStraight && z > 0;
    bool isTurningRight = !isStraight && z < 0;

    // If throttle is negative go backwards.
    bool isForward = throttle.abs() == throttle;

    // Set throttle between 0 and 1.
    throttle = throttle.abs();

    int throttleBits = (throttle * 31).toInt();

    // Arbitrary strength or inside motor during turn
    double turnPower = throttle * (1 - z.abs() / (_pi / 2));
    int turnPowerBits = (turnPower * 31).toInt();

    // Set the opposite directions to 0 power.
    _cache[(isForward ? leftBackward : leftForward)] = 0;
    _cache[(isForward ? rightBackward : rightForward)] = 0;

    _cache[(isForward ? leftForward : leftBackward)] = 31;
    _cache[(isForward ? rightForward : rightBackward)] = 31;

    if (isStraight) {
      _cache[leftPower] = throttleBits;
      _cache[rightPower] = throttleBits;
    } else if (turnPower > 0) {
      // Making a turn.
      if (isTurningLeft) {
        _cache[leftPower] = turnPowerBits;
        _cache[rightPower] = throttleBits;
      } else if (isTurningRight) {
        _cache[leftPower] = throttleBits;
        _cache[rightPower] = turnPowerBits;
      } else {
        // This shouldn't happen.
      }
    }

  }

  /// Adds low left and right power to the cache.
  static void goNeutral() {
    isInNeutral = true;
    _cache[leftPower] = 0;
    _cache[rightPower] = 0;
  }
}

class DriverConnection {
  static const int in1 = 0x01;
  static const int in2 = 0x02;
  static const int in3 = 0x03;
  static const int in4 = 0x04;
  static const int enA = 0x05;
  static const int enB = 0x06;
}

// TODO: Explore using a Map<String, String> instead of List<String>

/// Class to convert SensorService's angle outputs into a command
/// or string of commands to send over bluetooth.
class SteeringService {
  static SteeringService _steeringService;
  static const double _pi = 3.14159265358979323846264;
  static Map<String, String> _cache = {};

  // How far can the device be turned without triggering differential steering.
  static const double steeringPlay = 0.1;

  // How far until the throttle kicks the car out of neutral.
  static const double throttlePlay = 0.05;

  static const String leftForward = DriverConnection.in1;
  static const String leftBackward = DriverConnection.in2;
  static const String rightForward = DriverConnection.in3;
  static const String rightBackward = DriverConnection.in4;
  static const String leftPower = DriverConnection.enA;
  static const String rightPower = DriverConnection.enB;

  static bool isInNeutral = true;

  factory SteeringService() {
    return _steeringService;
  }

  static Map<String, String> get cache => _cache;

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
    List<String> output = [];

    // Put z in the range -2π < z < 2π
    // Full left is π/2
    // Full right is -π/2
    z = (z / z.abs()) * (((z.abs() % (2 * _pi)) > (_pi / 2.0)) ? _pi / 2.0 : z.abs());

    // Don't activate steering until out of play zone.
    bool isStraight = z.abs() < steeringPlay;

    bool isTurningLeft = !isStraight && z > 0;
    bool isTurningRight = !isStraight && z < 0;

    // If throttle is negative go backwards.
    bool isForward = throttle.abs() == throttle;

    // Set throttle between 0 and 1.
    throttle = throttle.abs();

    // Arbitrary strength or inside motor during turn
    double turnPower = throttle * (1 - z.abs() / (_pi / 2));

    if (isInNeutral && throttle > throttlePlay) {
      output.addAll([
        "$rightPower HIGH",
        "$leftPower HIGH",
      ]);
      isInNeutral = false;
    }

    // Hold either forward or backward value.
    String left = isForward ? leftForward : leftBackward;
    String right = isForward ? rightForward : rightBackward;

    // Set the opposite directions to 0 power.
    output.add(isForward ? "$leftBackward 0.00" : "$leftForward 0.00");
    output.add(isForward ? "$rightBackward 0.00" : "$rightForward 0.00");

    if (isStraight) {
      output.addAll([
        "$left ${throttle.toStringAsFixed(2)}",
        "$right ${throttle.toStringAsFixed(2)}",
      ]);
    } else if (turnPower > 0) {
      // Making a turn.
      if (isTurningLeft) {
        output.addAll([
          "$left ${turnPower.toStringAsFixed(2)}",
          "$right ${throttle.toStringAsFixed(2)}",
        ]);
      } else if (isTurningRight) {
        output.addAll([
          "$left ${throttle.toStringAsFixed(2)}",
          "$right ${turnPower.toStringAsFixed(2)}",
        ]);
      } else {
        // This shouldn't happen.
      }
    }

    _cacheResult(output);
  }

  /// Adds low left and right power to the cache.
  static void goNeutral() {
    isInNeutral = true;
    List<String> output = [
      "$leftPower LOW",
      "$rightPower LOW",
    ];
    _cacheResult(output);
  }

  static void _cacheResult(List<String> data) => data.forEach((value) => _cache[value.split(" ")[0]] = value.split(" ")[1]);
}

class DriverConnection {
  static const String in1 = "IN1";
  static const String in2 = "IN2";
  static const String in3 = "IN3";
  static const String in4 = "IN4";
  static const String enA = "ENA";
  static const String enB = "ENB";
}

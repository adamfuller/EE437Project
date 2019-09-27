import 'dart:typed_data';

/// Class to convert SensorService's angle outputs into a command
/// or string of commands to send over bluetooth.
class SteeringService {
  static SteeringService _steeringService;
  static const double _pi = 3.14159265358979323846264;

  // List of commands to be executed;
  static Map<Intent, Extent> _cache = {};

  // How far can the device be turned without triggering differential steering.
  static const double steeringPlay = 0.1;

  // How far until the throttle kicks the car out of neutral.
  static const double throttlePlay = 0.05;

  /// Map of intent to extent for braking.
  static final Uint8List brake = Uint8List.fromList([
    (Intent.leftForward.value << 5) | Extent.none.value,
    (Intent.rightForward.value << 5) | Extent.none.value,
    (Intent.leftBackward.value << 5) | Extent.none.value,
    (Intent.rightBackward.value << 5) | Extent.none.value,
    (Intent.leftPower.value << 5) | Extent.none.value,
    (Intent.rightPower.value << 5) | Extent.none.value,
  ]);

  static final Uint8List spinLeft = Uint8List.fromList([
    (Intent.leftForward.value << 5) | Extent.none.value,
    (Intent.rightForward.value << 5) | Extent.max.value,
    (Intent.leftBackward.value << 5) | Extent.max.value,
    (Intent.rightBackward.value << 5) | Extent.none.value,
    (Intent.leftPower.value << 5) | Extent.max.value,
    (Intent.rightPower.value << 5) | Extent.max.value,
  ]);

  static final Uint8List spinRight = Uint8List.fromList([
    (Intent.leftForward.value << 5) | Extent.max.value,
    (Intent.rightForward.value << 5) | Extent.none.value,
    (Intent.leftBackward.value << 5) | Extent.none.value,
    (Intent.rightBackward.value << 5) | Extent.max.value,
    (Intent.leftPower.value << 5) | Extent.max.value,
    (Intent.rightPower.value << 5) | Extent.max.value,
  ]);

  static bool isInNeutral = true;

  factory SteeringService() {
    return _steeringService;
  }

  /// Returns a Map of Intent to an Extent.
  static Map<Intent, Extent> get cache => _cache;

  /// Returns a list of bytes representing the cached commands.
  static Uint8List get cacheCommands => Uint8List.fromList(_cache.entries.fold(<int>[], (l, com) => l..add(commandValue(com.key, com.value))));

  /// Returns the byte value of the command for a set intent and extent.
  static int commandValue(Intent i, Extent e) => (i.value << 5) | e.value;

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

    // Arbitrary strength or inside motor during turn
    double turnPower = throttle * (1 - z.abs() / (_pi / 2));

    // Set the opposite directions to 0 power.
    _cache[(isForward ? Intent.leftBackward : Intent.leftForward)] = Extent.none;
    _cache[(isForward ? Intent.rightBackward : Intent.rightForward)] = Extent.none;

    _cache[(isForward ? Intent.leftForward : Intent.leftBackward)] = Extent.max;
    _cache[(isForward ? Intent.rightForward : Intent.rightBackward)] = Extent.max;

    _cache[Intent.leftPower] = Extent.fromUnit((isTurningLeft ? turnPower : throttle));
    _cache[Intent.rightPower] = Extent.fromUnit((isTurningRight ? turnPower : throttle));
  }

  /// Adds low left and right power to the cache.
  static void goNeutral() {
    isInNeutral = true;
    _cache[Intent.leftPower] = Extent.none;
    _cache[Intent.rightPower] = Extent.none;
  }


}

class Extent {
  static const Extent max = Extent(maxValue);
  static const Extent none = Extent(0);
  static const maxValue = 31;

  final int value;

  const Extent(this.value);

  /// Returns an extent with a value of __val__ * __Extent.maxValue__
  factory Extent.fromUnit(double val) => Extent(((val % 1.0) * maxValue).toInt());
}

class Intent {
  static const Intent rightForward = Intent(DriverConnection.in1);
  static const Intent rightBackward = Intent(DriverConnection.in2);
  static const Intent leftBackward = Intent(DriverConnection.in3);
  static const Intent leftForward = Intent(DriverConnection.in4);
  static const Intent rightPower = Intent(DriverConnection.enA);
  static const Intent leftPower = Intent(DriverConnection.enB);

  final int value;

  const Intent(this.value);
}

class DriverConnection {
  static const int in1 = 0x01;
  static const int in2 = 0x02;
  static const int in3 = 0x03;
  static const int in4 = 0x04;
  static const int enA = 0x05;
  static const int enB = 0x06;
}

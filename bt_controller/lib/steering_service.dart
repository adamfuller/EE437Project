import 'dart:typed_data';

/// Class to convert SensorService's angle outputs into a command
/// or string of commands to send over bluetooth.
class SteeringService {
  //
  // Private Variables
  //
  static SteeringService _steeringService;
  static const double _pi = 3.14159265358979323846264;

  // Map of Intent to extent for commands;
  static Map<Intent, Extent> _cache = {};

  static Map<Intent, Extent> _lastReceived = {};

  // List of commands to be executed;
  static Uint8List _commandsCache;

  //
  // Public Variables
  //

  // How far can the device be turned without triggering differential steering.
  static const double steeringPlay = 0.1;

  // How far until the throttle kicks the car out of neutral.
  static const double throttlePlay = 0.05;

  /// List with command for braking.
  static final Uint8List brake = Uint8List.fromList([0xE0]);

  /// List with command for spinning right
  static final Uint8List spinRight = Uint8List.fromList([0xE1]);

  /// List with command for spinning left
  static final Uint8List spinLeft = Uint8List.fromList([0xE2]);

  static final Uint8List cancel = Uint8List.fromList([0xEF]);

  static bool isInNeutral = true;

  factory SteeringService() {
    return _steeringService;
  }

  //
  // Getters
  //

  /// Returns a Map of Intent to an Extent.
  static Map<Intent, Extent> get cache => _cache;

  /// Returns a list of bytes representing the cached commands.
  static Uint8List get cacheCommands => _commandsCache;

  //
  // Public methods
  //

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

    // If steering forward don't supply power backwards and vice versa.
    _cache[(isForward ? Intent.leftBackward : Intent.leftForward)] = Extent.none;
    _cache[(isForward ? Intent.rightBackward : Intent.rightForward)] = Extent.none;

    // Supply power in the direction of motion.
    _cache[(isForward ? Intent.leftForward : Intent.leftBackward)] = Extent.max;
    _cache[(isForward ? Intent.rightForward : Intent.rightBackward)] = Extent.max;

    // Modulate actual power supplied based on steering angle.
    _cache[Intent.leftPower] = Extent.fromUnit((isTurningLeft ? turnPower : throttle));
    _cache[Intent.rightPower] = Extent.fromUnit((isTurningRight ? turnPower : throttle));

    _commandsCache = Uint8List.fromList(_cache.entries.fold(<int>[], (l, com) {
      if (_lastReceived.containsKey(com.key) && _lastReceived[com.key] == com.value) return l;
      return l..add(_commandValue(com.key, com.value));
    }));
  }

  /// Adds low left and right power to the cache.
  static void goNeutral() {
    isInNeutral = true;
    _cache[Intent.leftPower] = Extent.none;
    _cache[Intent.rightPower] = Extent.none;
  }

  static void updateLastReceived(Uint8List vals) {
    _lastReceived.clear();
    List<int> data = vals.toList();
    for (int i = 0; i < data.length; i++) {
      _lastReceived[Intent(data[i] & 0xE0)] = Extent(data[i] & 0x1F);
    }
  }

  //
  // Private Methods
  //

  /// Returns the byte value of the command for a set intent and extent.
  static int _commandValue(Intent i, Extent e) => (i.value << 5) | e.value;
}

/// Abstraction class for bits 0-4 of signal sent to arduino
class Extent {
  /// Extent representing a value of 31 or Extent.maxValue
  static const Extent max = Extent(maxValue);

  /// Extent representing a value of 0
  static const Extent none = Extent(0);

  static const maxValue = 31;

  // Current integer value of this extent
  final int value;

  /// Create a new Extent instance with a value of __value__
  const Extent(this.value);

  @override
  int get hashCode => this.value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != this.runtimeType) return false;
    return other.value == this.value;
  }

  /// Returns an extent with a value of __val__ * __Extent.maxValue__
  factory Extent.fromUnit(double val) => val >= 1.0 ? Extent.max : Extent(((val) * maxValue).toInt());
}

/// Abstraction class for bits 5-7 of signal sent to arduino
class Intent {
  /// Intent instance for driving the right side forward.
  static const Intent rightForward = Intent(DriverConnection.in1);

  /// Intent instance for driving the right side backward.
  static const Intent rightBackward = Intent(DriverConnection.in2);

  /// Intent instance for driving the left side backward.
  static const Intent leftBackward = Intent(DriverConnection.in3);

  /// Intent instance for driving the left side forward.
  static const Intent leftForward = Intent(DriverConnection.in4);

  /// Intent instance for supplying for to the right side.
  static const Intent rightPower = Intent(DriverConnection.enA);

  /// Intent instance for supplying for to the left side.
  static const Intent leftPower = Intent(DriverConnection.enB);

  final int value;

  const Intent(this.value);

  @override
  int get hashCode => this.value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != this.runtimeType) return false;
    return other.value == this.value;
  }
}

/// Class to hold values correlating to each connection to the driver.
class DriverConnection {
  static const int in1 = 0x01;
  static const int in2 = 0x02;
  static const int in3 = 0x03;
  static const int in4 = 0x04;
  static const int enA = 0x05;
  static const int enB = 0x06;
}

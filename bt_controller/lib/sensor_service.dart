import 'package:sensors/sensors.dart';

class SensorService {
  static SensorService _sensorService;
  // Number of sensor readings to be averaged.
  static const averageCycleDuration = 5;

  // Current angle of the device in radians
  static double _xAngle = 0;
  static double _yAngle = 0;
  static double _zAngle = 0; // Plane of the screen

  // Previous values retrieved from the gyroscope (rad/s)
  static List<double> _xGyroPrev = [];
  static List<double> _yGyroPrev = [];
  static List<double> _zGyroPrev = [];

  // Time between measurements in seconds
  static List<double> _times = [];

  static List<DateTime> _dates = [];

  static List<void Function(double, double, double)> _gyroListeners = [];

  // This turns the class into a singleton (all instances are the same instance)
  factory SensorService() {
    // Return the static instance of SensorService.
    return _sensorService;
  }

  // Starts listening to the sensors and recording to the averaging lists.
  static void start() {
    _initGyroscope();
  }

  static void _initGyroscope() {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      // Remove previous measurements and only hold the most recent few
      _xGyroPrev = _xGyroPrev.take(averageCycleDuration).toList()..insert(0, event.x);
      _yGyroPrev = _yGyroPrev.take(averageCycleDuration).toList()..insert(0, event.y);
      _zGyroPrev = _zGyroPrev.take(averageCycleDuration).toList()..insert(0, event.z);
      _dates = _dates.take(averageCycleDuration).toList()..insert(0, DateTime.now());

      if (_dates.length < 2) return;

      // Calculate the time that has passed since last measurement. (seconds)
      double timeBetween = _dates[0].difference(_dates[1]).inMilliseconds / 1000.0;

      // Add the time to the array.
      _times = _times.take(averageCycleDuration).toList()..insert(0, timeBetween);

      // Calculate the angular acceleration. (rad/s^2)s
      double _xAccel = (_xGyroPrev[0] - _xGyroPrev[1]) / timeBetween;
      double _yAccel = (_yGyroPrev[0] - _yGyroPrev[1]) / timeBetween;
      double _zAccel = (_zGyroPrev[0] - _zGyroPrev[1]) / timeBetween;

      // θnew = θold + w*t + 1/2 * a & t^2
      _xAngle = _xAngle + _xGyroPrev[0] * timeBetween + 0.5 * _xAccel * timeBetween * timeBetween;
      _yAngle = _yAngle + _yGyroPrev[0] * timeBetween + 0.5 * _yAccel * timeBetween * timeBetween;
      _zAngle = _zAngle + _zGyroPrev[0] * timeBetween + 0.5 * _zAccel * timeBetween * timeBetween;

      // Send the averages to all the listeners.
      _gyroListeners?.forEach((_) => _(_xAngle, _yAngle, _zAngle));
    });
  }

  static void zero() {
    _xAngle = 0;
    _yAngle = 0;
    _zAngle = 0;
    _xGyroPrev.clear();
    _yGyroPrev.clear();
    _zGyroPrev.clear();
    _times.clear();
    _dates.clear();
  }

  // Listen to the sensors.
  static void listen(void Function(double, double, double) onChange) => _gyroListeners.add(onChange);
}

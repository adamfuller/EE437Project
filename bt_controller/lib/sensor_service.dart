import 'package:sensors/sensors.dart';

class SensorService {
  static SensorService _sensorService;
  // Current angle of the device in radians
  static double _xAngle = 0;
  static double _yAngle = 0;
  static double _zAngle = 0; // Plane of the screen

  // Previous values retrieved from the gyroscope (rad/s)
  static double _prevXGyro = 0.0;
  static double _prevYGyro = 0.0;
  static double _prevZGyro = 0.0;

  static DateTime _prevDate;

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
      DateTime now = DateTime.now();

      // If no previous values are recorded wait till next input.
      if (_prevDate == null) {
        _prevDate = now;
        _prevXGyro = event.x;
        _prevYGyro = event.y;
        _prevZGyro = event.z;
        return;
      }

      // Calculate the time that has passed since last measurement. (seconds)
      double timeBetween = now.difference(_prevDate).inMilliseconds / 1000.0;

      // Calculate the angular acceleration. (rad/s^2)s
      double _xAccel = (event.x - _prevXGyro) / timeBetween;
      double _yAccel = (event.y - _prevYGyro) / timeBetween;
      double _zAccel = (event.z - _prevZGyro) / timeBetween;

      // θnew = θold + w*t + 1/2 * a & t^2
      _xAngle = _xAngle + event.x * timeBetween + 0.5 * _xAccel * timeBetween * timeBetween;
      _yAngle = _yAngle + event.y * timeBetween + 0.5 * _yAccel * timeBetween * timeBetween;
      _zAngle = _zAngle + event.z * timeBetween + 0.5 * _zAccel * timeBetween * timeBetween;

      _prevXGyro = event.x;
      _prevYGyro = event.y;
      _prevZGyro = event.z;
      _prevDate = now;
      // Send the averages to all the listeners.
      if (!_xAngle.isNaN && !_yAngle.isNaN && !_zAngle.isNaN) _gyroListeners?.forEach((_) => _(_xAngle, _yAngle, _zAngle));
    });
  }

  static void zero() {
    _xAngle = 0;
    _yAngle = 0;
    _zAngle = 0;
    _prevXGyro = 0.0;
    _prevYGyro = 0.0;
    _prevZGyro = 0.0;
    _prevDate = DateTime.now();
  }

  // Listen to the sensors.
  static void listen(void Function(double, double, double) onChange) => _gyroListeners.add(onChange);
}

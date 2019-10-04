import 'package:sensors/sensors.dart';

class SensorService {
  /// Static instance of class. Creating singleton.
  static SensorService _sensorService;

  /// Current angle of the device about the x axis (vertical center) in radians.
  static double _xAngle = 0;

  /// Current angle of the device about the y axis (horizontal center) in radians.
  static double _yAngle = 0;

  /// Current angle of the device about the z axis (orthogonal to the screen) in radians.
  static double _zAngle = 0;

  /// Previous angular velocity about x axis in rad/s
  static double _prevXGyro = 0.0;

  /// Previous angular velocity about y axis in rad/s
  static double _prevYGyro = 0.0;

  /// Previous angular velocity about z axis in rad/s
  static double _prevZGyro = 0.0;

  /// Last time a measurement has been recorded.
  static DateTime _prevDate;

  /// List holding all callbacks for the listener.
  static List<void Function(double, double, double)> _gyroListeners = [];

  // This turns the class into a singleton (all instances are the same instance)
  factory SensorService() {
    // Return the static instance of SensorService.
    return _sensorService;
  }

  /// Starts listening to the sensors.
  ///
  /// __listen__ callbacks will now be triggered.
  static void start() => _initGyroscope();

  /// Initialize the gyroscope listener and begin callbacks.
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

      // Set previous values for taking difference on next recording.
      _prevXGyro = event.x;
      _prevYGyro = event.y;
      _prevZGyro = event.z;
      _prevDate = now;

      // Send the averages to all the listeners.
      if (!_xAngle.isNaN && !_yAngle.isNaN && !_zAngle.isNaN) _gyroListeners?.forEach((_) => _(_xAngle, _yAngle, _zAngle));
    });
  }

  /// Set all recorded measurements to zero and last recorded time to now.
  static void zero() {
    _xAngle = 0;
    _yAngle = 0;
    _zAngle = 0;
    _prevXGyro = 0.0;
    _prevYGyro = 0.0;
    _prevZGyro = 0.0;
    _prevDate = DateTime.now();
  }

  /// Listen to the gyroscope.
  ///
  /// Call __start__ to begin triggering callbacks.
  static void listen(void Function(double, double, double) onChange) => _gyroListeners.add(onChange);
}

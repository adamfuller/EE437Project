import 'package:sensors/sensors.dart';
import "dart:math";

class SensorService {
  static SensorService _sensorService;
  // Number of sensor readings to be averaged.
  static const averageCycleDuration = 5;

  // Average of the last 20 values
  static double _xAccAvg = 0;
  static double _yAccAvg = 0;
  static double _zAccAvg = 0;
  static double _xNormAccAvg = 0;
  static double _yNormAccAvg = 0;
  static double _zNormAccAvg = 0;

  // Last 20 values retrieved from the accelerometer
  static List<double> _xAcc = [];
  static List<double> _yAcc = [];
  static List<double> _zAcc = [];
  static List<double> _xNormAcc = [];
  static List<double> _yNormAcc = [];
  static List<double> _zNormAcc = [];

  static List<void Function(double, double, double)> _listeners = [];
  static List<void Function(double, double, double)> _normalizedListeners = [];

  // This turns the class into a singleton (all instances are the same instance)
  factory SensorService() {
    // Return the static instance of SensorService.
    return _sensorService;
  }

  // Starts listening to the sensors and recording to the averaging lists.
  static void start() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double total = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      _xAcc = _xAcc.take(averageCycleDuration).toList()..insert(0, event.x);
      _yAcc = _yAcc.take(averageCycleDuration).toList()..insert(0, event.y);
      _zAcc = _zAcc.take(averageCycleDuration).toList()..insert(0, event.z);

      _xNormAcc = _xNormAcc.take(averageCycleDuration).toList()..insert(0, event.x.abs() / total);
      _yNormAcc = _yNormAcc.take(averageCycleDuration).toList()..insert(0, event.y.abs() / total);
      _zNormAcc = _zNormAcc.take(averageCycleDuration).toList()..insert(0, event.z.abs() / total);

      _xAccAvg = 0;
      _yAccAvg = 0;
      _zAccAvg = 0;
      _xNormAccAvg = 0;
      _yNormAccAvg = 0;
      _zNormAccAvg = 0;

      int n = 0;
      _xAcc.forEach((val) => _xAccAvg = (_xAccAvg * n + val) / (n += 1));

      n = 0;
      _yAcc.forEach((val) => _yAccAvg = (_yAccAvg * n + val) / (n += 1));

      n = 0;
      _zAcc.forEach((val) => _zAccAvg = (_zAccAvg * n + val) / (n += 1));

      n = 0;
      _xNormAcc.forEach((val) => _xNormAccAvg = (_xNormAccAvg * n + val) / (n += 1));

      n = 0;
      _yNormAcc.forEach((val) => _yNormAccAvg = (_yNormAccAvg * n + val) / (n += 1));

      n = 0;
      _zNormAcc.forEach((val) => _zNormAccAvg = (_zNormAccAvg * n + val) / (n += 1));

      // Send the averages to all the listeners.
      _listeners?.forEach((_) => _(_xAccAvg, _yAccAvg, _zAccAvg));
      _normalizedListeners?.forEach((_) => _(_xNormAccAvg, _yNormAccAvg, _zNormAccAvg));
    });

    // gyroscopeEvents.listen((GyroscopeEvent event) {});
  }

  // Listen to the sensors.
  static void listen(void Function(double, double, double) onChange) => _listeners.add(onChange);
  static void listenNormalized(void Function(double, double, double) onChange) => _normalizedListeners.add(onChange);
}

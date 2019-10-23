import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sensor_service.dart';
import 'steering_service.dart' as ss;
import 'bluetooth_service.dart';

const String deviceMacAddress = "98:D3:B1:F5:B3:BF";

class HomeViewModel {
  //
  // Private Properties
  //
  Function onDataChanged;
  static const double _pi = 3.14159265358979323846264;

  double _throttleValue = 5.0;
  bool _isSpinningRight = false;
  bool _isSpinningLeft = false;

  //
  // Public Properties
  //
  
  /// True if the phone is connected to a device.
  bool isConnected = false;

  /// Currently connected MAC address.
  String connectedAddress;

  /// False if showing the sensor data, true if showing the brake button.
  bool showControls = true;

  /// Maximum value on the throttle slider.
  double throttleMax = 10.0;

  /// Timer instance for transmitting data.
  Timer btTimer;

  /// String holding incoming data from arduino.
  String btListen = "";

  /// If false the phone will send no more inputs to the arduino.
  bool isAcceptingInputs = true;

  /// True if the phone is currently connecting to the arduino.
  bool isConnecting = false;

  /// True if using the throttle slider for speed control.
  bool useThrottleSlider = true;

  /// True if the brake is being held down.
  bool isBraking = false;

  /// String representation of current angle about x axis;
  String xString = "0.000";

  /// String representation of current angle about y axis;
  String yString = "0.000";

  /// String representation of current angle about z axis;
  String zString = "0.000";

  //
  // Getters
  //

  double get throttleValue => _throttleValue;

  List<String> get currentState {
    if (isBraking) {
      return ss.SteeringService.brake.fold([], (l, val) => l..add(val.toRadixString(2).padLeft(8, '0')));
    } else if (_isSpinningLeft) {
      return ss.SteeringService.spinLeft.fold([], (l, val) => l..add(val.toRadixString(2).padLeft(8, '0')));
    } else if (_isSpinningRight) {
      return ss.SteeringService.spinRight.fold([], (l, val) => l..add(val.toRadixString(2).padLeft(8, '0')));
    }
    return ss.SteeringService.cacheCommands.fold([], (l, val) => l..add(val.toRadixString(2).padLeft(8, '0')));
  }

  //
  // Constructor
  //
  HomeViewModel(this.onDataChanged) {
    init();
  }

  //
  // Public functions
  //

  /// Initialize sensor listener and bluetooth timer callback.
  void init() {
    SensorService.listen(
      (x, y, z) {
        xString = x.toStringAsFixed(4);
        yString = y.toStringAsFixed(4);
        zString = z.toStringAsFixed(4);

        double throttleVal = (_throttleValue - throttleMax / 2.0) / (throttleMax / 2.0);

        if (!useThrottleSlider) {
          if (y.abs() > _pi / 2.0) {
            // Use the sign of y
            throttleVal = (y / y.abs());
          } else {
            throttleVal = y / (_pi / 2.0);
          }
        }

        ss.SteeringService.accept(x, y, z, throttleVal);
        onDataChanged();
      },
    );

    SensorService.start();

    this.btTimer = Timer.periodic(Duration(milliseconds: 50), (_) {
      if (!isAcceptingInputs) return;
      if (isBraking) {
        BluetoothService.sendData(connectedAddress, ss.SteeringService.brake);
        return;
      } else if (_isSpinningRight) {
        BluetoothService.sendData(connectedAddress, ss.SteeringService.spinRight);
        return;
      } else if (_isSpinningLeft) {
        BluetoothService.sendData(connectedAddress, ss.SteeringService.spinLeft);
        return;
      }

      BluetoothService.sendData(connectedAddress, ss.SteeringService.cacheCommands);
    });
  }

  //
  //  Button Callbacks
  //

  // Callback for the connect button.
  void bluetoothButtonPressed(BuildContext context) async {
    if (isConnected) {
      BluetoothService.close();
      this.isConnected = false;
      this.connectedAddress = null;
      onDataChanged();
      return;
    }

    isConnecting = true;
    onDataChanged();

    bool successfullyConnected = await BluetoothService.listen(
      deviceMacAddress,
      (address, data) {
        ss.SteeringService.updateLastReceived(data);
        btListen += String.fromCharCodes(data.toList());
        while (btListen.contains("\n")) btListen = btListen.substring(btListen.indexOf("\n") + 1);
      },
      onDisconnect: () {
        // Clears the last received list
        ss.SteeringService.updateLastReceived(Uint8List.fromList([]));
        BluetoothService.close(address: deviceMacAddress);
        _showAlertDialog(context, "Disconnected", "You have been disconnected from the bluetooth device");
        this.isConnected = false;
        onDataChanged();
      },
    );

    SensorService.zero();

    if (!successfullyConnected) await _showAlertDialog(context, "Error", "Failed connect to bluetooth device");
    if (successfullyConnected) await _showAlertDialog(context, "Connected", "Connected to bluetooth device");

    this.isConnected = successfullyConnected;
    this.connectedAddress = deviceMacAddress;
    this.isConnecting = false;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]);
    onDataChanged();
  }

  /// Callback when throttle slider changes.
  void updateThrottle(double value) {
    _throttleValue = value;
    onDataChanged();
  }

  /// Callback when the brake button is pressed.
  void brakePressed(TapDownDetails details) {
    isBraking = true;
    onDataChanged();
  }

  /// Callback when the brake button is released.
  void brakeReleased(TapUpDetails details) {
    isBraking = false;
    onDataChanged();
  }

  /// Callback when the show data/show controls button is pressed.
  void toggleControlsPressed() {
    this.showControls = !this.showControls;
    onDataChanged();
  }

  /// Callback when the center button is pressed.
  void zeroControlsPressed() {
    SensorService.zero();
    onDataChanged();
  }

  /// Callback when the neutral button is pressed.
  void zeroThrottlePressed() {
    _throttleValue = throttleMax / 2.0;
    ss.SteeringService.goNeutral();
    onDataChanged();
  }

  /// Callback when the spin right, spin left, or cancel spin buttons are pressed.
  void spinRight(bool val) {
    _isSpinningRight = val;
    onDataChanged();
  }

  /// Callback when the spin right, spin left, or cancel spin buttons are pressed.
  void spinLeft(bool val) {
    _isSpinningLeft = val;
    onDataChanged();
  }

  Future<void> _showAlertDialog(BuildContext context, String title, String subtitle) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(title),
          content: Text(subtitle),
          actions: <Widget>[
            FlatButton(
              child: const Text("Ok"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  //
  // Dispose
  //
  void dispose() {
    this.btTimer.cancel();
    BluetoothService.close();
  }
}

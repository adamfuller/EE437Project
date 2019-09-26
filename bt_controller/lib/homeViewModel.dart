import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sensor_service.dart';
import 'steering_service.dart';
import 'bluetooth_service.dart';

const String deviceMacAddress = "98:D3:B1:F5:B3:BF";

class HomeViewModel {
  //
  // Private Properties
  //
  Function onDataChanged;
  static const double _pi = 3.14159265358979323846264;

  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  double _xNorm, _yNorm, _zNorm;
  double _throttleValue = 5.0;
  Map<int, int> previousState = {};

  //
  // Public Properties
  //
  Color cardColor = Colors.white;
  bool isConnected = false;
  String connectedAddress;
  bool showControls = true;
  double throttleMax = 10.0;
  Timer btTimer;
  String btListen = "";
  bool isAcceptingInputs = true;
  bool isConnecting = false;
  bool useThrottleSlider = true;

  //
  // Getters
  //

  String get xString => _x.toStringAsFixed(4);
  String get yString => _y.toStringAsFixed(4);
  String get zString => _z.toStringAsFixed(4);

  String get xNormString => _xNorm.toStringAsFixed(4);
  String get yNormString => _yNorm.toStringAsFixed(4);
  String get zNormString => _zNorm.toStringAsFixed(4);

  double get throttleValue => _throttleValue;

  List<String> get currentState => SteeringService.cache.entries.fold(<String>[], (list, e) => list..add(((e.key << 5) + e.value).toRadixString(2)));

  bool get isDebug {
    bool val = false;
    assert(val = true);
    return val;
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
  void init() {
    SensorService.listen(
      (x, y, z) {
        this._x = x;
        this._y = y;
        this._z = z;

        double throttleVal = (_throttleValue - throttleMax / 2.0) / (throttleMax / 2.0);

        if (!useThrottleSlider){
          if (y.abs() > _pi/2.0) {
            // Use the sign of y
            throttleVal = (y/y.abs());
          } else {
            throttleVal = y / (_pi/2.0);
          }
        }

        SteeringService.accept(x, y, z, throttleVal );
        onDataChanged();
      },
    );

    SensorService.start();

    this.btTimer = Timer.periodic(Duration(milliseconds: 50), (_) {
      if (!isAcceptingInputs) return;
      Map<int, int> state = SteeringService.cache;
      Uint8List commands = Uint8List.fromList(state.entries.fold(<int>[], (list, e) => list..add((e.key << 5) + e.value)));

      BluetoothService.sendData(connectedAddress, commands);
    });
  }

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
        // print("Do something here!!!!");
        // print(String.fromCharCodes(data.toList()));
        btListen += String.fromCharCodes(data.toList());
        while (btListen.contains("\n")) {
          print(btListen.substring(0, btListen.indexOf("\n")));
          btListen = btListen.substring(btListen.indexOf("\n") + 1);
        }
        // print(btListen.length);
      },
    );

    previousState = {};
    SensorService.zero();

    if (!successfullyConnected) await showAlertDialog(context, "Error", "Failed connect to bluetooth device");
    if (successfullyConnected) await showAlertDialog(context, "Connected", "Connected to bluetooth device");

    this.isConnected = successfullyConnected;
    this.connectedAddress = deviceMacAddress;
    this.isConnecting = false;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]);
    onDataChanged();
  }

  void updateThrottle(double value) {
    _throttleValue = value;
    onDataChanged();
  }

  void brakePressed(TapDownDetails details) {
    this.cardColor = Colors.red;
    SteeringService.goNeutral();
    onDataChanged();
  }

  void brakeReleased(TapUpDetails details) {
    this.cardColor = Colors.white;
    onDataChanged();
  }

  void toggleControlsPressed() {
    this.showControls = !this.showControls;

    onDataChanged();
  }

  void zeroControlsPressed() {
    SensorService.zero();
    onDataChanged();
  }

  void zeroThrottlePressed() {
    _throttleValue = throttleMax / 2.0;
    SteeringService.goNeutral();
    onDataChanged();
  }

  //
  // Dispose
  //
  void dispose() {
    this.btTimer.cancel();
    BluetoothService.close();
  }
}

Future<String> showInputDialog(
  BuildContext context,
  String title, {
  String subtitle,
  TextInputType keyboardType,
  String hintText,
  int maxLines,
  String confirmText,
}) async {
  TextEditingController _inputController = TextEditingController();
  return showDialog<String>(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              subtitle != null ? Text(subtitle ?? "") : null,
              TextField(
                autofocus: true,
                keyboardType: keyboardType ?? TextInputType.text,
                controller: _inputController,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
              ),
            ]..removeWhere((_) => _ == null),
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
            child: Text(confirmText ?? "Ok"),
            onPressed: () => Navigator.of(context).pop(_inputController.text),
          ),
        ]..removeWhere((_) => _ == null),
      );
    },
  );
}

Future<void> showAlertDialog(BuildContext context, String title, String subtitle) async {
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

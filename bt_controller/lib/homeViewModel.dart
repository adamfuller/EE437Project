import 'dart:async';

import 'package:bt_controller/steering_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensor_service.dart';

import 'bluetooth_service.dart';

class HomeViewModel {
  //
  // Private Properties
  //
  Function onDataChanged;

  BluetoothService _bluetoothService;

  double _x, _y, _z;
  double _xNorm, _yNorm, _zNorm;
  double _throttleValue = 0.0;

  //
  // Public Properties
  //
  Color cardColor = Colors.white;
  bool isConnected = false;
  String connectedAddress;
  bool showControls = true;
  double throttleMax = 10.0;
  Timer btTimer;

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

  List<String> commands = [];
  List<String> lastCommands = [];

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
    _bluetoothService = BluetoothService();

    SensorService.listen(
      (x, y, z) {
        this._x = x;
        this._y = y;
        this._z = z;
        this.lastCommands = commands.isNotEmpty ? commands : lastCommands;
        List<String> _commands = SteeringService.accept(x, y, z, _throttleValue / 10.0);
        if (!_commands.every((_) => lastCommands.contains(_))){
          this.commands.addAll(_commands);
          onDataChanged();
        }
      },
    );

    SensorService.start();

    this.btTimer = Timer.periodic(Duration(milliseconds: 50), (_) {
      this.commands.forEach((command) {
        _bluetoothService?.sendString(connectedAddress, command);
      });
      this.commands.clear();
    });
  }

  void bluetoothButtonPressed(BuildContext context) async {
    if (isConnected) {
      _bluetoothService.close();
      this.isConnected = false;
      this.connectedAddress = null;
      onDataChanged();
      return;
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]);
    String input = await showInputDialog(context, "Enter device BT mac address", confirmText: "Connect");

    if (input == null || input.isEmpty) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIOverlays([]);
      return;
    }

    bool successfullyConnected = await _bluetoothService.listen(
      input,
      (address, data) {
        print("Do something here!!!!");
      },
    );

    if (!successfullyConnected) await showAlertDialog(context, "Error", "Failed connect to bluetooth device");
    if (successfullyConnected) await showAlertDialog(context, "Connected", "Connected to bluetooth device");

    this.isConnected = successfullyConnected;
    this.connectedAddress = input;

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
    _throttleValue = 0.0;
    this.commands.addAll(SteeringService.goNeutral());
    onDataChanged();
  }

  //
  // Dispose
  //
  void dispose() {
    this.btTimer.cancel();
    this._bluetoothService.close();
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

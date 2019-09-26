import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sensor_service.dart';
import 'steering_service.dart';
import 'bluetooth_service.dart';

class HomeViewModel {
  //
  // Private Properties
  //
  Function onDataChanged;

  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  double _xNorm, _yNorm, _zNorm;
  double _throttleValue = 0.0;
  Map<String, String> previousState = {};

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

  List<String> get currentState => SteeringService.cache.entries.fold(<String>[], (val, entry) => val..add(entry.key + " " + entry.value));

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

        SteeringService.accept(x, y, z, _throttleValue / 10.0);
        // this.commands.addAll(_commands);
        onDataChanged();
      },
    );

    SensorService.start();

    this.btTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      Map<String, String> state = SteeringService.cache;

      for (MapEntry entry in state.entries) {
        String key = entry.key;
        String value = entry.value;

        if (!previousState.containsKey(key) || previousState[key] != state[key]) {
          BluetoothService.sendString(connectedAddress, "$key $value");
          // print("$key $value");
          previousState[key] = value;
        }
      }
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
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    // ]);
    // SystemChrome.setEnabledSystemUIOverlays([]);
    // String input = await showInputDialog(context, "Enter device BT mac address", confirmText: "Connect");

    // if (input == null || input.isEmpty) {
    //   SystemChrome.setPreferredOrientations([
    //     DeviceOrientation.landscapeLeft,
    //   ]);
    //   SystemChrome.setEnabledSystemUIOverlays([]);
    //   return;
    // }

    bool successfullyConnected = await BluetoothService.listen(
      "98:D3:B1:F5:B3:BF",
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

    if (!successfullyConnected) await showAlertDialog(context, "Error", "Failed connect to bluetooth device");
    if (successfullyConnected) await showAlertDialog(context, "Connected", "Connected to bluetooth device");

    this.isConnected = successfullyConnected;
    this.connectedAddress = "98:D3:B1:F5:B3:BF";

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
    _throttleValue = 0.0;
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

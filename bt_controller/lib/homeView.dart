import 'package:flutter/material.dart';

import "homeViewModel.dart";

class HomeView extends StatefulWidget {
  HomeView();

  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  HomeViewModel vm;

  @override
  void initState() {
    vm = HomeViewModel(() {
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8.0, left: 8.0),
          child: _getThrottle(),
        ),
        VerticalDivider(
          endIndent: 0.0,
        ),
        Expanded(
          child: _getButtonsAndBrake(),
        ),
      ],
    );
  }

  Widget _getButtonsAndBrake() {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 0.0),
          child: _getTopButtons(),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.zero,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 18.0),
          child: vm.showControls ? _getBrake() : _getSensorData(),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _getSensorData() {
    return Column(
      children: <Widget>[
        Text("X: ${vm.xString}"),
        Text("Y: ${vm.yString}"),
        Text("Z: ${vm.zString}"),
        Text(
          "Throttle: ${(vm.throttleValue / vm.throttleMax).toStringAsFixed(4)}",
        )
      ].followedBy(vm.currentState.map<Widget>((command) => Text(command))).toList(),
    );
  }

  Widget _getThrottle() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _getZeroThrottleButton(),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.0,
                thumbColor: Colors.black,
                // activeTrackColor: Colors.blue[100],
                // inactiveTrackColor: Colors.blue,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                // overlayColor: Colors.purple.withAlpha(32),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                value: vm.throttleValue,
                min: -1 * vm.throttleMax,
                max: vm.throttleMax,
                // divisions: 2,
                onChanged: vm.updateThrottle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getBrake() {
    return GestureDetector(
      onTapDown: vm.brakePressed,
      onTapUp: vm.brakeReleased,
      onLongPressStart: (_) => vm.brakePressed(null),
      onLongPressEnd: (_) => vm.brakeReleased(null),
      // onTapCancel: () => vm.brakeReleased(null),
      child: Card(
        color: vm.cardColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(100),
          child: Text(
            "Brake",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _getTopButtons() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _getBluetoothButton(),
        vm.isDebug
            ? _getToggleControlsButton()
            : Padding(
                padding: EdgeInsets.zero,
              ),
        _getZeroControlsButton(),
      ],
    );
  }

  Widget _getBluetoothButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: Text(vm.isConnected ? "Connected" : "Connect"),
      color: vm.isConnected ? Colors.blue : Colors.white,
      textColor: vm.isConnected ? Colors.white : Colors.blue,
      icon: Icon(
        vm.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color: vm.isConnected ? Colors.white : Colors.blue,
      ),
      onPressed: () => vm.bluetoothButtonPressed(context),
    );
  }

  Widget _getToggleControlsButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: Text(vm.showControls ? "Show Data" : "Show Controls"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: Icon(
        vm.showControls ? Icons.swap_horizontal_circle : Icons.swap_horizontal_circle,
        color: Colors.blue,
      ),
      onPressed: vm.toggleControlsPressed,
    );
  }

  Widget _getZeroControlsButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: Text("Center"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: Icon(
        Icons.linear_scale,
        color: Colors.blue,
      ),
      onPressed: () => vm.zeroControlsPressed(),
    );
  }

  Widget _getZeroThrottleButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: Text("Neutral"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: Icon(
        Icons.exposure_zero,
        color: Colors.blue,
      ),
      onPressed: () => vm.zeroThrottlePressed(),
    );
  }
}

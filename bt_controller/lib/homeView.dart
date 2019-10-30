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
        vm.useThrottleSlider ? _getThrottle() : _getNothing(),
        vm.useThrottleSlider ? VerticalDivider(endIndent: 0.0) : _getNothing(),
        _getMainControls(),
      ],
    );
  }

  Widget _getMainControls() {
    return Expanded(
      child: Column(
        children: <Widget>[
          _getTopButtons(),
          _getExpander(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _getToggles(),
              VerticalDivider(),
              Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: vm.showControls ? _getBrake() : _getSensorData(),
              ),
            ],
          ),
          _getExpander(),
        ],
      ),
    );
  }

  Widget _getSensorData() {
    return Column(
      children: <Widget>[
        Text("X: ${vm.xString}"),
        Text("Y: ${vm.yString}"),
        Text("Z: ${vm.zString}"),
        Text(
          "Throttle: ${((vm.throttleValue - vm.throttleMax / 2) / (vm.throttleMax / 2.0)).toStringAsFixed(4)}",
        )
      ].followedBy(vm.currentState.map<Widget>((command) => Text(command))).toList(),
    );
  }

  Widget _getThrottle() {
    return Padding(
      padding: EdgeInsets.only(top: 8.0, left: 8.0),
      child: Column(
        children: [
          _getZeroThrottleButton(),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.0,
                  thumbColor: Colors.black,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
                ),
                child: Slider(
                  value: vm.throttleValue,
                  max: vm.throttleMax,
                  onChanged: vm.updateThrottle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getToggles() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _labeledCheckBox(vm.isAcceptingInputs, "Accept Inputs", (b) {
          setState(() {
            vm.isAcceptingInputs = b;
          });
        }),
        _labeledCheckBox(vm.useThrottleSlider, "Use Throttle Slider", (b) {
          setState(() {
            vm.useThrottleSlider = b;
          });
        }),
        _getSpinRightButton(),
        _getSpinLeftButton(),
        _getCancelSpinButton(),
      ],
    );
  }

  Widget _labeledCheckBox(bool value, String text, void Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Text(text),
      ],
    );
  }

  Widget _getSpinRightButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: const Text("Spin Right"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: const Icon(Icons.rotate_right),
      onPressed: () => vm
        ..spinLeft(false)
        ..spinRight(true),
    );
  }

  Widget _getSpinLeftButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: const Text("Spin Left"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: const Icon(Icons.rotate_left),
      onPressed: () => vm
        ..spinRight(false)
        ..spinLeft(true),
    );
  }

  Widget _getCancelSpinButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: const Text("Cancel Spin"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: const Icon(Icons.cancel),
      onPressed: () => vm
        ..spinRight(false)
        ..spinLeft(false)
        ..cancelSpin(),
    );
  }

  Widget _getBrake() {
    return GestureDetector(
      onTapDown: vm.brakePressed,
      onTapUp: vm.brakeReleased,
      onLongPressStart: (_) => vm.brakePressed(null),
      onLongPressEnd: (_) => vm.brakeReleased(null),
      child: Card(
        color: vm.isBraking ? Colors.red : Theme.of(context).cardColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(100),
          child: const Text(
            "Brake",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _getTopButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _getBluetoothButton(),
          _getShowDataButton(),
          _getZeroControlsButton(),
        ],
      ),
    );
  }

  Widget _getBluetoothButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: Text(vm.isConnected ? "Connected" : (vm.isConnecting ? "Connecting..." : "Connect")),
      color: vm.isConnected ? Colors.blue : Colors.white,
      textColor: vm.isConnected ? Colors.white : Colors.blue,
      icon: vm.isConnecting
          ? SizedBox(child: CircularProgressIndicator(), height: 20, width: 20)
          : Icon(
              vm.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: vm.isConnected ? Colors.white : Colors.blue,
            ),
      onPressed: () => vm.bluetoothButtonPressed(context),
    );
  }

  Widget _getShowDataButton() {
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
      label: const Text("Center"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: const Icon(
        Icons.linear_scale,
        color: Colors.blue,
      ),
      onPressed: () => vm.zeroControlsPressed(),
    );
  }

  Widget _getZeroThrottleButton() {
    return RaisedButton.icon(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      label: const Text("Neutral"),
      color: Colors.white,
      textColor: Colors.blue,
      icon: const Icon(
        Icons.exposure_zero,
        color: Colors.blue,
      ),
      onPressed: () => vm.zeroThrottlePressed(),
    );
  }

  Widget _getNothing() => const Padding(padding: EdgeInsets.zero);

  Widget _getExpander() => Expanded(child: _getNothing());
}

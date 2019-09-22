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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _getBluetoothButton(),
          Expanded(
            child: _getInputs(),
          ),
        ],
      ),
    );
  }

  Widget _getInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(padding: EdgeInsets.zero),
        ),
        _getThrottle(),
        Expanded(
          child: Padding(padding: EdgeInsets.zero),
        ),
        Expanded(
          child: Padding(padding: EdgeInsets.zero),
        ),
        Expanded(
          child: Padding(padding: EdgeInsets.zero),
        ),
        _getBrake(),
        Expanded(
          child: Padding(padding: EdgeInsets.zero),
        ),
      ],
    );
  }

  Widget _getThrottle() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: RotatedBox(
              quarterTurns: 1,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.0,
                  thumbColor: Colors.black,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                  overlayColor: Colors.purple.withAlpha(32),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
                ),
                child: Slider(
                  value: vm.throttleValue,
                  min: -10.0,
                  max: 10.0,
                  onChanged: vm.updateThrottle,
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _getBluetoothButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: RaisedButton.icon(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          label: Text(vm.isConnected ? "Connected" : "Connect"),
          color: vm.isConnected ? Colors.blue : Colors.white,
          textColor: vm.isConnected ? Colors.white : Colors.blue,
          icon: Icon(
            vm.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: vm.isConnected ? Colors.green : Colors.blue,
          ),
          onPressed: vm.isConnected ? () {} : () => vm.bluetoothButtonPressed(context),
        ),
      ),
    );
  }
}

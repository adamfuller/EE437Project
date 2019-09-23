import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import "package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart";

class BluetoothService {
  static BluetoothService _bluetoothService;
  static Map<String, BluetoothConnection> _connections = HashMap();
  static List<StreamSubscription> _listeners = [];

  factory BluetoothService(){
    print("BluetoothService created");
    return _bluetoothService;
  }

  static Future<void> _connectIfNotAlready(String address) async => _connections.containsKey(address) ? null : _connections[address] = await BluetoothConnection.toAddress(address);

  static Future<bool> listen(String address, void Function(String, Uint8List) onEvent) async {
    try {
      // Connect to the device if we aren't already.
      await _connectIfNotAlready(address);

      var listener = _connections[address].input.listen((data) => onEvent(address, data));

      // Add the listener for the events.
      _listeners.add(listener);
      return true;
    } catch (e) {
      return false;
    }
  }

  static void sendData(String address, Uint8List data) => _connections[address]?.output?.add(data);

  static void sendString(String address, String text) => sendData(address, utf8.encode(text + "\r\n"));


  static void close({String address}) {
    // Only cancel one if it is selected.
    if (address != null){
      _connections[address]?.close();
      _connections.removeWhere((key, v)=> key == address);
      return;
    }

    // Cancel all the listener callbacks.
    _listeners.forEach((_) => _.cancel());

    // Close all bluetooth connections
    _connections.forEach((s, _) => _.close());

    // Clear the listener list
    _listeners.clear();

    // Clear the connections map
    _connections.clear();
  }
}

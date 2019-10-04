import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import "package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart";

class BluetoothService {
  static BluetoothService _bluetoothService;
  static Map<String, BluetoothConnection> _connections = HashMap();
  static List<StreamSubscription> _listeners = [];

  factory BluetoothService() {
    print("BluetoothService created");
    return _bluetoothService;
  }

  /// Connect to a device over bluetooth only if it isn't already.
  static Future<void> _connectIfNotAlready(String address) async => _connections.containsKey(address) ? null : _connections[address] = await BluetoothConnection.toAddress(address);

  /// Begin listening for output from a device with mac address of __address.
  ///
  /// This will connect to the device if not already.
  static Future<bool> listen(String address, void Function(String, Uint8List) onEvent, {void Function() onDisconnect}) async {
    try {
      // Connect to the device if we aren't already.
      await _connectIfNotAlready(address);

      // Attach listener.
      var listener = _connections[address].input.listen((data) => onEvent(address, data));

      listener.onDone(onDisconnect ?? (){});

      // Add the listener for the events.
      _listeners.add(listener);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send __data__ to device connected with a MAC address of __address__
  static void sendData(String address, Uint8List data) {
    if (!_connections.containsKey(address)) return;

    if (_connections[address]?.isConnected ?? false) {
      _connections[address]?.output?.add(data);
    }
  }

  static void close({String address}) {
    // Only cancel one if it is selected.
    if (address != null) {
      _connections[address]?.close();
      _connections.removeWhere((key, v) => key == address);
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

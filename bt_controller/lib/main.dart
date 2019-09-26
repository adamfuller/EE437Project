import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'homeView.dart';

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(AppWrapper());
}

class AppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EE 437 Controller',
      theme: ThemeData(brightness: Brightness.light),
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

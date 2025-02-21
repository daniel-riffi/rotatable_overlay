import 'package:flutter/material.dart';
import 'package:rotatable_overlay/rotatable_overlay.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: RotatableOverlay(
              snaps: [
                Angle.degrees(0),
                Angle.degrees(90),
                Angle.degrees(180),
                Angle.degrees(270),
              ],
              snapDelta: Angle.degrees(5),
              shouldSnapOnEnd: true,
              shouldUseRelativeSnapDuration: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    color: Colors.green,
                  ),
                  const Positioned(
                    top: 0,
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: Text(
                      'S',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

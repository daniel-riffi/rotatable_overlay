## RotatableOverlay

A flutter widget that makes its child rotatable by dragging around its center.

### Usage

```dart
RotatableOverlay(
    child: Container(
        height: 50,
        width: 50,
        color: Colors.green,
    ),
)
```

### Parameters

| Parameter | Description |
|---|---|
| `child` | Child widget that will be rotatable |
| `initialRotation` | Sets the initial rotation of the child |
| `snaps` | A list of angles to which the rotation snaps |
| `snapDelta` | Determines how close the rotation has to be to a snap angle in order to snap |
| `shouldSnapOnEnd` | If `true` the rotation will animate to the nearest snap angle when stopped dragging |
| `snapDuration` | Determines how long the animation will take if `shouldSnapOnEnd` is `true` |
| `shouldUseRelativeSnapDuration` | Whether the duration of the snap animation is constant or it should be calculated based on the relative angle it has to rotate |
| `snapCurve` | Determines the animation curve to the nearest snap angle |
| `onSnap` | Callback that is called when the rotation snaps |
| `onAngleChanged` | Callback that is called when the angle of the rotation changes |
| `onSnapAnimationEnd` | Callback that is called when animation to the nearest snap angle is finished |

### Example

![rotatable_overlay_example](https://github.com/daniel-riffi/rotatable_overlay/assets/48239596/a8d96979-530e-4985-9f77-9bd622e20547)

```dart
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
                    child: Text('N', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Positioned(
                    right: 0,
                    child: Text('E', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Positioned(
                    left: 0,
                    child: Text('W', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: Text('S', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
```

### Contact

If you find any bugs or have ideas for new features, feel free to send me an email! 👋 \
📧 riffert.daniel@gmail.com

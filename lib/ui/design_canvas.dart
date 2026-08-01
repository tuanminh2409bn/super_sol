import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double mockupWidth = 589;
const double mockupHeight = 1280;
Future<void> showDeviceStatusBar({
  required bool darkIcons,
  required Color backgroundColor,
}) async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top],
  );
  final style = darkIcons
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;
  SystemChrome.setSystemUIOverlayStyle(
    style.copyWith(
      statusBarColor: backgroundColor,
      systemStatusBarContrastEnforced: false,
    ),
  );
}

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / mockupWidth,
            constraints.maxHeight / mockupHeight,
          );
          return Center(
            child: SizedBox(
              width: mockupWidth * scale,
              height: mockupHeight * scale,
              child: FittedBox(
                // The canvas keeps the mockup aspect ratio. `contain` avoids
                // stretching glyphs and icon edges when a device's dimensions
                // do not divide cleanly into the design canvas.
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: mockupWidth,
                  height: mockupHeight,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      color: Color(0xFF151820),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

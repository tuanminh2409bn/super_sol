import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_canvas.dart';

/// The approved PIN demo: a single pale grey arc, with no circular track.
class PinLoadingOverlay extends StatefulWidget {
  const PinLoadingOverlay({super.key});

  static const minimumDisplayDuration = Duration(milliseconds: 800);

  @override
  State<PinLoadingOverlay> createState() => _PinLoadingOverlayState();
}

class _PinLoadingOverlayState extends State<PinLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 2200)
        : const Duration(milliseconds: 500);
    if (_rotation.duration != duration) {
      _rotation.duration = duration;
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: AbsorbPointer(
        child: Semantics(
          label: '인증 중',
          liveRegion: true,
          child: ColoredBox(
            color: const Color(0x0F0F1420),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  constraints.maxWidth / mockupWidth,
                  constraints.maxHeight / mockupHeight,
                );
                return Center(
                  child: RotationTransition(
                    turns: _rotation,
                    child: CustomPaint(
                      size: Size.square(56 * scale),
                      painter: const PinLoadingArcPainter(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PinLoadingArcPainter extends CustomPainter {
  const PinLoadingArcPainter();

  static const color = Color(0xFFA6A6A6);
  static const sweepAngle = 2 * math.pi * .12;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 56;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: 22 * scale),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(PinLoadingArcPainter oldDelegate) => false;
}

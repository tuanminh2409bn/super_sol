import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/ui/pin_loading_overlay.dart';

void main() {
  test('approved spinner paints only one 12 percent pale grey arc', () {
    void paint(Canvas canvas) =>
        const PinLoadingArcPainter().paint(canvas, const Size.square(56));
    expect(
      paint,
      paints..arc(
        rect: Rect.fromCircle(center: const Offset(28, 28), radius: 22),
        startAngle: -math.pi / 2,
        sweepAngle: 2 * math.pi * .12,
        useCenter: false,
        color: const Color(0xFFA6A6A6),
        strokeWidth: 5,
        strokeCap: StrokeCap.round,
        style: PaintingStyle.stroke,
      ),
    );
    expect(paint, paintsExactlyCountTimes(#drawArc, 1));
    expect(paint, paintsExactlyCountTimes(#drawCircle, 0));
  });

  testWidgets('spinner rotates once per 500ms and respects reduced motion', (
    tester,
  ) async {
    Future<void> host(bool reduced) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const SizedBox.expand(child: PinLoadingOverlay()),
        ),
      ),
    );
    await host(false);
    await tester.pump(const Duration(milliseconds: 100));
    final rotation = tester.widget<RotationTransition>(
      find.byType(RotationTransition),
    );
    expect(rotation.turns.value, closeTo(.2, .001));
    await tester.pump(const Duration(milliseconds: 500));
    expect(rotation.turns.value, closeTo(.2, .001));
    await host(true);
    await tester.pump(const Duration(milliseconds: 220));
    expect(rotation.turns.value, closeTo(.3, .001));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

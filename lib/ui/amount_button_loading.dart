import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The approved amount-entry demo, measured on the 589px design canvas.
class AmountButtonContent extends StatelessWidget {
  const AmountButtonContent({
    super.key,
    required this.loading,
    this.labelStyle,
  });

  static const displayDuration = Duration(milliseconds: 700);
  final bool loading;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: loading,
      label: loading ? '처리 중' : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '다음',
            style:
                labelStyle ??
                const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  fontVariations: [FontVariation('wght', 700)],
                ),
          ),
          ClipRect(
            child: AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 130),
              curve: Curves.easeOut,
              width: loading ? 38 : 0,
              height: 26,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 38,
                maxWidth: 38,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: AnimatedOpacity(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 90),
                    opacity: loading ? 1 : 0,
                    child: loading
                        ? const _AmountButtonSpinner()
                        : const SizedBox.square(dimension: 26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountButtonSpinner extends StatefulWidget {
  const _AmountButtonSpinner();

  @override
  State<_AmountButtonSpinner> createState() => _AmountButtonSpinnerState();
}

class _AmountButtonSpinnerState extends State<_AmountButtonSpinner>
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
  Widget build(BuildContext context) => SizedBox.square(
    key: const Key('amount-button-loading'),
    dimension: 26,
    child: ExcludeSemantics(
      child: RotationTransition(
        turns: _rotation,
        child: const CustomPaint(painter: _AmountButtonArcPainter()),
      ),
    ),
  );
}

class _AmountButtonArcPainter extends CustomPainter {
  const _AmountButtonArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: 10),
      -math.pi / 2,
      2 * math.pi * .12,
      false,
      Paint()
        ..color = const Color(0xFFD7D9DE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AmountButtonArcPainter oldDelegate) => false;
}

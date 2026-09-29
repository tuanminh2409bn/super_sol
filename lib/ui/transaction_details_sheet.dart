import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_data.dart';
import 'design_canvas.dart';

const _ink = Color(0xFF141820);
const _secondary = Color(0xFF505866);
const _blue = Color(0xFF005CFF);

Future<void> showTransactionDetailsSheet(
  BuildContext context, {
  required LedgerTransaction transaction,
  required int runningBalance,
}) {
  final media = MediaQuery.of(context);
  final designHeight = transaction.incoming ? 694.0 : 773.0;
  final scale = math.min(
    media.size.width / mockupWidth,
    (media.size.height - media.padding.top - media.viewPadding.bottom) /
        designHeight,
  );
  // The reference already includes 47 design pixels below the buttons.
  final extraBottom = math.max(0.0, media.viewPadding.bottom - 47 * scale);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x990F1420),
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 300),
      reverseDuration: Duration(milliseconds: 250),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: extraBottom),
      child: SizedBox(
        width: media.size.width,
        height: designHeight * scale,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          child: MediaQuery(
            data: media.copyWith(textScaler: TextScaler.noScaling),
            child: SizedBox(
              width: mockupWidth,
              height: designHeight,
              child: _TransactionDetailsSheet(
                transaction: transaction,
                runningBalance: runningBalance,
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TransactionDetailsSheet extends StatelessWidget {
  const _TransactionDetailsSheet({
    required this.transaction,
    required this.runningBalance,
    required this.onClose,
  });

  final LedgerTransaction transaction;
  final int runningBalance;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'NotoSansKR',
        color: _secondary,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontVariations: [FontVariation('wght', 500)],
        letterSpacing: -.6,
      ),
      child: Stack(
        key: const Key('transaction-details-sheet'),
        children: [
          Positioned(
            left: 28,
            top: 30,
            child: Semantics(
              header: true,
              child: const Text(
                '거래내역상세',
                style: TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontVariations: [FontVariation('wght', 700)],
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          Positioned(
            right: 21,
            top: 21,
            child: IconButton(
              key: const Key('transaction-details-close'),
              tooltip: '닫기',
              onPressed: onClose,
              icon: const _SheetIcon(_SheetGlyph.close, size: 31),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 99,
            child: Text(
              transaction.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const Positioned(
            left: 28,
            right: 28,
            top: 141,
            child: _MemoPreview(),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 283,
            child: _TransactionTable(
              transaction: transaction,
              runningBalance: runningBalance,
            ),
          ),
          if (!transaction.incoming)
            Positioned(
              top: 557,
              left: 205,
              width: 179,
              height: 55,
              child: Semantics(
                button: true,
                enabled: false,
                child: Container(
                  key: const Key('transaction-details-result'),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이체결과조회',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontVariations: [FontVariation('wght', 700)],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 23, color: _ink),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 47,
            height: 79,
            child: Row(
              children: [
                Semantics(
                  label: '공유',
                  button: true,
                  enabled: false,
                  child: Container(
                    width: 67,
                    height: 73,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF0FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: _SheetIcon(_SheetGlyph.share, size: 31),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox.expand(
                    child: FilledButton(
                      key: const Key('transaction-details-confirm'),
                      onPressed: onClose,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          fontVariations: [FontVariation('wght', 700)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// These secondary controls match the reference; editing/sharing is a later feature.
class _MemoPreview extends StatelessWidget {
  const _MemoPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          height: 79,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD6D7DB), width: 1.5),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '20자 이내로 메모',
                  style: TextStyle(
                    color: Color(0xFF9298A2),
                    fontSize: 25,
                    fontVariations: [FontVariation('wght', 400)],
                  ),
                ),
              ),
              _SheetIcon(_SheetGlyph.edit, size: 33),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '0',
                  style: TextStyle(color: _blue),
                ),
                TextSpan(text: '/20자'),
              ],
            ),
            style: TextStyle(
              color: Color(0xFF747C89),
              fontSize: 19,
              fontVariations: [FontVariation('wght', 400)],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTable extends StatelessWidget {
  const _TransactionTable({
    required this.transaction,
    required this.runningBalance,
  });

  final LedgerTransaction transaction;
  final int runningBalance;

  @override
  Widget build(BuildContext context) {
    final date = transaction.occurredAt;
    String two(int value) => value.toString().padLeft(2, '0');
    final rows = [
      (
        '거래일시',
        '${date.year}.${two(date.month)}.${two(date.day)} '
            '${two(date.hour)}:${two(date.minute)}:${two(date.second)}',
      ),
      ('거래구분', transaction.channel),
      (
        '거래금액',
        '${transaction.incoming ? '' : '-'}${_money(transaction.signedAmount.abs())}원',
      ),
      ('거래 후 잔액', '${_money(runningBalance)}원'),
    ];
    return Table(
      key: const Key('transaction-details-table'),
      columnWidths: const {0: FixedColumnWidth(169)},
      border: const TableBorder(
        top: BorderSide(color: Color(0xFF777F8A), width: 1.5),
        bottom: BorderSide(color: Color(0xFFE4E5E9)),
        horizontalInside: BorderSide(color: Color(0xFFE4E5E9)),
        verticalInside: BorderSide(color: Color(0xFFE4E5E9)),
      ),
      children: [
        for (final row in rows)
          TableRow(
            children: [
              Container(
                height: 62.5,
                color: const Color(0xFFF8F9FE),
                alignment: Alignment.center,
                child: Text(
                  row.$1,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 62.5,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  row.$2,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?<!^)(?=(\d{3})+$)'),
  (_) => ',',
);

enum _SheetGlyph { close, edit, share }

class _SheetIcon extends StatelessWidget {
  const _SheetIcon(this.glyph, {required this.size});

  final _SheetGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SheetIconPainter(glyph));
}

class _SheetIconPainter extends CustomPainter {
  const _SheetIconPainter(this.glyph);

  final _SheetGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);
    final paint = Paint()
      ..color = glyph == _SheetGlyph.share ? _blue : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case _SheetGlyph.close:
        canvas.drawLine(const Offset(6, 6), const Offset(26, 26), paint);
        canvas.drawLine(const Offset(26, 6), const Offset(6, 26), paint);
      case _SheetGlyph.edit:
        canvas.drawPath(
          Path()
            ..moveTo(4, 28)
            ..lineTo(5, 21)
            ..lineTo(23, 3)
            ..quadraticBezierTo(25, 1, 27, 3)
            ..lineTo(29, 5)
            ..quadraticBezierTo(31, 7, 29, 9)
            ..lineTo(11, 27)
            ..close()
            ..moveTo(20, 6)
            ..lineTo(26, 12)
            ..moveTo(5, 21)
            ..lineTo(11, 27),
          paint,
        );
      case _SheetGlyph.share:
        canvas.drawLine(const Offset(9, 15), const Offset(23, 7), paint);
        canvas.drawLine(const Offset(9, 18), const Offset(23, 25), paint);
        for (final point in [
          const Offset(6, 16),
          const Offset(26, 6),
          const Offset(26, 26),
        ]) {
          canvas.drawCircle(point, 3.1, paint);
        }
    }
  }

  @override
  bool shouldRepaint(_SheetIconPainter oldDelegate) =>
      glyph != oldDelegate.glyph;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/ui/amount_button_loading.dart';
import 'package:super_sol/ui/transfer_recipient_screen.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform amount button matches approved loading demo', (
      tester,
    ) async {
      final store = AppDataStore.inMemory();
      final balances = [
        for (final account in store.accounts) store.balanceFor(account.id),
      ];
      await _openAmount(tester, platform: platform, store: store);
      final next = find.byKey(const Key('transfer-next'));
      final label = find.descendant(of: next, matching: find.text('다음'));
      final originalCenter = tester.getCenter(label).dx;
      expect(originalCenter, closeTo(tester.getCenter(next).dx, .01));
      expect(find.byKey(const Key('amount-button-loading')), findsNothing);

      await tester.tap(next);
      await tester.pump();
      expect(find.byKey(const Key('amount-button-loading')), findsOneWidget);
      expect(find.text('보내기'), findsNothing);
      final button = tester.widget<FilledButton>(next);
      expect(button.onPressed, isNull);
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        const Color(0xFF0969F6),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getCenter(label).dx, closeTo(originalCenter - 19, .01));
      final spinner = find.byKey(const Key('amount-button-loading'));
      expect(tester.getSize(spinner), const Size.square(26));
      expect(
        tester.getRect(spinner).left,
        closeTo(tester.getRect(label).right + 12, .01),
      );
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: spinner, matching: find.byType(CustomPaint)),
      );
      void paint(Canvas canvas) =>
          customPaint.painter!.paint(canvas, const Size.square(26));
      expect(
        paint,
        paints..arc(
          rect: Rect.fromCircle(center: const Offset(13, 13), radius: 10),
          startAngle: -math.pi / 2,
          sweepAngle: 2 * math.pi * .12,
          useCenter: false,
          color: const Color(0xFFD7D9DE),
          // Canvas stores paint widths as float32, not Dart's float64.
          strokeWidth: (Paint()..strokeWidth = 3.2).strokeWidth,
          strokeCap: StrokeCap.round,
          style: PaintingStyle.stroke,
        ),
      );
      expect(paint, paintsExactlyCountTimes(#drawArc, 1));
      expect(paint, paintsExactlyCountTimes(#drawCircle, 0));
      final rotation = tester.widget<RotationTransition>(
        find.descendant(of: spinner, matching: find.byType(RotationTransition)),
      );
      expect(rotation.turns.value, closeTo(.3, .001));
      // Repeated taps and keypad edits must not skip the loading or change the amount.
      await tester.tapAt(tester.getCenter(next));
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('amount-key-9'))),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('transfer-back'))),
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('5원'), findsOneWidget);
      expect(spinner, findsOneWidget);
      expect(find.text('보내기'), findsNothing);
      expect(find.byKey(const Key('transfer-pin-loading')), findsNothing);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(spinner, findsNothing);
      expect(find.text('보내기'), findsOneWidget);
      expect(find.byKey(const Key('transfer-pin-keypad')), findsNothing);
      expect([
        for (final account in store.accounts) store.balanceFor(account.id),
      ], balances);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('closing amount loading cancels navigation safely', (
    tester,
  ) async {
    await _openAmount(tester);
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pump();
    expect(find.byKey(const Key('amount-button-loading')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('보내기'), findsNothing);
  });

  testWidgets('zero amount cannot start loading', (tester) async {
    await _openAmount(tester);
    await tester.tap(find.byKey(const Key('amount-delete')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('amount-button-loading')), findsNothing);
    expect(find.text('얼마를 보낼까요?'), findsOneWidget);
  });

  testWidgets('amount spinner repeats and respects reduced motion', (
    tester,
  ) async {
    Future<void> host(bool reduced) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Center(child: AmountButtonContent(loading: true)),
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

  testWidgets('amount button preserves the existing manual-entry label style', (
    tester,
  ) async {
    const labelStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AmountButtonContent(loading: false, labelStyle: labelStyle),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('다음')).style, labelStyle);
    expect(find.byKey(const Key('amount-button-loading')), findsNothing);
  });
}

Future<void> _openAmount(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.iOS,
  AppDataStore? store,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(589, 1280);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: TransferRecipientScreen(
        dataStore: store ?? AppDataStore.inMemory(),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('amount-key-5')));
  await tester.pump();
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/ui/transfer_recipient_screen.dart';

void main() {
  for (final config in [
    (size: const Size(589, 1280), navigation: 48.0, gesture: 0.0),
    (size: const Size(360, 808), navigation: 24.0, gesture: 0.0),
    (size: const Size(412, 915), navigation: 48.0, gesture: 0.0),
    (size: const Size(360, 808), navigation: 0.0, gesture: 24.0),
  ]) {
    testWidgets('Android transfer controls avoid navigation inset $config', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = config.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final bottomInset = config.navigation > config.gesture
          ? config.navigation
          : config.gesture;
      await tester.pumpWidget(
        _host(
          config.size,
          TargetPlatform.android,
          navigation: config.navigation,
          gesture: config.gesture,
        ),
      );
      await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('amount-key-5')));
      await tester.pump();
      final next = find.byKey(const Key('transfer-next'));
      final nextRect = tester.getRect(next);
      expect(
        nextRect.bottom,
        lessThanOrEqualTo(config.size.height - bottomInset),
      );
      expect(
        tester.getRect(find.byKey(const Key('amount-key-0'))).bottom,
        lessThan(nextRect.top),
      );
      expect(
        tester.getRect(find.byKey(const Key('amount-key-00'))).bottom,
        lessThan(nextRect.top),
      );
      expect(
        tester.getRect(find.byKey(const Key('amount-delete'))).bottom,
        lessThan(nextRect.top),
      );
      // The button remains tappable, and the next stage is also protected.
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('보내기'), findsOneWidget);
      expect(
        tester.getRect(next).bottom,
        lessThanOrEqualTo(config.size.height - bottomInset),
      );
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transfer-pin-keypad')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('transfer-pin-keypad'))).bottom,
        lessThanOrEqualTo(config.size.height - bottomInset),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('iOS transfer amount retains its existing canvas layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(589, 1280);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      _host(const Size(589, 1280), TargetPlatform.iOS, navigation: 34),
    );
    await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
    await tester.pump();
    expect(tester.getRect(find.byKey(const Key('transfer-next'))).bottom, 1260);
  });
}

Widget _host(
  Size size,
  TargetPlatform platform, {
  double navigation = 0,
  double gesture = 0,
}) {
  return MaterialApp(
    theme: ThemeData(platform: platform),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        viewPadding: EdgeInsets.only(bottom: navigation),
        systemGestureInsets: EdgeInsets.only(bottom: gesture),
      ),
      child: TransferRecipientScreen(dataStore: AppDataStore.inMemory()),
    ),
  );
}

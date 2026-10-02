import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/ui/pin_screen.dart';
import 'package:super_sol/ui/transfer_recipient_screen.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('NotoSansKR')
          ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'))
          ..addFont(rootBundle.load('assets/fonts/NotoSansCJKkr-Bold.otf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final appAccess in [true, false]) {
    testWidgets('approved loading on ${appAccess ? 'app' : 'transfer'} PIN', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(589, 1280);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'NotoSansKR',
            platform: TargetPlatform.iOS,
          ),
          home: appAccess
              ? PinScreen(auth: AuthService())
              : TransferRecipientScreen(
                  dataStore: AppDataStore.inMemory(),
                  initialPinKeys: const [
                    '0',
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                  ],
                ),
        ),
      );
      if (!appAccess) {
        await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('amount-key-1')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('transfer-next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('transfer-next')));
        await tester.pumpAndSettle();
      }
      final prefix = appAccess ? 'app' : 'transfer';
      for (final digit in (appAccess ? '123456' : '1234').split('')) {
        await tester.tap(find.byKey(Key('$prefix-pin-key-$digit')));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(Key('$prefix-pin-loading')), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${prefix}_pin_loading.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

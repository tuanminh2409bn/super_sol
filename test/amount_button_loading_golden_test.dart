import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
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

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('approved amount button loading on ${platform.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(589, 1280);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'NotoSansKR', platform: platform),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(589, 1280),
              viewPadding: EdgeInsets.only(
                bottom: platform == TargetPlatform.android ? 48 : 0,
              ),
            ),
            child: TransferRecipientScreen(dataStore: AppDataStore.inMemory()),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('amount-key-8')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('transfer-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('amount-button-loading')), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/amount_button_loading_${platform.name}.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

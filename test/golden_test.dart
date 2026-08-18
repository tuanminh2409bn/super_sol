import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/ui/account_details_screen.dart';
import 'package:super_sol/ui/home_screen.dart';
import 'package:super_sol/ui/pin_screen.dart';
import 'package:super_sol/ui/splash_screen.dart';
import 'package:super_sol/ui/transfer_recipient_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('NotoSansKR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansCJKkr-Bold.otf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  testWidgets('reference renders at the original mockup canvas', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final auth = _GoldenAuthService();

    await tester.pumpWidget(
      _host(SplashScreen(auth: auth, autoContinue: false)),
    );
    await _precache(tester, const ['assets/images/brand_logo.png']);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/1_splash.png'),
    );

    await tester.pumpWidget(_host(PinScreen(auth: auth)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/2_pin.png'),
    );

    await tester.pumpWidget(
      _host(HomeScreen(key: const ValueKey('home-3.1'), auth: auth)),
    );
    await _precache(tester, const [
      'assets/images/profile_badge.png',
      'assets/images/shinhan_logo.png',
      'assets/images/home_sol_global_card.png',
      'assets/images/coupon_tight.png',
      'assets/images/calendar.png',
      'assets/images/header_chat.png',
      'assets/images/header_wallet.png',
      'assets/images/header_bell.png',
      'assets/images/header_search.png',
      'assets/images/tesla.png',
      'assets/images/point_circle.png',
      'assets/images/service_family.png',
      'assets/images/service_salary.png',
      'assets/images/service_card.png',
      'assets/images/group_card.png',
      'assets/images/group_invest.png',
      'assets/images/group_life.png',
      'assets/images/bottom_nav_clean.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/3_1_home.png'),
    );

    await tester.pumpWidget(
      _host(
        HomeScreen(
          key: const ValueKey('home-3.2'),
          auth: auth,
          initialScrollOffset: 941,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/3_2_services.png'),
    );

    await tester.pumpWidget(
      _host(
        HomeScreen(
          key: const ValueKey('home-3.3'),
          auth: auth,
          initialScrollOffset: 1108,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/3_3_services_scrolled.png'),
    );

    await tester.pumpWidget(
      _host(
        AccountDetailsScreen(key: const ValueKey('account-4.1'), auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/4_1_account.png'),
    );

    await tester.pumpWidget(
      _host(
        AccountDetailsScreen(
          key: const ValueKey('account-4.2'),
          auth: auth,
          initialScrollOffset: 370,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/4_2_account_scrolled.png'),
    );

    await tester.pumpWidget(_host(TransferRecipientScreen()));
    await _precache(tester, const [
      'assets/images/recipient_woori_mock.png',
      'assets/images/recipient_toss_mock.png',
      'assets/images/recipient_hana_mock.png',
      'assets/images/recipient_shinhan_mock.png',
      'assets/images/recipient_jeonbuk_mock.png',
      'assets/images/recipient_kb_mock.png',
      'assets/images/recipient_saemaul_mock.png',
      'assets/images/recipient_toss2_mock.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/5_transfer_recipients.png'),
    );

    await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/9_transfer_saved_recipient.png'),
    );
    await tester.tap(find.byKey(const Key('source-account-selector')));
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/12_source_account_selector.png'),
    );
    await tester.tap(find.byKey(const Key('source-account-sheet-close')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-back')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('transfer-my-accounts-toggle')));
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/5_transfer_my_account.png'),
    );
    await tester.tap(find.byKey(const Key('transfer-my-accounts-toggle')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/10_manual_entry_empty.png'),
    );
    for (final digit in ['1', '0', '0', '2']) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await _precache(tester, const ['assets/images/bank_woori_transparent.png']);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/10_account_suggestions.png'),
    );
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
      'assets/images/bank_kb_transparent.png',
      'assets/images/bank_ibk_transparent.png',
      'assets/images/bank_nh_transparent.png',
      'assets/images/bank_kdb_transparent.png',
      'assets/images/bank_suhyup_transparent.png',
      'assets/images/bank_shinhyup_transparent.png',
      'assets/images/bank_woori_transparent.png',
      'assets/images/bank_hana_transparent.png',
      'assets/images/bank_citi_transparent.png',
      'assets/images/bank_kakao_transparent.png',
      'assets/images/bank_kbank_transparent.png',
      'assets/images/bank_toss_transparent.png',
      'assets/images/bank_kyongnam_transparent.png',
      'assets/images/bank_gwangju_transparent.png',
      'assets/images/bank_im_transparent.png',
      'assets/images/bank_busan_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/8_bank_selector.png'),
    );
    await tester.tap(find.byKey(const Key('bank-tab-증권사')));
    await _precache(tester, const [
      'assets/images/security_shinhan.png',
      'assets/images/security_kyobo.png',
      'assets/images/security_daol.png',
      'assets/images/security_daishin.png',
      'assets/images/security_mirae_asset.png',
      'assets/images/security_samsung.png',
      'assets/images/security_sangsangin.png',
      'assets/images/security_shinyoung.png',
      'assets/images/security_yuanta.png',
      'assets/images/security_kakao_pay.png',
      'assets/images/security_cape.png',
      'assets/images/security_kiwoom.png',
      'assets/images/security_toss.png',
      'assets/images/security_hana.png',
      'assets/images/security_korea_investment.png',
      'assets/images/security_hanwha.png',
      'assets/images/security_hyundai_motor.png',
      'assets/images/security_db_financial.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/8_2_securities_selector.png'),
    );
    await tester.tap(find.byKey(const Key('bank-tab-은행')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-신한')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/11_transfer_error.png'),
    );
  });

  testWidgets('transfer review matches the named-recipient reference', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: false);
    addTearDown(store.dispose);
    await store.saveAccount(
      BankAccount(
        id: 'golden-source-account',
        bankCode: '신한',
        bankDisplayName: '신한',
        ownerName: 'TRINHTRUNGMINH',
        accountNumber: '110-628-103680',
        accountType: '[금융거래한도계좌2]저축예금',
        openingBalance: 388489,
        createdAt: DateTime(2026, 7, 22),
      ),
    );
    await store.saveRecipient(
      const SavedRecipient(
        id: 'golden-recipient',
        displayName: '조승도',
        bankCode: '하나',
        accountNumber: '65491013364107',
      ),
    );

    await tester.pumpWidget(
      _host(
        TransferRecipientScreen(
          dataStore: store,
          initialPinKeys: const [
            '3',
            '2',
            '7',
            '5',
            '6',
            '8',
            '9',
            '1',
            '0',
            '4',
          ],
        ),
      ),
    );
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
      'assets/images/bank_hana_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipient-조승도')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/13_transfer_review.png'),
    );

    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/14_transfer_pin.png'),
    );
  });

  testWidgets('long source account name matches the ellipsized reference', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: false);
    addTearDown(store.dispose);
    await store.saveAccount(
      BankAccount(
        id: 'golden-long-source-account',
        bankCode: '신한',
        bankDisplayName: '신한',
        ownerName: 'TRINHTRUNGMINH',
        accountNumber: '110602923598',
        accountType: '[금융거래한도계좌2]신한 주거래 우대통장(저축예금)',
        openingBalance: 6809,
        createdAt: DateTime(2026, 8, 18),
      ),
    );
    await store.saveRecipient(
      const SavedRecipient(
        id: 'golden-long-source-recipient',
        displayName: 'HO THI BAO',
        bankCode: '국민',
        accountNumber: '85300100157042',
      ),
    );
    await tester.pumpWidget(_host(TransferRecipientScreen(dataStore: store)));
    await _precache(tester, const [
      'assets/images/bank_shinhan_transparent.png',
      'assets/images/bank_kb_transparent.png',
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipient-HO THI BAO')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/16_long_source_account.png'),
    );
  });

  testWidgets('home transfer failure popup matches the original reference', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final auth = _GoldenAuthService();
    await tester.pumpWidget(_host(HomeScreen(auth: auth)));
    await _precache(tester, const [
      'assets/images/profile_badge.png',
      'assets/images/shinhan_logo.png',
      'assets/images/home_sol_global_card.png',
      'assets/images/coupon_tight.png',
      'assets/images/calendar.png',
      'assets/images/header_chat.png',
      'assets/images/header_wallet.png',
      'assets/images/header_bell.png',
      'assets/images/header_search.png',
      'assets/images/tesla.png',
      'assets/images/point_circle.png',
      'assets/images/bottom_nav_clean.png',
    ]);
    await tester.pumpAndSettle();

    showTransferFailurePopup(tester.element(find.byType(HomeScreen)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/15_transfer_failure_home.png'),
    );
  });
}

class _GoldenAuthService extends AuthService {
  @override
  String? get currentEmail => 'test@gmail.com';

  @override
  String get displayName => 'TRINHTRUNGMINH';
}

Future<void> _precache(WidgetTester tester, List<String> assets) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in assets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pump();
}

Widget _host(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      fontFamilyFallback: const [
        'Apple SD Gothic Neo',
        'Noto Sans KR',
        'Noto Sans',
        'Roboto',
      ],
    ),
    home: home,
  );
}

void _configureMockupViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(589, 1280);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

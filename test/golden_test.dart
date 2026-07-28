import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      'assets/images/card_usage.png',
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

    await tester.pumpWidget(_host(const TransferRecipientScreen()));
    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-key-1')));
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
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
}

class _GoldenAuthService extends AuthService {
  @override
  String? get currentEmail => 'test@gmail.com';
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

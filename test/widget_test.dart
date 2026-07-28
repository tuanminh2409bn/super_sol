import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/main.dart';
import 'package:super_sol/ui/account_details_screen.dart';
import 'package:super_sol/ui/auth_sheet.dart';
import 'package:super_sol/ui/home_screen.dart';
import 'package:super_sol/ui/pin_screen.dart';
import 'package:super_sol/ui/transfer_recipient_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash screen matches the first app state', (tester) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(SuperSolApp(auth: AuthService()));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('12:17'), findsNothing);
  });

  testWidgets('six PIN taps open the home screen', (tester) async {
    _configureMockupViewport(tester);
    final auth = AuthService();
    await tester.pumpWidget(_TestHost(home: PinScreen(auth: auth)));

    for (final digit in ['8', '9', '7', '1', '5', '0']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('자산'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });

  testWidgets('PIN back opens the login-method picker when there is no route', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(_TestHost(home: PinScreen(auth: AuthService())));

    await tester.tap(find.byKey(const Key('pin-back')));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
  });

  testWidgets('home scrolls continuously through states 3.2 and 3.3', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(home: HomeScreen(auth: _SignedInAuthService())),
    );

    expect(find.text('TRINHTRUNGMINH님'), findsOneWidget);
    expect(find.text('test@gmail.com'), findsNothing);
    final accountNameFinder = find.byKey(const Key('home-account-name'));
    final accountNameWidget = tester.widget<Text>(accountNameFinder);
    final accountNameContext = tester.element(accountNameFinder);
    final accountNamePainter = TextPainter(
      text: TextSpan(
        text: accountNameWidget.data,
        style: DefaultTextStyle.of(
          accountNameContext,
        ).style.merge(accountNameWidget.style),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(accountNameContext),
    )..layout();
    expect(accountNameWidget.style?.fontSize, 20.5);
    expect(
      accountNamePainter.width,
      lessThanOrEqualTo(tester.getSize(accountNameFinder).width),
    );
    final benefitTitle = tester.getRect(find.text('땡겨요'));
    final benefitSubtitle = tester.getRect(find.text('할인 쿠폰 드려요'));
    expect(benefitSubtitle.top, greaterThan(benefitTitle.bottom));

    // The icon button is the deterministic switch path used by the UI.
    await tester.tap(find.byKey(const Key('home-switch')));
    await tester.pumpAndSettle();
    expect(find.text('추천서비스'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -168),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-switch')), findsNothing);
  });

  testWidgets('successful authentication closes a sheet without a Scaffold', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final auth = _SuccessfulAuthService();
    var authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => GestureDetector(
            key: const Key('open-auth'),
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              authenticated = await showAuthSheet(context, auth: auth);
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-auth')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'test@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Mật khẩu'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the logout button at the end of Home signs out', (tester) async {
    _configureMockupViewport(tester);
    final auth = _SignedInAuthService();
    await tester.pumpWidget(
      _TestHost(home: HomeScreen(auth: auth, initialScrollOffset: 1260)),
    );

    expect(find.byKey(const Key('home-logout')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-logout')));
    await tester.pumpAndSettle();

    expect(auth.signedOut, isTrue);
    expect(find.byType(PinScreen), findsOneWidget);
  });

  testWidgets('a hidden gesture area does not lift the bottom menu', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(589, 1280),
            systemGestureInsets: EdgeInsets.only(bottom: 30),
          ),
          child: HomeScreen(auth: _SignedInAuthService()),
        ),
      ),
    );

    final menuTop = tester
        .getTopLeft(find.byKey(const Key('home-bottom-navigation')))
        .dy;
    expect(menuTop, 1147);
  });

  testWidgets('a visible system navigation area lifts the bottom menu', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(589, 1280),
            viewPadding: EdgeInsets.only(bottom: 30),
          ),
          child: HomeScreen(auth: _SignedInAuthService()),
        ),
      ),
    );

    final menuTop = tester
        .getTopLeft(find.byKey(const Key('home-bottom-navigation')))
        .dy;
    expect(menuTop, lessThan(1147));
  });

  testWidgets('the first Home card opens account details and both exits work', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final auth = _SignedInAuthService();
    await tester.pumpWidget(_TestHost(home: HomeScreen(auth: auth)));

    await tester.tap(find.byKey(const Key('home-account-card')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountDetailsScreen), findsOneWidget);
    expect(find.text('TRINHTRUNGMINH'), findsWidgets);
    expect(find.text('test@gmail.com'), findsNothing);

    await tester.tap(find.byKey(const Key('account-home')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-account-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-back')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the account-history transfer button opens the transfer flow', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(home: AccountDetailsScreen(auth: _SignedInAuthService())),
    );

    await tester.tap(find.byKey(const Key('account-transfer')));
    await tester.pumpAndSettle();
    expect(find.byType(TransferRecipientScreen), findsOneWidget);
  });

  testWidgets('transfer recipient entry selects a bank and enables next', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(home: HomeScreen(auth: _SignedInAuthService())),
    );

    await tester.tap(find.byKey(const Key('home-transfer')));
    await tester.pumpAndSettle();
    expect(find.byType(TransferRecipientScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    for (final digit in '100237698805'.split('')) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-selector-list')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('bank-selector-list')),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bank-토스뱅크')));
    await tester.pumpAndSettle();
    expect(find.text('토스뱅크'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    expect(find.text('얼마를 보낼까요?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNull,
    );
    final lastKeyRow = tester.getRect(find.byKey(const Key('amount-key-00')));
    final keypadViewport = tester.getRect(find.byType(GridView));
    final nextButton = tester.getRect(find.byKey(const Key('transfer-next')));
    expect(lastKeyRow.bottom, lessThanOrEqualTo(keypadViewport.bottom));
    expect(nextButton.top, greaterThan(lastKeyRow.bottom));
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    expect(find.text('1원'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('amount-key-00')));
    await tester.pump();
    expect(find.text('100원'), findsNWidgets(2));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    expect(find.text('EEF90723'), findsOneWidget);
    expect(find.text('해당 계좌는 사고신고계좌로 거래가 불가합니다.'), findsOneWidget);
    expect(find.text('아래 계좌로\n100원 보낼까요?'), findsOneWidget);
    expect(find.text('수수료 무료'), findsOneWidget);
    expect(find.text('보내기'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('transfer-error-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('EEF90723'), findsNothing);
    expect(find.text('누구에게 보낼까요?'), findsOneWidget);
  });
}

void _configureMockupViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(589, 1280);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _TestHost extends StatelessWidget {
  const _TestHost({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
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
}

class _SuccessfulAuthService extends AuthService {
  @override
  bool get firebaseReady => true;

  @override
  Future<AuthResult> authenticate({
    required AuthMode mode,
    required String email,
    required String password,
  }) async {
    return const AuthResult(ok: true, message: 'Thành công.');
  }
}

class _SignedInAuthService extends AuthService {
  bool signedOut = false;

  @override
  String? get currentEmail => signedOut ? null : 'test@gmail.com';

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

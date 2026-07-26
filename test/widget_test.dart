import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/main.dart';
import 'package:super_sol/ui/account_details_screen.dart';
import 'package:super_sol/ui/auth_sheet.dart';
import 'package:super_sol/ui/home_screen.dart';
import 'package:super_sol/ui/pin_screen.dart';

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

  testWidgets('home scrolls continuously through states 3.2 and 3.3', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(home: HomeScreen(auth: _SignedInAuthService())),
    );

    expect(find.text('TRINHTRUNGMINH님'), findsOneWidget);
    expect(find.text('test@gmail.com'), findsNothing);

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

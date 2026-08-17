import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/main.dart';
import 'package:super_sol/ui/account_details_screen.dart';
import 'package:super_sol/ui/auth_sheet.dart';
import 'package:super_sol/ui/bank_logo.dart';
import 'package:super_sol/ui/data_management_screen.dart';
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
    final accountNameSpan = accountNameWidget.textSpan! as TextSpan;
    final accountNameParts = accountNameSpan.children!.cast<TextSpan>();
    final accountNamePainter = TextPainter(
      text: TextSpan(
        children: accountNameSpan.children,
        style: DefaultTextStyle.of(
          accountNameContext,
        ).style.merge(accountNameWidget.style),
      ),
      maxLines: accountNameWidget.maxLines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(accountNameContext),
    )..layout(maxWidth: tester.getSize(accountNameFinder).width);
    expect(accountNameWidget.style?.fontSize, 23);
    expect(accountNameParts[0].text, 'TRINHTRUNGMINH');
    expect(accountNameParts[0].style?.fontWeight, FontWeight.w500);
    expect(accountNameParts[1].text, '님');
    expect(accountNameParts[1].style?.fontWeight, FontWeight.w400);
    expect(accountNamePainter.didExceedMaxLines, isFalse);
    expect(
      tester.getSize(find.byKey(const Key('home-account-logo'))),
      const Size.square(44),
    );
    final accountType = tester.widget<Text>(
      find.byKey(const Key('home-account-type')),
    );
    expect(accountType.style?.color, const Color(0xFF505866));
    expect(accountType.style?.fontWeight, FontWeight.w500);
    expect(accountType.style?.fontVariations, const [
      FontVariation('wght', 500),
    ]);
    final homeSecondaryLabels = <Text>[
      tester.widget(find.byKey(const Key('home-card-usage-value'))),
      tester.widget(find.byKey(const Key('home-benefit-subtitle'))),
      tester.widget(find.byKey(const Key('home-spending-subtitle'))),
      for (final label in ['금융', '상품', '혜택', '주식'])
        tester.widget(find.byKey(Key('home-bottom-label-$label'))),
    ];
    for (final secondaryText in homeSecondaryLabels) {
      expect(secondaryText.style?.color, const Color(0xFF505866));
      expect(secondaryText.style?.fontWeight, FontWeight.w500);
      expect(secondaryText.style?.fontVariations, const [
        FontVariation('wght', 500),
      ]);
    }
    final accountBalance = tester.widget<Text>(
      find.byKey(const Key('home-account-balance')),
    );
    expect(accountBalance.style?.fontWeight, FontWeight.w500);
    expect(
      tester.getTopLeft(find.byKey(const Key('home-account-balance'))).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const Key('home-account-type'))).dy,
      ),
    );
    final benefitTitle = tester.getRect(find.text('땡겨요'));
    final benefitSubtitle = tester.getRect(find.text('할인 쿠폰 드려요'));
    final benefitOffer = tester.getRect(find.text('bhc치킨 최대 9,000원'));
    expect(benefitSubtitle.top - benefitTitle.bottom, greaterThanOrEqualTo(13));
    expect(benefitOffer.top - benefitSubtitle.bottom, greaterThanOrEqualTo(4));

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

  testWidgets('long home account name wraps fully before the header icons', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(
          auth: _SignedInAuthService(name: 'NGUYEN HUYNH XUAN MAI'),
        ),
      ),
    );

    final nameFinder = find.byKey(const Key('home-account-name'));
    final nameWidget = tester.widget<Text>(nameFinder);
    final nameContext = tester.element(nameFinder);
    final nameSpan = nameWidget.textSpan! as TextSpan;
    final namePainter = TextPainter(
      text: TextSpan(
        children: nameSpan.children,
        style: DefaultTextStyle.of(nameContext).style.merge(nameWidget.style),
      ),
      maxLines: nameWidget.maxLines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(nameContext),
    )..layout(maxWidth: tester.getSize(nameFinder).width);

    expect(find.text('NGUYEN HUYNH XUAN MAI님'), findsOneWidget);
    expect(nameWidget.maxLines, 2);
    expect(nameWidget.overflow, TextOverflow.clip);
    expect(namePainter.computeLineMetrics(), hasLength(2));
    expect(namePainter.didExceedMaxLines, isFalse);
    expect(
      namePainter.height,
      lessThanOrEqualTo(tester.getSize(nameFinder).height),
    );
    final firstLine = namePainter.getLineBoundary(
      const TextPosition(offset: 0),
    );
    expect(
      nameSpan.toPlainText().substring(firstLine.start, firstLine.end).trim(),
      'NGUYEN HUYNH',
    );
    expect(
      tester.getTopRight(nameFinder).dx,
      lessThan(
        tester
            .getTopLeft(
              find.image(const AssetImage('assets/images/header_chat.png')),
            )
            .dx,
      ),
    );
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

  testWidgets('registration requires and sends the display name', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final auth = _RegisteringAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => GestureDetector(
            key: const Key('open-register-auth'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showAuthSheet(context, auth: auth),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-register-auth')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('register-display-name')),
      'TÊN TÀI KHOẢN MỚI',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Mật khẩu'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    expect(auth.registeredDisplayName, 'TÊN TÀI KHOẢN MỚI');
  });

  testWidgets('a new account home is empty and uses its registered name', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final store = AppDataStore();
    await store.initialize('brand-new-user');
    final auth = _SignedInAuthService(name: 'TÊN TÀI KHOẢN MỚI');

    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(auth: auth, dataStore: store),
      ),
    );

    expect(find.text('TÊN TÀI KHOẢN MỚI님'), findsOneWidget);
    expect(find.text('등록된 계좌가 없습니다'), findsOneWidget);
    expect(find.text('0원'), findsNWidgets(2));
    expect(
      find.text('TÊN TÀI KHOẢN MỚI님의 금융생활, 슈퍼SOL이 함께합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('home card usage can be edited and remains in the store', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: true);
    final auth = _SignedInAuthService();

    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(auth: auth, dataStore: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('8월 이용 금액 6,500원'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-card-usage-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('home-card-month-field')), '9');
    await tester.enterText(
      find.byKey(const Key('home-card-amount-field')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('home-card-usage-save')));
    await tester.pumpAndSettle();

    expect(find.text('9월 이용 금액 123,456원'), findsOneWidget);
    expect(store.homeCardMonth, 9);
    expect(store.homeCardAmount, 123456);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(auth: auth, dataStore: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('9월 이용 금액 123,456원'), findsOneWidget);
  });

  testWidgets('the logout button at the end of Home signs out', (tester) async {
    _configureMockupViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final auth = _SignedInAuthService();
    final store = AppDataStore.inMemory(withMockData: true);
    final signedInAccountId = store.accounts.first.id;
    await store.createTransaction(
      accountId: signedInAccountId,
      title: 'SIGNED-IN-ONLY',
      signedAmount: 777,
      occurredAt: DateTime(2026, 7, 30, 12, 34, 56),
      channel: '모바일',
    );
    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(
          auth: auth,
          initialScrollOffset: 1260,
          dataStore: store,
        ),
      ),
    );

    expect(find.byKey(const Key('home-logout')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-logout')));
    await tester.pumpAndSettle();

    expect(auth.signedOut, isTrue);
    expect(find.byType(PinScreen), findsOneWidget);
    expect(store.accounts, isEmpty);
  });

  testWidgets('a system gesture area lifts the bottom menu', (tester) async {
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
    expect(menuTop, 1118);
    expect(
      tester.getSize(find.byKey(const Key('home-bottom-navigation'))),
      const Size(535, 90),
    );
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
    expect(menuTop, 1118);
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
    expect(find.byKey(const Key('account-home-glyph')), findsOneWidget);
    expect(find.byKey(const Key('account-scan-icon')), findsOneWidget);
    expect(find.byKey(const Key('account-copy-glyph')), findsOneWidget);
    expect(find.text('계좌관리'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('account-details-logo'))),
      const Size.square(52),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('account-type-text'))),
      const Offset(90, 243),
    );
    final accountNumberRect = tester.getRect(
      find.byKey(const Key('account-number-text')),
    );
    final copyRect = tester.getRect(
      find.byKey(const Key('account-copy-glyph')),
    );
    expect(copyRect.size, const Size.square(15));
    expect(copyRect.left - accountNumberRect.right, closeTo(5, .1));
    expect(copyRect.center.dy, closeTo(accountNumberRect.center.dy, .1));
    final balanceText = tester.widget<Text>(
      find.byKey(const Key('account-balance-text')),
    );
    final availableBalanceText = tester.widget<Text>(
      find.byKey(const Key('account-available-balance-text')),
    );
    expect(balanceText.style?.fontWeight, FontWeight.w600);
    expect(availableBalanceText.style?.color, const Color(0xFF505866));
    expect(availableBalanceText.style?.fontWeight, FontWeight.w500);
    expect(availableBalanceText.style?.fontVariations, const [
      FontVariation('wght', 500),
    ]);
    final accountNumberText = tester.widget<Text>(
      find.byKey(const Key('account-number-text')),
    );
    expect(accountNumberText.style?.fontWeight, FontWeight.w500);
    expect(accountNumberText.style?.fontVariations, const [
      FontVariation('wght', 500),
    ]);
    final transactionDate = tester.widget<Text>(
      find.byKey(const Key('account-transaction-date-2026-7-22')),
    );
    final transactionTime = tester.widget<Text>(
      find.byKey(const Key('account-transaction-time-seed-transaction-0')),
    );
    final transactionBalance = tester.widget<Text>(
      find.byKey(const Key('account-transaction-balance-seed-transaction-0')),
    );
    for (final secondaryText in [transactionDate, transactionTime]) {
      expect(secondaryText.style?.color, const Color(0xFF505866));
      expect(secondaryText.style?.fontWeight, FontWeight.w500);
      expect(secondaryText.style?.fontVariations, const [
        FontVariation('wght', 500),
      ]);
    }
    expect(transactionBalance.style?.color, const Color(0xFF505866));
    expect(transactionBalance.style?.fontWeight, FontWeight.w500);
    expect(transactionBalance.style?.fontVariations, const [
      FontVariation('wght', 500),
    ]);
    expect(
      tester.getTopLeft(find.byKey(const Key('account-balance-text'))).dy,
      330,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('account-available-balance-text')))
          .dy,
      381,
    );

    String? copiedAccountNumber;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedAccountNumber =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.byKey(const Key('account-copy')));
    await tester.pump();
    expect(copiedAccountNumber, '110-628-103680');
    final homeIconCenter = tester.getCenter(
      find.byKey(const Key('account-home-glyph')),
    );
    final scanIconCenter = tester.getCenter(
      find.byKey(const Key('account-scan-icon')),
    );
    expect(homeIconCenter.dx, closeTo(scanIconCenter.dx, 1));

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

  testWidgets(
    'a long account type wraps clear of icons and following account details',
    (tester) async {
      _configureMockupViewport(tester);
      final store = AppDataStore.inMemory(withMockData: false);
      addTearDown(store.dispose);
      await store.saveAccount(
        BankAccount(
          id: 'long-account-type',
          bankCode: '신한',
          bankDisplayName: '신한',
          ownerName: 'TRINHTRUNGMINH',
          accountNumber: '110602923598',
          accountType: '[금융거래한도계좌2]신한 주거래 우대통장(저축예금)',
          openingBalance: 10000,
          createdAt: DateTime(2026, 8, 17),
        ),
      );

      await tester.pumpWidget(
        _TestHost(
          home: AccountDetailsScreen(
            auth: _SignedInAuthService(),
            dataStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final accountTypeFinder = find.byKey(const Key('account-type-text'));
      final accountTypeRect = tester.getRect(accountTypeFinder);
      final accountNumberRect = tester.getRect(
        find.byKey(const Key('account-number-text')),
      );
      final scanIconRect = tester.getRect(
        find.byKey(const Key('account-scan-icon')),
      );
      final balanceRect = tester.getRect(
        find.byKey(const Key('account-balance-text')),
      );
      final accountType = tester.widget<Text>(accountTypeFinder);
      final accountTypeContext = tester.element(accountTypeFinder);
      final accountTypePainter = TextPainter(
        text: TextSpan(
          text: accountType.data,
          style: DefaultTextStyle.of(
            accountTypeContext,
          ).style.merge(accountType.style),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(accountTypeContext),
      )..layout(maxWidth: accountTypeRect.width);

      expect(accountTypePainter.computeLineMetrics(), hasLength(2));
      expect(accountTypeRect.right, lessThan(scanIconRect.left));
      expect(accountTypeRect.bottom, lessThan(accountNumberRect.top));
      expect(accountNumberRect.bottom, lessThan(balanceRect.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all transactions across many days can scroll into view', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: false);
    addTearDown(store.dispose);
    final account = await store.saveAccount(
      BankAccount(
        id: 'multi-day-history',
        bankCode: '신한',
        bankDisplayName: '신한',
        ownerName: 'TRINHTRUNGMINH',
        accountNumber: '110602923598',
        accountType: '저축예금',
        openingBalance: 100000,
        createdAt: DateTime(2026, 8, 17),
      ),
    );
    final transactionIds = <String>[];
    for (var index = 0; index < 12; index++) {
      final transaction = await store.createTransaction(
        accountId: account.id,
        title: 'TX-$index',
        signedAmount: 100,
        occurredAt: DateTime(2026, 8, 17).subtract(Duration(days: index)),
        channel: '모바일',
      );
      transactionIds.add(transaction.id);
    }

    await tester.pumpWidget(
      _TestHost(
        home: AccountDetailsScreen(
          auth: _SignedInAuthService(),
          dataStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final transactionId in transactionIds) {
      expect(
        find.byKey(Key('account-transaction-time-$transactionId')),
        findsOneWidget,
      );
    }
    await tester.drag(
      find.byKey(const Key('account-details-scroll')),
      const Offset(0, -10000),
    );
    await tester.pumpAndSettle();

    final oldestTransactionRect = tester.getRect(find.text('TX-0'));
    expect(oldestTransactionRect.top, greaterThanOrEqualTo(0));
    expect(oldestTransactionRect.bottom, lessThan(1164));
    expect(
      find.byKey(const Key('account-transaction-date-2026-8-6')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
    expect(find.byKey(const Key('transfer-multiple')), findsOneWidget);
    expect(find.byKey(const Key('transfer-quick-recipient')), findsOneWidget);
    expect(find.byKey(const Key('transfer-favorite-label')), findsOneWidget);
    expect(find.byKey(const Key('transfer-favorite-edit')), findsOneWidget);
    expect(find.byKey(const Key('transfer-favorite-toggle')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('transfer-favorite-label'))),
      const Offset(28, 387),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('transfer-own-account-label'))),
      const Offset(28, 461),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('transfer-recent-label'))),
      const Offset(28, 535),
    );
    final manualEntryLabel = tester.widget<Text>(find.text('계좌번호 직접 입력'));
    expect(manualEntryLabel.style?.color, const Color(0xFF8A93A4));
    expect(manualEntryLabel.style?.fontVariations?.single.axis, 'wght');
    expect(manualEntryLabel.style?.fontVariations?.single.value, 470);
    final recentCountText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('transfer-recent-recipients-toggle')),
        matching: find.byType(Text),
      ),
    );
    expect(recentCountText.style?.color, const Color(0xFF303846));
    expect(recentCountText.style?.fontWeight, FontWeight.w500);

    await tester.tap(find.byKey(const Key('transfer-my-accounts-toggle')));
    await tester.pump();
    expect(find.text('1개'), findsOneWidget);
    expect(find.text('[금융거래한도계좌2]저축예금'), findsOneWidget);
    expect(find.text('신한 110-628-103680'), findsOneWidget);

    await tester.tap(find.byKey(const Key('recipient-[금융거래한도계좌2]저축예금')));
    await tester.pump();
    expect(find.text('[금융거래한도계좌2]저축예금 계좌로'), findsOneWidget);
    await tester.tap(find.byKey(const Key('source-account-selector')));
    await tester.pump();
    expect(find.byKey(const Key('source-account-sheet')), findsOneWidget);
    expect(find.text('출금계좌 선택'), findsOneWidget);
    expect(find.text('[금융거래한도계좌2]저축예금'), findsOneWidget);
    expect(find.text('신한 110-628-103680'), findsNWidgets(2));
    final sourceOption = find.byKey(
      const Key('source-account-option-신한-110-628-103680'),
    );
    expect(sourceOption, findsOneWidget);
    final sourceLogo = tester.widget<Image>(
      find.descendant(of: sourceOption, matching: find.byType(Image)),
    );
    expect(
      (sourceLogo.image as AssetImage).assetName,
      'assets/images/bank_shinhan_transparent.png',
    );
    expect(
      find.byKey(const Key('source-account-balance-신한-110-628-103680')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('source-account-sheet-close')));
    await tester.pump();
    expect(find.byKey(const Key('source-account-sheet')), findsNothing);

    await tester.tap(find.byKey(const Key('transfer-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-my-accounts-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    expect(find.byKey(const Key('transfer-back')), findsOneWidget);
    expect(find.byKey(const Key('transfer-home')), findsOneWidget);
    expect(find.byKey(const Key('transfer-multiple')), findsNothing);
    for (final digit in '100237698805'.split('')) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-selector-list-banks')), findsOneWidget);
    final bankTileRect = tester.getRect(find.byKey(const Key('bank-신한')));
    final bankLogoFrameSize = tester.getSize(
      find.byKey(const Key('bank-logo-frame-신한')),
    );
    await tester.tap(find.byKey(const Key('bank-tab-증권사')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-신한투자증권')), findsOneWidget);
    expect(find.byKey(const Key('bank-교보증권')), findsOneWidget);
    final securitiesTileRect = tester.getRect(
      find.byKey(const Key('bank-신한투자증권')),
    );
    final securitiesLogoFrameSize = tester.getSize(
      find.byKey(const Key('bank-logo-frame-신한투자증권')),
    );
    expect(securitiesTileRect, bankTileRect);
    expect(bankTileRect.height, 134);
    expect(securitiesLogoFrameSize, bankLogoFrameSize);
    expect(securitiesLogoFrameSize, const Size.square(BankLogoSize.picker));
    final shinhanSecurityTile = find.byKey(const Key('bank-신한투자증권'));
    final shinhanSecurityLogo = tester.widget<Image>(
      find.descendant(of: shinhanSecurityTile, matching: find.byType(Image)),
    );
    expect(
      (shinhanSecurityLogo.image as AssetImage).assetName,
      'assets/images/security_shinhan.png',
    );
    await tester.drag(
      find.byKey(const Key('bank-selector-list-securities')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.byKey(const Key('bank-DB금융투자')), findsOneWidget);
    final dbSecurityTile = find.byKey(const Key('bank-DB금융투자'));
    final dbSecurityLogo = tester.widget<Image>(
      find.descendant(of: dbSecurityTile, matching: find.byType(Image)),
    );
    expect(
      (dbSecurityLogo.image as AssetImage).assetName,
      'assets/images/security_db_financial.png',
    );
    await tester.tap(find.byKey(const Key('bank-tab-은행')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('bank-selector-list-banks')),
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
    expect(find.text('1원'), findsOneWidget);
    expect(find.byKey(const Key('amount-available-balance')), findsOneWidget);
    final amountRecipientAccount = tester.widget<Text>(
      find.byKey(const Key('amount-recipient-account')),
    );
    final amountAvailableBalance = tester.widget<Text>(
      find.byKey(const Key('amount-available-balance')),
    );
    final amountAvailableSpan = amountAvailableBalance.textSpan! as TextSpan;
    final amountAvailableValueSpan =
        amountAvailableSpan.children!.last as TextSpan;
    for (final secondaryStyle in [
      amountRecipientAccount.style!,
      amountAvailableSpan.style!,
      amountAvailableValueSpan.style!,
    ]) {
      expect(secondaryStyle.color, const Color(0xFF505866));
      expect(secondaryStyle.fontWeight, FontWeight.w500);
      expect(secondaryStyle.fontVariations, const [FontVariation('wght', 500)]);
    }
    await tester.tap(find.byKey(const Key('amount-key-00')));
    await tester.pump();
    expect(find.text('100원'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    expect(find.text('아래 계좌로\n100원 보낼까요?'), findsOneWidget);
    expect(find.text('수수료 무료'), findsOneWidget);
    expect(find.text('보내기'), findsOneWidget);
    expect(find.text('보내는 계좌'), findsOneWidget);
    expect(find.text('받는 계좌'), findsOneWidget);
    expect(find.text('받는분 메모'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('transfer-review-details-toggle')),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      Icons.keyboard_arrow_down_rounded,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('transfer-review-details-toggle')));
    await tester.pump();
    expect(find.text('보내는 계좌'), findsNothing);
    expect(find.text('받는 계좌'), findsNothing);
    expect(find.text('받는분 메모'), findsNothing);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('transfer-review-details-toggle')),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      Icons.keyboard_arrow_up_rounded,
    );

    final balanceBeforeFailure = AppDataStore.shared.balanceFor(
      AppDataStore.shared.accounts.first.id,
    );
    final transactionsBeforeFailure = AppDataStore.shared
        .transactionsFor(AppDataStore.shared.accounts.first.id)
        .map((transaction) => transaction.id)
        .toList();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    expect(find.text('계좌 비밀번호'), findsOneWidget);
    expect(find.byKey(const Key('transfer-pin-keypad')), findsOneWidget);
    expect(find.text('재배열'), findsOneWidget);
    expect(find.byKey(const Key('transfer-back')), findsNothing);

    for (final digit in ['0', '1', '2', '3']) {
      await tester.tap(find.byKey(Key('transfer-pin-key-$digit')));
    }
    await tester.pumpAndSettle();
    expect(find.text('DEP20180'), findsOneWidget);
    expect(find.text('전화금융사고 및 기타금융사고 등록고객은 지급거래'), findsOneWidget);
    expect(find.text('또는 콜센터로 문의해 주시기 바랍니다.'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    final failureCode = tester.widget<Text>(
      find.byKey(const Key('transfer-failure-code')),
    );
    expect(failureCode.style?.color, const Color(0xFFFF5C73));
    expect(failureCode.style?.fontWeight, FontWeight.w500);
    expect(failureCode.style?.fontVariations, const [
      FontVariation('wght', 500),
    ]);
    final failureTexts = <Text>[
      for (final body in [
        '전화금융사고 및 기타금융사고 등록고객은 지급거래',
        '불가합니다. 고객사고 정보 확인후 거래하세요.',
        '고객사고 등록으로 거래가 불가합니다. 신한은행 영업점',
        '또는 콜센터로 문의해 주시기 바랍니다.',
      ])
        tester.widget(find.byKey(Key('transfer-failure-body-$body'))),
    ];
    for (final failureText in failureTexts) {
      expect(failureText.style?.color, const Color(0xFF505866));
      expect(failureText.style?.fontWeight, FontWeight.w500);
      expect(failureText.style?.fontVariations, const [
        FontVariation('wght', 500),
      ]);
    }
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      AppDataStore.shared.balanceFor(AppDataStore.shared.accounts.first.id),
      balanceBeforeFailure,
    );
    expect(
      AppDataStore.shared
          .transactionsFor(AppDataStore.shared.accounts.first.id)
          .map((transaction) => transaction.id),
      transactionsBeforeFailure,
    );
    await tester.tap(find.byKey(const Key('transfer-failure-home-confirm')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'bank and securities selectors keep mockup proportions on Android DPR',
    (tester) async {
      const devicePixelRatio = 1.5;
      tester.view.devicePixelRatio = devicePixelRatio;
      tester.view.physicalSize = const Size(591, 1280);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _TestHost(
          home: TransferRecipientScreen(dataStore: AppDataStore.inMemory()),
        ),
      );
      await tester.tap(find.byKey(const Key('transfer-manual-entry')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('transfer-bank-selector')));
      await tester.pumpAndSettle();

      final bankTileRect = tester.getRect(find.byKey(const Key('bank-신한')));
      final bankLogoRect = tester.getRect(
        find.byKey(const Key('bank-logo-frame-신한')),
      );
      expect(bankTileRect.left * devicePixelRatio, closeTo(28, 0.75));
      expect(
        bankLogoRect.width * devicePixelRatio,
        closeTo(BankLogoSize.picker, 0.75),
      );

      await tester.tap(find.byKey(const Key('bank-tab-증권사')));
      await tester.pumpAndSettle();
      final securityTileRect = tester.getRect(
        find.byKey(const Key('bank-신한투자증권')),
      );
      final securityLogoRect = tester.getRect(
        find.byKey(const Key('bank-logo-frame-신한투자증권')),
      );
      expect(securityTileRect, bankTileRect);
      expect(securityLogoRect.size, bankLogoRect.size);
    },
  );

  testWidgets('a selected securities logo follows the transfer flow', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(
      _TestHost(
        home: TransferRecipientScreen(dataStore: AppDataStore.inMemory()),
      ),
    );

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-key-1')));
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-tab-증권사')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-신한투자증권')));
    await tester.pumpAndSettle();

    expect(find.text('신한투자증권'), findsWidgets);
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();

    final confirmationLogo = tester.widget<Image>(find.byType(Image).last);
    expect(
      (confirmationLogo.image as AssetImage).assetName,
      'assets/images/security_shinhan.png',
    );
  });

  testWidgets('transfer cannot start without an active source account', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    await store.archiveAccount(store.accounts.first.id);
    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );

    await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
    await tester.pumpAndSettle();
    expect(find.text('출금 계좌를 먼저 추가해주세요.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('missing-source-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('누구에게 보낼까요?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-key-1')));
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-신한')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('recipient search and favorite controls update real data', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );

    await tester.tap(
      find.byKey(const Key('recipient-favorite-seed-recipient-0')),
    );
    await tester.pump();
    expect(
      store.recipients
          .singleWhere((item) => item.id == 'seed-recipient-0')
          .favorite,
      isTrue,
    );
    final favoriteStar = tester.widget<Icon>(find.byIcon(Icons.star_rounded));
    expect(favoriteStar.color, const Color(0xFF0969F6));
    final favoriteCountText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('transfer-favorite-toggle')),
        matching: find.byType(Text),
      ),
    );
    expect(favoriteCountText.data, '1개');
    await tester.tap(find.byKey(const Key('transfer-favorite-toggle')));
    await tester.pump();
    expect(
      find.byKey(const Key('favorite-recipient-TRINH TRUN')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('transfer-recipient-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Npay');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipient-search-Npay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipient-search-Npay')));
    await tester.pumpAndSettle();
    expect(find.text('Npay님 계좌로'), findsOneWidget);
    expect(find.textContaining('56020228505759'), findsOneWidget);
  });

  testWidgets('recent recipients show saved entries beyond the first eight', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: false);
    await store.createAccount(
      bankCode: '신한',
      bankDisplayName: '신한',
      ownerName: 'TEST OWNER',
      accountNumber: '110000000000',
      accountType: '입출금',
      openingBalance: 500000,
    );
    for (var index = 0; index < 12; index++) {
      await store.createRecipient(
        displayName: 'Saved recipient $index',
        bankCode: '우리',
        accountNumber: '100000000$index',
      );
    }

    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );
    expect(
      find.byKey(const Key('recipient-Saved recipient 0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('recent-recipient-list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recipient-Saved recipient 11')),
      findsOneWidget,
    );
  });

  testWidgets('camera shortcut enters the manual account flow', (tester) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(_TestHost(home: TransferRecipientScreen()));

    await tester.tap(find.byKey(const Key('transfer-camera')));
    await tester.pump();
    expect(find.byKey(const Key('account-key-1')), findsOneWidget);
    expect(find.byKey(const Key('transfer-bank-selector')), findsOneWidget);
  });

  testWidgets('manual account keypad matches the original spacing and weight', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(_TestHost(home: TransferRecipientScreen()));

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();

    final one = tester.getCenter(find.byKey(const Key('account-key-1')));
    final two = tester.getCenter(find.byKey(const Key('account-key-2')));
    final three = tester.getCenter(find.byKey(const Key('account-key-3')));
    expect(one.dx, closeTo(98.2, .2));
    expect(two.dx, closeTo(294.5, .2));
    expect(three.dx, closeTo(490.8, .2));
    expect(one.dy, closeTo(832.7, .3));
    expect(two.dy, closeTo(one.dy, .1));
    expect(three.dy, closeTo(one.dy, .1));

    final digit = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('account-key-1')),
        matching: find.text('1'),
      ),
    );
    expect(digit.style?.fontSize, 35);
    expect(digit.style?.fontWeight, FontWeight.w400);
    expect(digit.style?.fontVariations?.single.axis, 'wght');
    expect(digit.style?.fontVariations?.single.value, 400);

    final accountLabel = tester.widget<Text>(find.text('계좌번호'));
    expect(accountLabel.style?.fontSize, 17);
    expect(accountLabel.style?.fontWeight, FontWeight.w400);
    final accountHint = tester.widget<Text>(find.text('- 없이 숫자만 입력'));
    expect(accountHint.style?.fontSize, 26);
    expect(find.byKey(const Key('transfer-account-caret')), findsOneWidget);
    final bankHint = tester.widget<Text>(find.text('은행 또는 증권사 선택'));
    expect(bankHint.style?.fontSize, 27);
  });

  testWidgets('bank selection does not show default suggestion chips', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(_TestHost(home: TransferRecipientScreen()));

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-신한')));
    await tester.pumpAndSettle();
    for (final digit in ['1', '0']) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.pump();

    expect(find.byKey(const Key('transfer-account-suggestions')), findsNothing);
    expect(find.text('케이뱅크'), findsNothing);
    expect(find.text('토스뱅크'), findsNothing);
  });

  testWidgets('four account digits show the matching compact suggestion chip', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory(withMockData: false);
    await store.createAccount(
      bankCode: '신한',
      bankDisplayName: '신한',
      ownerName: 'TEST OWNER',
      accountNumber: '110000000000',
      accountType: '입출금',
      openingBalance: 500000,
    );
    final pham = await store.createRecipient(
      displayName: 'PHAM DINH',
      bankCode: '토스뱅크',
      accountNumber: '100191200803',
    );
    final trinh = await store.createRecipient(
      displayName: 'TRINH TRUN',
      bankCode: '우리',
      accountNumber: '1002365702814',
    );

    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );
    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    for (final digit in ['1', '0', '0', '1']) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.pump();

    expect(
      find.byKey(const Key('transfer-account-suggestions')),
      findsOneWidget,
    );
    expect(find.text('PHAM DINH 100191200803'), findsOneWidget);
    expect(find.text('TRINH TRUN 1002365702814'), findsNothing);
    expect(find.text('은행 또는 증권사 선택'), findsOneWidget);
    expect(
      find.byKey(Key('transfer-account-suggestion-${pham.id}')),
      findsOneWidget,
    );
    final bankRect = tester.getRect(
      find.byKey(const Key('transfer-bank-selector')),
    );
    final suggestionRect = tester.getRect(
      find.byKey(const Key('transfer-account-suggestions')),
    );
    expect(suggestionRect.top, greaterThan(bankRect.bottom));
    expect(suggestionRect.height, 44);

    await tester.tap(find.byKey(const Key('transfer-clear-account')));
    await tester.pump();
    for (final digit in ['1', '0', '0', '2']) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.pump();

    expect(find.text('PHAM DINH 100191200803'), findsNothing);
    expect(find.text('TRINH TRUN 1002365702814'), findsOneWidget);
    await tester.tap(
      find.byKey(Key('transfer-account-suggestion-${trinh.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRINH TRUN님 계좌로'), findsOneWidget);
    expect(find.textContaining('1002365702814'), findsOneWidget);
  });

  testWidgets(
    'account suggestions include newly saved accounts and all matching recipients',
    (tester) async {
      _configureMockupViewport(tester);
      final store = AppDataStore.inMemory(withMockData: false);
      await store.createAccount(
        bankCode: '신한',
        bankDisplayName: '신한',
        ownerName: 'SOURCE OWNER',
        accountNumber: '110000000000',
        accountType: '출금계좌',
        openingBalance: 500000,
      );
      final ownAccount = await store.createAccount(
        bankCode: '우리',
        bankDisplayName: '우리',
        ownerName: 'SECOND OWNER',
        accountNumber: '123400000001',
        accountType: '새로 추가한 계좌',
        openingBalance: 300000,
      );
      final first = await store.createRecipient(
        displayName: 'MATCH ONE',
        bankCode: '국민',
        accountNumber: '123400000002',
      );
      final second = await store.createRecipient(
        displayName: 'MATCH TWO',
        bankCode: '하나',
        accountNumber: '123400000003',
      );

      await tester.pumpWidget(
        _TestHost(home: TransferRecipientScreen(dataStore: store)),
      );
      await tester.tap(find.byKey(const Key('transfer-manual-entry')));
      await tester.pump();
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.byKey(Key('account-key-$digit')));
      }
      await tester.pump();

      expect(
        find.byKey(Key('transfer-account-suggestion-${first.id}')),
        findsOneWidget,
      );
      final suggestionList = find.descendant(
        of: find.byKey(const Key('transfer-account-suggestions')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(Key('transfer-account-suggestion-${second.id}')),
        240,
        scrollable: suggestionList,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('transfer-account-suggestion-123400000001')),
        240,
        scrollable: suggestionList,
      );

      await tester.tap(
        find.byKey(const Key('transfer-account-suggestion-123400000001')),
      );
      await tester.pumpAndSettle();
      expect(find.text('새로 추가한 계좌 계좌로'), findsOneWidget);
      expect(find.textContaining(ownAccount.accountNumber), findsOneWidget);
    },
  );

  testWidgets('data management adds accounts and recipients', (tester) async {
    final store = AppDataStore.inMemory();
    await tester.pumpWidget(
      _TestHost(home: DataManagementScreen(store: store)),
    );

    final accountCount = store.accounts.length;
    await tester.tap(find.byKey(const Key('add-account')));
    await tester.pumpAndSettle();
    final accountFields = find.byType(TextFormField);
    expect(accountFields, findsNWidgets(5));
    await tester.enterText(accountFields.at(0), '우리 표시');
    await tester.enterText(accountFields.at(1), 'TEST OWNER');
    await tester.enterText(accountFields.at(2), '100-200-300');
    await tester.enterText(accountFields.at(3), '입출금');
    await tester.enterText(accountFields.at(4), '500000');
    await tester.tap(find.byKey(const Key('save-account')));
    await tester.pumpAndSettle();
    expect(store.accounts, hasLength(accountCount + 1));
    expect(store.accounts.last.bankDisplayName, '우리 표시');
    expect(store.balanceFor(store.accounts.last.id), 500000);

    await tester.tap(find.text('거래내역'));
    await tester.pumpAndSettle();
    final transactionAccountId = store.accounts.first.id;
    final balanceBeforeTransaction = store.balanceFor(transactionAccountId);
    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    final transactionFields = find.byType(TextFormField);
    expect(transactionFields, findsNWidgets(4));
    await tester.enterText(transactionFields.at(0), 'MANAGED EXPENSE');
    await tester.enterText(transactionFields.at(1), '1000');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    expect(
      store.balanceFor(transactionAccountId),
      balanceBeforeTransaction - 1000,
    );
    expect(
      store.transactionsFor(transactionAccountId).first.title,
      'MANAGED EXPENSE',
    );

    await tester.tap(find.text('받는 분'));
    await tester.pumpAndSettle();
    final recipientCount = store.recipients.length;
    await tester.tap(find.byKey(const Key('add-recipient')));
    await tester.pumpAndSettle();
    final recipientFields = find.byType(TextFormField);
    expect(recipientFields, findsNWidgets(2));
    await tester.enterText(recipientFields.at(0), 'NEW RECIPIENT');
    await tester.enterText(recipientFields.at(1), '987654321');
    await tester.tap(find.byKey(const Key('save-recipient')));
    await tester.pumpAndSettle();
    expect(store.recipients, hasLength(recipientCount + 1));
    expect(store.recipients.last.displayName, 'NEW RECIPIENT');
  });

  testWidgets('transaction editor requires a real timestamp to the second', (
    tester,
  ) async {
    final store = AppDataStore.inMemory();
    await tester.pumpWidget(
      _TestHost(home: DataManagementScreen(store: store, initialTab: 1)),
    );

    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'SECOND PRECISION');
    await tester.enterText(fields.at(1), '1000');

    final dateField = find.byKey(const Key('transaction-date-time'));
    await tester.enterText(dateField, '2026-07-30 12:34');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pump();
    expect(find.text('초 단위까지 정확히 입력해주세요.'), findsOneWidget);

    await tester.enterText(dateField, '2026-02-30 12:34:56');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pump();
    expect(find.text('초 단위까지 정확히 입력해주세요.'), findsOneWidget);

    await tester.enterText(dateField, '2026-02-28 12:34:56');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    expect(
      store.transactionsFor(store.accounts.first.id).first.occurredAt,
      DateTime(2026, 2, 28, 12, 34, 56),
    );
  });

  testWidgets('account details stops displaying an archived account', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    final archivedId = store.accounts.first.id;
    final replacement = await store.createAccount(
      bankCode: '우리',
      bankDisplayName: '우리 표시',
      ownerName: 'REPLACEMENT',
      accountNumber: '200-300-400',
      accountType: '입출금',
      openingBalance: 123456,
    );
    await tester.pumpWidget(
      _TestHost(
        home: AccountDetailsScreen(
          auth: _SignedInAuthService(),
          dataStore: store,
          accountId: archivedId,
        ),
      ),
    );
    expect(find.textContaining('110-628-103680'), findsOneWidget);

    await store.archiveAccount(archivedId);
    await tester.pump();

    expect(find.textContaining('110-628-103680'), findsNothing);
    expect(find.textContaining(replacement.accountNumber), findsOneWidget);
    expect(find.text('123,456원'), findsWidgets);
  });

  testWidgets('transfer failure leaves balance and history unchanged', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    final accountId = store.accounts.first.id;
    final before = store.balanceFor(accountId);
    final transactionsBefore = store
        .transactionsFor(accountId)
        .map((transaction) => transaction.id)
        .toList();
    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(auth: _SignedInAuthService(), dataStore: store),
      ),
    );

    await tester.tap(find.byKey(const Key('home-transfer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipient-TRINH TRUN')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('transfer-next')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    expect(find.text('계좌 비밀번호'), findsOneWidget);
    for (final digit in ['0', '1', '2', '3']) {
      await tester.tap(find.byKey(Key('transfer-pin-key-$digit')));
    }
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byKey(const Key('transfer-failure-home-confirm')),
      findsOneWidget,
    );
    expect(store.balanceFor(accountId), before);
    expect(
      store.transactionsFor(accountId).map((transaction) => transaction.id),
      transactionsBefore,
    );
  });

  testWidgets('a failed manual transfer does not create a saved recipient', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );

    await tester.tap(find.byKey(const Key('transfer-manual-entry')));
    await tester.pump();
    for (final digit in '777000001234'.split('')) {
      await tester.tap(find.byKey(Key('account-key-$digit')));
    }
    await tester.tap(find.byKey(const Key('transfer-bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-우리')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amount-key-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-next')));
    await tester.pumpAndSettle();
    for (final digit in ['0', '1', '2', '3']) {
      await tester.tap(find.byKey(Key('transfer-pin-key-$digit')));
    }
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('transfer-failure-home-confirm')),
      findsOneWidget,
    );
    expect(
      store.recipients.any(
        (recipient) =>
            recipient.bankCode == '우리' &&
            recipient.accountNumber == '777000001234',
      ),
      isFalse,
    );
  });

  testWidgets('home and account management react to stored data', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    final auth = _SignedInAuthService();
    final accountId = store.accounts.first.id;
    await tester.pumpWidget(
      _TestHost(
        home: HomeScreen(auth: auth, dataStore: store),
      ),
    );
    expect(find.text('388,489원'), findsOneWidget);

    await store.createTransaction(
      accountId: accountId,
      title: 'NEW INCOME',
      signedAmount: 1000,
      occurredAt: DateTime(2026, 7, 30, 12, 0, 1),
      channel: '모바일',
    );
    await tester.pump();
    expect(find.text('389,489원'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-account-card')));
    await tester.pumpAndSettle();
    expect(find.text('389,489원'), findsWidgets);
    await tester.tap(find.byKey(const Key('account-manage')));
    await tester.pumpAndSettle();
    expect(find.byType(DataManagementScreen), findsOneWidget);
    expect(find.text('데이터 관리'), findsOneWidget);
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
    String? displayName,
  }) async {
    return const AuthResult(ok: true, message: 'Thành công.');
  }
}

class _RegisteringAuthService extends AuthService {
  String? registeredDisplayName;

  @override
  Future<AuthResult> authenticate({
    required AuthMode mode,
    required String email,
    required String password,
    String? displayName,
  }) async {
    registeredDisplayName = displayName;
    return const AuthResult(ok: true, message: 'Thành công.');
  }
}

class _SignedInAuthService extends AuthService {
  _SignedInAuthService({this.name = 'TRINHTRUNGMINH'});

  bool signedOut = false;
  final String name;

  @override
  String? get currentEmail => signedOut ? null : 'test@gmail.com';

  @override
  String get displayName => name;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/main.dart';
import 'package:super_sol/ui/account_details_screen.dart';
import 'package:super_sol/ui/auth_sheet.dart';
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
    expect(accountNameWidget.style?.fontSize, 23);
    expect(accountNameWidget.style?.fontWeight, FontWeight.w600);
    expect(
      accountNamePainter.width,
      lessThanOrEqualTo(tester.getSize(accountNameFinder).width),
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
    SharedPreferences.setMockInitialValues({});
    final auth = _SignedInAuthService();
    final store = AppDataStore();
    await store.initialize(auth.dataScope);
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
    expect(
      store
          .transactionsFor(store.accounts.first.id)
          .where((item) => item.title == 'SIGNED-IN-ONLY'),
      isEmpty,
    );
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
    expect(find.byKey(const Key('account-home-glyph')), findsOneWidget);
    expect(find.byKey(const Key('account-scan-icon')), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('bank-tab-증권사')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-신한투자증권')), findsOneWidget);
    expect(find.byKey(const Key('bank-교보증권')), findsOneWidget);
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
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('transfer-recipient-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Npay');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipient-search-Npay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipient-search-Npay')));
    await tester.pumpAndSettle();
    expect(find.text('Npay 계좌로'), findsOneWidget);
    expect(find.textContaining('56020228505759'), findsOneWidget);
  });

  testWidgets('camera shortcut enters the manual account flow', (tester) async {
    _configureMockupViewport(tester);
    await tester.pumpWidget(_TestHost(home: TransferRecipientScreen()));

    await tester.tap(find.byKey(const Key('transfer-camera')));
    await tester.pump();
    expect(find.byKey(const Key('account-key-1')), findsOneWidget);
    expect(find.byKey(const Key('transfer-bank-selector')), findsOneWidget);
  });

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

  testWidgets('successful transfer creates an expense transaction', (
    tester,
  ) async {
    _configureMockupViewport(tester);
    final store = AppDataStore.inMemory();
    final accountId = store.accounts.first.id;
    final before = store.balanceFor(accountId);
    await tester.pumpWidget(
      _TestHost(home: TransferRecipientScreen(dataStore: store)),
    );

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

    expect(store.balanceFor(accountId), before - 1);
    expect(find.text('이체 완료'), findsOneWidget);
    expect(store.transactionsFor(accountId).first.title, 'TRINH TRUN');
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

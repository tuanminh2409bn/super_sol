import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sol/core/app_data.dart';
import 'package:super_sol/core/auth_service.dart';
import 'package:super_sol/ui/account_details_screen.dart';

const _sheetKey = Key('transaction-details-sheet');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'NotoSansKR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final incoming in [false, true]) {
    final kind = incoming ? 'credit' : 'debit';

    testWidgets('$kind row opens its real transaction details', (tester) async {
      final store = await _openHistory(tester);
      await _openDetails(tester, store, incoming: incoming);
      final sheet = find.byKey(_sheetKey);
      Finder textInSheet(String text) =>
          find.descendant(of: sheet, matching: find.text(text));
      expect(textInSheet('거래내역상세'), findsOneWidget);
      expect(
        textInSheet(incoming ? 'LEKIMCUC' : 'NGUYEN XUAN HIEU'),
        findsOneWidget,
      );
      expect(
        textInSheet(incoming ? '2026.09.29 15:19:19' : '2026.09.29 15:23:52'),
        findsOneWidget,
      );
      expect(textInSheet(incoming ? '타행모바일뱅킹' : '모바일'), findsOneWidget);
      expect(textInSheet(incoming ? '10,333원' : '-10원'), findsOneWidget);
      expect(textInSheet(incoming ? '228,201원' : '228,191원'), findsOneWidget);
      expect(
        find.byKey(const Key('transaction-details-result')),
        incoming ? findsNothing : findsOneWidget,
      );
      expect(tester.getTopLeft(sheet).dy, incoming ? 586 : 507);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$kind backdrop dismissal slides down and preserves history', (
      tester,
    ) async {
      final store = await _openHistory(tester);
      final accountId = store.accounts.single.id;
      final before = store
          .transactionsFor(accountId)
          .map((item) => item.toJson())
          .toList();
      await _openDetails(tester, store, incoming: incoming);
      final sheet = find.byKey(_sheetKey);
      final restingTop = tester.getTopLeft(sheet).dy;
      await tester.tapAt(const Offset(290, 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(sheet, findsOneWidget);
      expect(tester.getTopLeft(sheet).dy, greaterThan(restingTop));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(AccountDetailsScreen), findsOneWidget);
      expect(store.balanceFor(accountId), 228191);
      expect(
        store.transactionsFor(accountId).map((item) => item.toJson()).toList(),
        before,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$kind follows a downward drag and dismisses', (tester) async {
      final store = await _openHistory(tester);
      await _openDetails(tester, store, incoming: incoming);
      final sheet = find.byKey(_sheetKey);
      final top = tester.getTopLeft(sheet).dy;
      final gesture = await tester.startGesture(Offset(290, top + 110));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      expect(tester.getTopLeft(sheet).dy, greaterThan(top + 100));
      await gesture.moveBy(const Offset(0, 240));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final control in ['close', 'confirm']) {
      testWidgets('$kind $control button dismisses the popup', (tester) async {
        final store = await _openHistory(tester);
        await _openDetails(tester, store, incoming: incoming);
        await tester.tap(find.byKey(Key('transaction-details-$control')));
        await tester.pumpAndSettle();
        expect(find.byKey(_sheetKey), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$kind popup matches the reference layout', (tester) async {
      final store = await _openHistory(tester);
      await _openDetails(tester, store, incoming: incoming);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/transaction_details_$kind.png'),
      );
    });
  }

  testWidgets('small drag returns to the open sheet; system back closes it', (
    tester,
  ) async {
    final store = await _openHistory(tester);
    await _openDetails(tester, store, incoming: true);
    final top = tester.getTopLeft(find.byKey(_sheetKey)).dy;
    await tester.timedDragFrom(
      Offset(290, top + 110),
      const Offset(0, 70),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_sheetKey)).dy, top);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_sheetKey), findsNothing);
  });

  testWidgets(
    'opening from scrolled history retains offset and balance visibility',
    (tester) async {
      final store = await _openHistory(tester);
      await tester.tap(
        find.byKey(const Key('account-balance-visibility-toggle')),
      );
      final scrollable = find.descendant(
        of: find.byKey(const Key('account-details-scroll')),
        matching: find.byType(Scrollable),
      );
      tester.state<ScrollableState>(scrollable).position.jumpTo(360);
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(scrollable).position.pixels;
      await _openDetails(tester, store, incoming: false);
      await tester.tapAt(const Offset(290, 350));
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(scrollable).position.pixels, before);
      final transaction = store.transactionsFor(store.accounts.single.id).first;
      expect(
        find.byKey(Key('account-transaction-balance-${transaction.id}')),
        findsNothing,
      );
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    testWidgets('both popups fit $size with a bottom safe area', (
      tester,
    ) async {
      final store = await _openHistory(tester, size: size, bottomInset: 34);
      for (final incoming in [false, true]) {
        await _openDetails(tester, store, incoming: incoming);
        final rect = tester.getRect(find.byKey(_sheetKey));
        expect(rect.top, greaterThan(0));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        final confirm = find.byKey(const Key('transaction-details-confirm'));
        expect(
          tester.getBottomRight(confirm).dy,
          lessThanOrEqualTo(size.height - 34 + .01),
        );
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}

Future<AppDataStore> _openHistory(
  WidgetTester tester, {
  Size size = const Size(589, 1280),
  double bottomInset = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
  tester.view.padding = FakeViewPadding(bottom: bottomInset);
  addTearDown(tester.view.reset);
  final store = AppDataStore.inMemory(withMockData: false);
  addTearDown(store.dispose);
  final account = await store.createAccount(
    bankCode: '신한',
    bankDisplayName: '신한',
    ownerName: 'TRINHTRUNGMINH',
    accountNumber: '110-628-103680',
    accountType: '[금융거래한도계좌2]저축예금',
    openingBalance: 217868,
  );
  await store.createTransaction(
    accountId: account.id,
    title: 'LEKIMCUC',
    signedAmount: 10333,
    occurredAt: DateTime(2026, 9, 29, 15, 19, 19),
    channel: '타행모바일뱅킹',
  );
  await store.createTransaction(
    accountId: account.id,
    title: 'NGUYEN XUAN HIEU',
    signedAmount: -10,
    occurredAt: DateTime(2026, 9, 29, 15, 23, 52),
    channel: '모바일',
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'NotoSansKR'),
      home: AccountDetailsScreen(
        auth: AuthService(),
        dataStore: store,
        nowProvider: () => DateTime(2026, 9, 29),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _openDetails(
  WidgetTester tester,
  AppDataStore store, {
  required bool incoming,
}) async {
  final transaction = store
      .transactionsFor(store.accounts.single.id)
      .firstWhere((item) => item.incoming == incoming);
  await tester.tap(find.byKey(Key('account-transaction-${transaction.id}')));
  await tester.pumpAndSettle();
}

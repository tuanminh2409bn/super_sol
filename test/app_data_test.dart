import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_sol/core/app_data.dart';

void main() {
  group('AppDataStore balance invariants', () {
    late AppDataStore store;
    late String accountId;

    setUp(() {
      store = AppDataStore.inMemory();
      accountId = store.accounts.first.id;
    });

    test('seed data reproduces the mockup balance exactly', () {
      expect(store.balanceFor(accountId), 388489);
      final transactions = store.transactionsFor(accountId);
      expect(transactions, hasLength(7));
      expect(store.runningBalanceFor(transactions.first), 388489);
      expect(store.runningBalanceFor(transactions.last), 360289);
    });

    test('create, edit and delete apply the exact signed delta', () async {
      final before = store.balanceFor(accountId);
      final created = await store.createTransaction(
        accountId: accountId,
        title: '테스트 입금',
        signedAmount: 12345,
        occurredAt: DateTime(2026, 7, 23, 1, 2, 3),
        channel: '모바일',
      );
      expect(store.balanceFor(accountId), before + 12345);

      await store.saveTransaction(created.copyWith(signedAmount: -2000));
      expect(store.balanceFor(accountId), before - 2000);

      await store.deleteTransaction(created.id);
      expect(store.balanceFor(accountId), before);
    });

    test(
      'duplicate changes balance once and reorder never changes it',
      () async {
        final source = store.transactionsFor(accountId).first;
        final before = store.balanceFor(accountId);
        final duplicate = await store.duplicateTransaction(source.id);
        expect(duplicate, isNotNull);
        expect(store.balanceFor(accountId), before + source.signedAmount);

        final afterDuplicate = store.balanceFor(accountId);
        await store.reorderTransactions(accountId, 0, 2);
        expect(store.balanceFor(accountId), afterDuplicate);
      },
    );

    test('changing date to the second recalculates running balances', () async {
      final transactions = store.transactionsFor(accountId);
      final latest = transactions.first;
      final changed = latest.copyWith(
        occurredAt: DateTime(2026, 7, 20, 0, 0, 1),
      );
      await store.saveTransaction(changed);

      expect(store.balanceFor(accountId), 388489);
      expect(store.runningBalanceFor(changed), 559289);
    });

    test('editing displayed balance sets the exact requested total', () async {
      final account = store.accountById(accountId)!;
      await store.saveAccountWithCurrentBalance(account, 500000);
      expect(store.balanceFor(accountId), 500000);
      expect(store.transactionsFor(accountId), hasLength(7));
    });

    test('internal transfer updates both accounts in one operation', () async {
      final destination = await store.createAccount(
        bankCode: '우리',
        bankDisplayName: '우리',
        ownerName: 'SECOND',
        accountNumber: '200-300-400',
        accountType: '입출금',
        openingBalance: 10000,
      );
      final sourceBefore = store.balanceFor(accountId);
      final destinationBefore = store.balanceFor(destination.id);

      await store.recordTransfer(
        sourceAccountId: accountId,
        destinationAccountId: destination.id,
        recipientTitle: 'SECOND',
        amount: 5000,
        occurredAt: DateTime(2026, 7, 30, 1, 2, 3),
      );

      expect(store.balanceFor(accountId), sourceBefore - 5000);
      expect(store.balanceFor(destination.id), destinationBefore + 5000);
    });

    test(
      'transfer rejects insufficient funds without changing balance',
      () async {
        final before = store.balanceFor(accountId);
        await expectLater(
          store.recordTransfer(
            sourceAccountId: accountId,
            recipientTitle: 'TOO LARGE',
            amount: before + 1,
            occurredAt: DateTime(2026, 7, 30),
          ),
          throwsStateError,
        );
        expect(store.balanceFor(accountId), before);
      },
    );

    test(
      'invalid destination rejects transfer without mutating source data',
      () async {
        final beforeBalance = store.balanceFor(accountId);
        final beforeTransactions = store
            .transactionsFor(accountId)
            .map((item) => item.id)
            .toList();

        await expectLater(
          store.recordTransfer(
            sourceAccountId: accountId,
            destinationAccountId: 'missing-account',
            recipientTitle: 'INVALID DESTINATION',
            amount: 5000,
            occurredAt: DateTime(2026, 7, 30, 12, 34, 56),
          ),
          throwsStateError,
        );

        expect(store.balanceFor(accountId), beforeBalance);
        expect(
          store.transactionsFor(accountId).map((item) => item.id),
          beforeTransactions,
        );
      },
    );

    test('transfer rejects a blank recipient title', () async {
      final beforeBalance = store.balanceFor(accountId);
      await expectLater(
        store.recordTransfer(
          sourceAccountId: accountId,
          recipientTitle: '   ',
          amount: 1000,
          occurredAt: DateTime(2026, 7, 30, 12, 34, 56),
        ),
        throwsArgumentError,
      );
      expect(store.balanceFor(accountId), beforeBalance);
    });
  });

  group('AppDataStore CRUD', () {
    test('accounts and recipients can be added, edited and removed', () async {
      final store = AppDataStore.inMemory();
      final account = await store.createAccount(
        bankCode: '우리',
        bankDisplayName: '우리 커스텀',
        ownerName: 'TEST OWNER',
        accountNumber: '100-200-300',
        accountType: '입출금',
        openingBalance: 500000,
      );
      expect(store.balanceFor(account.id), 500000);

      await store.saveAccount(
        account.copyWith(bankDisplayName: '새 표시 이름', openingBalance: 700000),
      );
      expect(store.accountById(account.id)?.bankDisplayName, '새 표시 이름');
      expect(store.balanceFor(account.id), 700000);

      final recipient = await store.createRecipient(
        displayName: '받는 사람',
        bankCode: '하나',
        accountNumber: '123456789',
      );
      await store.saveRecipient(recipient.copyWith(displayName: '수정된 이름'));
      expect(
        store.recipients
            .singleWhere((item) => item.id == recipient.id)
            .displayName,
        '수정된 이름',
      );
      await store.deleteRecipient(recipient.id);
      expect(
        store.recipients.where((item) => item.id == recipient.id),
        isEmpty,
      );

      await store.archiveAccount(account.id);
      expect(store.accounts.where((item) => item.id == account.id), isEmpty);
    });
  });

  test('data persists per user scope and reloads without reseeding', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AppDataStore();
    await first.initialize('user-a');
    final accountId = first.accounts.first.id;
    await first.createTransaction(
      accountId: accountId,
      title: '영구 저장',
      signedAmount: 777,
      occurredAt: DateTime(2026, 7, 29, 12, 34, 56),
      channel: '모바일',
    );
    final expectedBalance = first.balanceFor(accountId);

    final reloaded = AppDataStore();
    await reloaded.initialize('user-a');
    expect(reloaded.balanceFor(accountId), expectedBalance);
    expect(
      reloaded
          .transactionsFor(accountId)
          .where((item) => item.title == '영구 저장'),
      hasLength(1),
    );

    final otherUser = AppDataStore();
    await otherUser.initialize('user-b');
    expect(
      otherUser
          .transactionsFor(otherUser.accounts.first.id)
          .where((item) => item.title == '영구 저장'),
      isEmpty,
    );
  });

  test('corrupted local data recovers to a valid seed state', () async {
    SharedPreferences.setMockInitialValues({
      'super_sol_app_data_v1-Z3Vlc3Q=': '{not-valid-json',
    });
    final store = AppDataStore();

    await store.initialize('guest');

    expect(store.accounts, isNotEmpty);
    expect(store.balanceFor(store.accounts.first.id), 388489);
    expect(store.transactionsFor(store.accounts.first.id), hasLength(7));
    expect(store.recipients, hasLength(8));
  });
}

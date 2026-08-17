import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_data.dart';
import '../core/auth_service.dart';
import 'bank_logo.dart';
import 'data_management_screen.dart';
import 'design_canvas.dart';
import 'transfer_recipient_screen.dart';

const _detailsInk = Color(0xFF141820);
const _detailsMuted = Color(0xFF626B79);
const _detailsSecondary = Color(0xFF505866);
const _detailsBlue = Color(0xFF0068F5);
const _detailsDivider = Color(0xFFF1F4F8);
const _detailsAccountNumber = Color(0xFF505866);
const _detailsAccountLogoSize = 52.0;
const _detailsAccountTypeWidth = 427.0;
const _detailsAccountTypeStyle = TextStyle(
  color: Color(0xFF2D323C),
  fontFamily: 'NotoSansKR',
  fontSize: 22,
  fontWeight: FontWeight.w600,
  letterSpacing: -1,
);

class AccountDetailsScreen extends StatefulWidget {
  AccountDetailsScreen({
    super.key,
    required this.auth,
    this.initialScrollOffset = 0,
    AppDataStore? dataStore,
    this.accountId,
  }) : dataStore = dataStore ?? AppDataStore.shared;

  final AuthService auth;
  final AppDataStore dataStore;
  final String? accountId;
  final double initialScrollOffset;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late final ScrollController _scrollController;
  late double _scrollOffset;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
    _scrollOffset = widget.initialScrollOffset;
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset,
    )..addListener(_handleScroll);
    widget.dataStore.addListener(_handleDataChange);
  }

  void _handleScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() > 1) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  void dispose() {
    widget.dataStore.removeListener(_handleDataChange);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    showDeviceStatusBar(
      darkIcons: true,
      backgroundColor: const Color(0xFFF0F3FA),
    );
    super.dispose();
  }

  void _handleDataChange() {
    if (mounted) setState(() {});
  }

  void _goHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _scrollToTop() {
    return _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openTransferRecipient() async {
    final result = await Navigator.of(context).push<TransferFlowResult>(
      MaterialPageRoute<TransferFlowResult>(
        builder: (_) => TransferRecipientScreen(dataStore: widget.dataStore),
      ),
    );
    if (!mounted) return;
    if (result == TransferFlowResult.failed) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(result);
      } else {
        await showTransferFailurePopup(context);
      }
      return;
    }
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
  }

  Future<void> _openManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DataManagementScreen(
          store: widget.dataStore,
          initialAccountId: _selectedAccount?.id,
        ),
      ),
    );
  }

  BankAccount? get _selectedAccount {
    final activeAccounts = widget.dataStore.accounts;
    final requested = widget.accountId;
    if (requested != null) {
      for (final account in activeAccounts) {
        if (account.id == requested) return account;
      }
    }
    return activeAccounts.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final accountLabel = widget.auth.isSignedIn
        ? widget.auth.displayName
        : 'TÀI KHOẢN';
    final account = _selectedAccount;
    final accountType = _displayAccountType(account?.accountType);
    final accountSummaryOffset = _accountTypeWrapOffset(accountType);
    final transactions = account == null
        ? const <LedgerTransaction>[]
        : widget.dataStore.transactionsFor(account.id);
    final requiredContentHeight =
        _TransactionLayoutMetrics.contentBottom(
          transactions,
          verticalOffset: accountSummaryOffset,
        ) +
        _TransactionLayoutMetrics.bottomPadding;
    final contentHeight = requiredContentHeight > 1780
        ? requiredContentHeight
        : 1780.0;
    final collapsed = _scrollOffset >= 340;

    return DesignCanvas(
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          Positioned.fill(
            child: SingleChildScrollView(
              key: const Key('account-details-scroll'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: mockupWidth,
                height: contentHeight,
                child: Stack(
                  children: [
                    _AccountSummary(
                      account: account,
                      accountType: accountType,
                      balance: account == null
                          ? 0
                          : widget.dataStore.balanceFor(account.id),
                      verticalOffset: accountSummaryOffset,
                      onTransfer: _openTransferRecipient,
                    ),
                    _TransactionList(
                      accountName: accountLabel,
                      account: account,
                      transactions: transactions,
                      store: widget.dataStore,
                      verticalOffset: accountSummaryOffset,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: collapsed ? 199 : 185,
            child: const ColoredBox(color: Colors.white),
          ),
          if (collapsed) ...[
            const Positioned(
              left: 0,
              right: 0,
              top: 184,
              height: 15,
              child: ColoredBox(color: _detailsDivider),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 199,
              height: 82,
              child: ColoredBox(color: Colors.white),
            ),
            const _FilterBar(top: 214),
          ],
          _DetailsHeader(
            onBack: _goHome,
            onHome: _goHome,
            onManage: _openManagement,
          ),
          if (collapsed)
            Positioned(
              right: 29,
              bottom: 48,
              width: 68,
              height: 68,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: IconButton(
                  key: const Key('account-scroll-top'),
                  onPressed: _scrollToTop,
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 31,
                    color: _detailsInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.onBack,
    required this.onHome,
    required this.onManage,
  });

  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 104,
      height: 66,
      child: Stack(
        children: [
          Positioned(
            left: 27,
            top: 2,
            width: 50,
            height: 50,
            child: IconButton(
              key: const Key('account-back'),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 28,
                color: _detailsInk,
              ),
            ),
          ),
          Positioned(
            right: 78,
            top: 2,
            width: 94,
            height: 50,
            child: TextButton(
              key: const Key('account-manage'),
              onPressed: onManage,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '계좌관리',
                style: TextStyle(
                  color: _detailsBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.8,
                ),
              ),
            ),
          ),
          Positioned(
            right: 19,
            top: 5,
            width: 50,
            height: 50,
            child: IconButton(
              key: const Key('account-home'),
              onPressed: onHome,
              padding: EdgeInsets.zero,
              icon: const _AccountHomeIcon(key: Key('account-home-glyph')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({
    required this.account,
    required this.accountType,
    required this.balance,
    required this.verticalOffset,
    required this.onTransfer,
  });

  final BankAccount? account;
  final String accountType;
  final int balance;
  final double verticalOffset;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 28,
          top: 201,
          width: 83,
          height: 33,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF344052),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                '한도계좌',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 245,
          width: _detailsAccountLogoSize,
          height: _detailsAccountLogoSize,
          child: account == null
              ? const Icon(Icons.account_balance_rounded)
              : BankLogo(
                  key: const Key('account-details-logo'),
                  bankCode: account!.bankCode,
                  size: _detailsAccountLogoSize,
                ),
        ),
        Positioned(
          left: 90,
          top: 243,
          width: _detailsAccountTypeWidth,
          child: Text(
            key: const Key('account-type-text'),
            accountType,
            softWrap: true,
            style: _detailsAccountTypeStyle,
          ),
        ),
        Positioned(
          left: 90,
          right: 72,
          top: 285 + verticalOffset,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  key: const Key('account-number-text'),
                  account == null
                      ? '-'
                      : '${account!.bankDisplayName} ${account!.accountNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _detailsAccountNumber,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontVariations: [FontVariation('wght', 500)],
                    letterSpacing: -.5,
                  ),
                ),
              ),
              if (account != null) ...[
                const SizedBox(width: 5),
                GestureDetector(
                  key: const Key('account-copy'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Clipboard.setData(
                    ClipboardData(text: account!.accountNumber),
                  ),
                  child: const _AccountCopyIcon(key: Key('account-copy-glyph')),
                ),
              ],
            ],
          ),
        ),
        const Positioned(
          right: 30,
          top: 245,
          child: _AccountScanIcon(key: Key('account-scan-icon')),
        ),
        Positioned(
          left: 28,
          top: 330 + verticalOffset,
          child: Text(
            key: const Key('account-balance-text'),
            '${_formatDetailsMoney(balance)}원',
            style: const TextStyle(
              color: _detailsInk,
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.5,
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 381 + verticalOffset,
          child: Text(
            key: const Key('account-available-balance-text'),
            '출금가능금액 ${_formatDetailsMoney(balance)}원',
            style: const TextStyle(
              color: _detailsSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontVariations: [FontVariation('wght', 500)],
              letterSpacing: -.5,
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 432 + verticalOffset,
          width: 533,
          height: 68,
          child: GestureDetector(
            key: const Key('account-transfer'),
            behavior: HitTestBehavior.opaque,
            onTap: onTransfer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  '이체',
                  style: TextStyle(
                    color: _detailsBlue,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 534 + verticalOffset,
          height: 15,
          child: const ColoredBox(color: _detailsDivider),
        ),
      ],
    );
  }
}

class _AccountHomeIcon extends StatelessWidget {
  const _AccountHomeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 30,
      child: CustomPaint(painter: _AccountHomePainter()),
    );
  }
}

class _AccountHomePainter extends CustomPainter {
  const _AccountHomePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _detailsInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final home = Path()
      ..moveTo(3, 12)
      ..lineTo(15, 2.5)
      ..lineTo(26.5, 12)
      ..moveTo(5, 10.5)
      ..lineTo(5, 26.5)
      ..lineTo(12, 26.5)
      ..lineTo(12, 17.5)
      ..lineTo(18, 17.5)
      ..lineTo(18, 26.5)
      ..lineTo(24.5, 26.5)
      ..lineTo(24.5, 10.5);

    canvas.drawPath(home, paint);
  }

  @override
  bool shouldRepaint(_AccountHomePainter oldDelegate) => false;
}

class _AccountScanIcon extends StatelessWidget {
  const _AccountScanIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 30,
      child: CustomPaint(painter: _AccountScanPainter()),
    );
  }
}

class _AccountCopyIcon extends StatelessWidget {
  const _AccountCopyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 15,
      child: CustomPaint(painter: _AccountCopyPainter()),
    );
  }
}

class _AccountCopyPainter extends CustomPainter {
  const _AccountCopyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _detailsAccountNumber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    // The source-app glyph is not two complete overlapping rectangles. The
    // rear sheet is visible only as its upper and right edges, while the front
    // sheet is a closed square. Keeping those paths separate preserves the
    // crisp negative space visible in the original mockup at this small size.
    final rearSheet = Path()
      ..moveTo(4.65, 1.45)
      ..lineTo(13.45, 1.45)
      ..lineTo(13.45, 10.25);
    canvas.drawPath(rearSheet, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.55, 4.55, 8.9, 8.9),
        const Radius.circular(.35),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AccountCopyPainter oldDelegate) => false;
}

class _AccountScanPainter extends CustomPainter {
  const _AccountScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _detailsInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final corners = Path()
      ..moveTo(4.5, 10.5)
      ..lineTo(4.5, 4)
      ..lineTo(11, 4)
      ..moveTo(19, 4)
      ..lineTo(25.5, 4)
      ..lineTo(25.5, 10.5)
      ..moveTo(25.5, 19.5)
      ..lineTo(25.5, 27)
      ..lineTo(19, 27)
      ..moveTo(11, 27)
      ..lineTo(4.5, 27)
      ..lineTo(4.5, 19.5);
    canvas.drawPath(corners, paint);

    final plusPaint = Paint()
      ..color = _detailsInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(11, 15), const Offset(19, 15), plusPaint)
      ..drawLine(const Offset(15, 11), const Offset(15, 19), plusPaint);
  }

  @override
  bool shouldRepaint(_AccountScanPainter oldDelegate) => false;
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.accountName,
    required this.account,
    required this.transactions,
    required this.store,
    required this.verticalOffset,
  });

  final String accountName;
  final BankAccount? account;
  final List<LedgerTransaction> transactions;
  final AppDataStore store;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _FilterBar(top: 558 + verticalOffset),
        ..._transactionWidgets(),
      ],
    );
  }

  List<Widget> _transactionWidgets() {
    if (account == null || transactions.isEmpty) {
      return [
        Positioned(
          left: 0,
          right: 0,
          top: 680 + verticalOffset,
          child: const Text(
            '거래내역이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _detailsMuted, fontSize: 18),
          ),
        ),
      ];
    }
    final widgets = <Widget>[];
    var cursor = _TransactionLayoutMetrics.firstRowTop + verticalOffset;
    String? previousDate;
    for (final transaction in transactions) {
      final dateKey = _TransactionLayoutMetrics.dateKey(transaction);
      if (dateKey != previousDate) {
        if (previousDate != null) {
          widgets.add(
            Positioned(
              left: 28,
              right: 28,
              top: cursor + 4,
              child: const Divider(height: 1, color: Color(0xFFE8EBF0)),
            ),
          );
          cursor += _TransactionLayoutMetrics.dayDividerExtent;
        }
        widgets.add(
          Positioned(
            left: 28,
            top: cursor,
            child: Text(
              key: Key('account-transaction-date-$dateKey'),
              '${transaction.occurredAt.month}월 '
              '${transaction.occurredAt.day}일',
              style: const TextStyle(
                color: _detailsSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
                letterSpacing: -.6,
              ),
            ),
          ),
        );
        cursor += _TransactionLayoutMetrics.dateHeaderExtent;
        previousDate = dateKey;
      }
      final signed = transaction.signedAmount;
      widgets.add(
        _TransactionRow(
          top: cursor,
          title: transaction.title,
          transactionId: transaction.id,
          time:
              '${_formatDetailsTime(transaction.occurredAt)} · '
              '${transaction.channel}',
          amount:
              '${signed >= 0 ? '+' : '-'}'
              '${_formatDetailsMoney(signed.abs())}원',
          balance:
              '${_formatDetailsMoney(store.runningBalanceFor(transaction))}원',
          positive: signed >= 0,
        ),
      );
      cursor += _TransactionLayoutMetrics.rowExtent;
    }
    return widgets;
  }
}

class _TransactionLayoutMetrics {
  const _TransactionLayoutMetrics._();

  static const firstRowTop = 652.0;
  static const dateHeaderExtent = 52.0;
  static const dayDividerExtent = 46.0;
  static const rowExtent = 110.0;
  static const bottomPadding = 150.0;

  static String dateKey(LedgerTransaction transaction) =>
      '${transaction.occurredAt.year}-${transaction.occurredAt.month}-'
      '${transaction.occurredAt.day}';

  static double contentBottom(
    List<LedgerTransaction> transactions, {
    required double verticalOffset,
  }) {
    var cursor = firstRowTop + verticalOffset;
    String? previousDate;
    for (final transaction in transactions) {
      final currentDate = dateKey(transaction);
      if (currentDate != previousDate) {
        if (previousDate != null) cursor += dayDividerExtent;
        cursor += dateHeaderExtent;
        previousDate = currentDate;
      }
      cursor += rowExtent;
    }
    return cursor;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 28,
      right: 28,
      top: top,
      height: 62,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 10,
            child: Icon(Icons.search_rounded, size: 35, color: _detailsInk),
          ),
          Positioned(
            right: 0,
            top: 14,
            child: Row(
              children: const [
                Text(
                  '3개월 · 전체 · 최신순',
                  style: TextStyle(
                    color: Color(0xFF303641),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.7,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: _detailsInk,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.top,
    required this.title,
    required this.transactionId,
    required this.time,
    required this.amount,
    required this.balance,
    this.positive = false,
  });

  final double top;
  final String title;
  final String transactionId;
  final String time;
  final String amount;
  final String balance;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 28,
      right: 28,
      top: top,
      height: 100,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 6,
            width: 330,
            height: 34,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF27303D),
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -.8,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Text(
              amount,
              style: TextStyle(
                color: positive ? _detailsBlue : _detailsInk,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -.8,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 49,
            child: Text(
              key: Key('account-transaction-time-$transactionId'),
              time,
              style: const TextStyle(
                color: _detailsSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
                letterSpacing: -.5,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 49,
            child: Text(
              key: Key('account-transaction-balance-$transactionId'),
              balance,
              style: const TextStyle(
                color: _detailsSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
                letterSpacing: -.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDetailsMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?<!^)(?=(\d{3})+$)'),
  (_) => ',',
);

double _accountTypeWrapOffset(String accountType) {
  final wrappedPainter = TextPainter(
    text: TextSpan(text: accountType, style: _detailsAccountTypeStyle),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: _detailsAccountTypeWidth);
  final singleLinePainter = TextPainter(
    text: const TextSpan(text: '가', style: _detailsAccountTypeStyle),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: _detailsAccountTypeWidth);
  final extraHeight = wrappedPainter.height - singleLinePainter.height;
  return extraHeight > 0 ? extraHeight : 0;
}

String _displayAccountType(String? value) {
  if (value == null || value.isEmpty) return '등록된 계좌가 없습니다';
  if (value.startsWith('금융거래한도계좌2]')) return '[$value';
  return value;
}

String _formatDetailsTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

import 'package:flutter/material.dart';

import '../core/app_data.dart';
import '../core/bank_catalog.dart';
import 'bank_logo.dart';
import 'data_management_screen.dart';
import 'design_canvas.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF818A99);
const _line = Color(0xFFD9DDE5);
const _blue = Color(0xFF0969F6);

enum _TransferStage { recipient, amount, confirmation }

class TransferRecipientScreen extends StatefulWidget {
  TransferRecipientScreen({super.key, AppDataStore? dataStore})
    : dataStore = dataStore ?? AppDataStore.shared;

  final AppDataStore dataStore;

  @override
  State<TransferRecipientScreen> createState() =>
      _TransferRecipientScreenState();
}

class _TransferRecipientScreenState extends State<TransferRecipientScreen> {
  _TransferStage _stage = _TransferStage.recipient;
  bool _manualEntry = false;
  bool _myAccountsExpanded = false;
  bool _sourceAccountSelectorVisible = false;
  String _account = '';
  String? _bank;
  String? _recipientName;
  String? _destinationAccountId;
  int _amount = 0;
  String? _sourceAccountId;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
    widget.dataStore.addListener(_handleDataChange);
  }

  @override
  void dispose() {
    widget.dataStore.removeListener(_handleDataChange);
    super.dispose();
  }

  void _handleDataChange() {
    if (mounted) setState(() {});
  }

  List<_SourceAccount> get _availableSourceAccounts => [
    for (final account in widget.dataStore.accounts)
      _SourceAccount(
        id: account.id,
        productName: account.accountType,
        bankCode: account.bankCode,
        bank: account.bankDisplayName,
        accountNumber: account.accountNumber,
        availableBalance: widget.dataStore.balanceFor(account.id),
      ),
  ];

  _SourceAccount? get _selectedSourceAccount {
    final accounts = _availableSourceAccounts;
    if (accounts.isEmpty) return null;
    for (final account in accounts) {
      if (account.id == _sourceAccountId) return account;
    }
    return accounts.first;
  }

  bool get _canContinue =>
      _account.isNotEmpty && _bank != null && _selectedSourceAccount != null;

  void _back() {
    if (_stage != _TransferStage.recipient) {
      setState(() => _stage = _TransferStage.recipient);
    } else if (_manualEntry) {
      setState(() => _manualEntry = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _appendAccount(String key) => setState(() => _account += key);
  void _deleteAccount() => setState(() {
    if (_account.isNotEmpty) {
      _account = _account.substring(0, _account.length - 1);
    }
  });
  void _appendAmount(String key) => setState(() {
    final digits = key == '00' ? 2 : 1;
    for (var i = 0; i < digits; i++) {
      _amount *= 10;
    }
    if (key != '00') _amount += int.parse(key);
  });
  void _deleteAmount() => setState(() => _amount ~/= 10);

  Future<void> _pickBank() async {
    final selected = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '은행 선택 닫기',
      barrierColor: const Color(0x8B27303E),
      pageBuilder: (_, __, ___) => _BankSelectorDialog(initialBank: _bank),
    );
    if (selected != null && mounted) setState(() => _bank = selected);
  }

  void _chooseRecipient(_Recipient recipient) {
    if (_selectedSourceAccount == null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('출금 계좌가 없습니다'),
          content: const Text('출금 계좌를 먼저 추가해주세요.'),
          actions: [
            FilledButton(
              key: const Key('missing-source-confirm'),
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _bank = recipient.bank;
      _account = recipient.account;
      _recipientName = recipient.name;
      _destinationAccountId = recipient.internalAccountId;
      _stage = _TransferStage.amount;
    });
  }

  List<_Recipient> get _savedRecipients => [
    for (final recipient in widget.dataStore.recipients)
      _Recipient(
        recipient.displayName,
        recipient.bankCode,
        recipient.accountNumber,
        BankCatalog.logoAsset(recipient.bankCode),
        bankCode: recipient.bankCode,
        recipientId: recipient.id,
        favorite: recipient.favorite,
      ),
  ];

  List<_Recipient> get _ownAccounts => [
    for (final account in widget.dataStore.accounts)
      _Recipient(
        account.accountType,
        account.bankDisplayName,
        account.accountNumber,
        BankCatalog.logoAsset(account.bankCode),
        bankCode: account.bankCode,
        internalAccountId: account.id,
      ),
  ];

  Future<void> _openRecipientManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DataManagementScreen(store: widget.dataStore, initialTab: 2),
      ),
    );
  }

  void _startManualEntry() {
    setState(() {
      _manualEntry = true;
      _account = '';
      _bank = null;
      _recipientName = null;
      _destinationAccountId = null;
    });
  }

  Future<void> _searchRecipients() async {
    final selected = await showSearch<_Recipient?>(
      context: context,
      delegate: _RecipientSearchDelegate([
        ..._ownAccounts,
        ..._savedRecipients,
      ]),
    );
    if (selected != null && mounted) _chooseRecipient(selected);
  }

  Future<void> _toggleFavorite(_Recipient recipient) async {
    final recipientId = recipient.recipientId;
    if (recipientId == null) return;
    for (final saved in widget.dataStore.recipients) {
      if (saved.id == recipientId) {
        await widget.dataStore.saveRecipient(
          saved.copyWith(favorite: !saved.favorite),
        );
        return;
      }
    }
  }

  Future<void> _completeTransfer() async {
    final source = _selectedSourceAccount;
    if (source == null || _amount <= 0) return;
    try {
      await widget.dataStore.recordTransfer(
        sourceAccountId: source.id,
        destinationAccountId: _destinationAccountId,
        recipientTitle: _recipientName ?? '${_bank ?? ''} $_account'.trim(),
        amount: _amount,
        occurredAt: DateTime.now(),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이체할 수 없습니다'),
          content: Text(error.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이체 완료'),
        content: Text('${_AmountPage._formatted(_amount)}원이 반영되었습니다.'),
        actions: [
          FilledButton(
            key: const Key('transfer-success-confirm'),
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sourceAccount = _selectedSourceAccount;
    final blockedRecipient = _account == '100237698805';
    final actionButtonBottom = _stage == _TransferStage.amount ? 20.0 : 54.0;
    return PopScope(
      onPopInvokedWithResult: (_, __) => showDeviceStatusBar(
        darkIcons: true,
        backgroundColor: const Color(0xFFF0F3FA),
      ),
      child: DesignCanvas(
        child: Material(
          color: Colors.white,
          child: Stack(
            children: [
              _TopControls(
                onBack: _back,
                onManageRecipients: _openRecipientManagement,
                showRecipientActions:
                    _stage == _TransferStage.recipient && !_manualEntry,
              ),
              if (_stage == _TransferStage.confirmation)
                _TransferReviewPage(bank: _bank ?? '토스뱅크', amount: _amount)
              else if (_stage == _TransferStage.amount && sourceAccount != null)
                _AmountPage(
                  sourceAccount: sourceAccount,
                  bank: _bank ?? '토스뱅크',
                  account: _account.isEmpty ? '100237698805' : _account,
                  recipientName: _recipientName,
                  amount: _amount,
                  onDigit: _appendAmount,
                  onDelete: _deleteAmount,
                  onChooseSourceAccount: () =>
                      setState(() => _sourceAccountSelectorVisible = true),
                )
              else if (_manualEntry)
                _ManualEntry(
                  account: _account,
                  bank: _bank,
                  onDigit: _appendAccount,
                  onDelete: _deleteAccount,
                  onClear: () => setState(() => _account = ''),
                  onChooseBank: _pickBank,
                )
              else
                _RecipientLanding(
                  ownAccounts: _ownAccounts,
                  recipients: _savedRecipients,
                  myAccountsExpanded: _myAccountsExpanded,
                  onSearch: _searchRecipients,
                  onToggleMyAccounts: () => setState(
                    () => _myAccountsExpanded = !_myAccountsExpanded,
                  ),
                  onManual: _startManualEntry,
                  onCamera: _startManualEntry,
                  onSelect: _chooseRecipient,
                  onToggleFavorite: _toggleFavorite,
                ),
              if (_stage != _TransferStage.recipient || _manualEntry)
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: actionButtonBottom,
                  height: 79,
                  child: FilledButton(
                    key: const Key('transfer-next'),
                    onPressed: _stage == _TransferStage.amount
                        ? (_amount > 0
                              ? () => setState(() {
                                  _stage = _TransferStage.confirmation;
                                })
                              : null)
                        : (_stage == _TransferStage.confirmation
                              ? (blockedRecipient ? null : _completeTransfer)
                              : _canContinue && sourceAccount != null
                              ? () => setState(
                                  () => _stage = _TransferStage.amount,
                                )
                              : null),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: const Color(0xFFF0F3F8),
                      disabledForegroundColor: const Color(0xFF98A1B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _stage == _TransferStage.confirmation ? '보내기' : '다음',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (_stage == _TransferStage.confirmation && blockedRecipient)
                _TransferConfirmation(
                  onConfirm: () =>
                      setState(() => _stage = _TransferStage.recipient),
                ),
              if (_sourceAccountSelectorVisible)
                _SourceAccountSelector(
                  accounts: _availableSourceAccounts,
                  selectedAccount: sourceAccount!,
                  onSelect: (account) => setState(() {
                    _sourceAccountId = account.id;
                    _sourceAccountSelectorVisible = false;
                  }),
                  onClose: () =>
                      setState(() => _sourceAccountSelectorVisible = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.onBack,
    required this.onManageRecipients,
    required this.showRecipientActions,
  });
  final VoidCallback onBack;
  final VoidCallback onManageRecipients;
  final bool showRecipientActions;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 24,
        top: 111,
        child: IconButton(
          key: const Key('transfer-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
        ),
      ),
      if (showRecipientActions)
        const Positioned(
          right: 142,
          top: 120,
          child: Text(
            '다건이체',
            key: Key('transfer-multiple'),
            style: TextStyle(
              color: _blue,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -.1,
            ),
          ),
        ),
      if (showRecipientActions)
        Positioned(
          right: 84,
          top: 112,
          width: 45,
          height: 45,
          child: IconButton(
            key: const Key('transfer-quick-recipient'),
            onPressed: onManageRecipients,
            padding: const EdgeInsets.all(6.5),
            icon: const _RecipientQuickTransferIcon(),
          ),
        ),
      Positioned(
        right: 21,
        top: 110,
        child: IconButton(
          key: const Key('transfer-home'),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const _TransferCloseIcon(),
        ),
      ),
    ],
  );
}

class _RecipientQuickTransferIcon extends StatelessWidget {
  const _RecipientQuickTransferIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _RecipientQuickTransferPainter());
  }
}

class _TransferCloseIcon extends StatelessWidget {
  const _TransferCloseIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 30,
      child: CustomPaint(painter: _TransferClosePainter()),
    );
  }
}

class _TransferClosePainter extends CustomPainter {
  const _TransferClosePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(5.5, 5.5), const Offset(24.5, 24.5), paint)
      ..drawLine(const Offset(24.5, 5.5), const Offset(5.5, 24.5), paint);
  }

  @override
  bool shouldRepaint(_TransferClosePainter oldDelegate) => false;
}

class _RecipientQuickTransferPainter extends CustomPainter {
  const _RecipientQuickTransferPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(const Offset(10, 7), 4, paint);

    final person = Path()
      ..moveTo(4, 22)
      ..cubicTo(5, 16.5, 7.5, 14, 11, 14)
      ..cubicTo(13.5, 14, 15, 15, 16, 16.5);
    canvas.drawPath(person, paint);

    final arrow = Path()
      ..moveTo(16, 22)
      ..lineTo(26, 22)
      ..moveTo(22, 18)
      ..lineTo(26, 22)
      ..lineTo(22, 27);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_RecipientQuickTransferPainter oldDelegate) => false;
}

class _RecipientLanding extends StatelessWidget {
  const _RecipientLanding({
    required this.ownAccounts,
    required this.recipients,
    required this.myAccountsExpanded,
    required this.onSearch,
    required this.onToggleMyAccounts,
    required this.onManual,
    required this.onCamera,
    required this.onSelect,
    required this.onToggleFavorite,
  });
  final List<_Recipient> ownAccounts;
  final List<_Recipient> recipients;
  final bool myAccountsExpanded;
  final VoidCallback onSearch;
  final VoidCallback onToggleMyAccounts;
  final VoidCallback onManual;
  final VoidCallback onCamera;
  final ValueChanged<_Recipient> onSelect;
  final ValueChanged<_Recipient> onToggleFavorite;
  @override
  Widget build(BuildContext context) {
    final recentOffset = myAccountsExpanded ? ownAccounts.length * 97.0 : 0.0;
    return Stack(
      children: [
        const Positioned(
          left: 28,
          top: 201,
          child: Text(
            '누구에게 보낼까요?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
            ),
          ),
        ),
        Positioned(
          right: 26,
          top: 196,
          child: _SquareIcon(
            key: const Key('transfer-recipient-search'),
            icon: Icons.search_rounded,
            onTap: onSearch,
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          top: 283,
          height: 70,
          child: InkWell(
            key: const Key('transfer-manual-entry'),
            onTap: onManual,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '계좌번호 직접 입력',
                style: TextStyle(fontSize: 21, color: _muted),
              ),
            ),
          ),
        ),
        Positioned(
          right: 28,
          top: 296,
          child: IconButton(
            key: const Key('transfer-camera'),
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined, size: 30),
          ),
        ),
        const Positioned(
          left: 28,
          right: 28,
          top: 354,
          child: Divider(color: _line, height: 1),
        ),
        const Positioned(
          left: 28,
          top: 387,
          child: Text(
            '내 계좌',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Positioned(
          right: 28,
          top: 375,
          child: _CountChip(
            myAccountsExpanded ? '${ownAccounts.length}개' : '0개',
            myAccountsExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            key: const Key('transfer-my-accounts-toggle'),
            onTap: onToggleMyAccounts,
          ),
        ),
        if (myAccountsExpanded)
          ...List.generate(
            ownAccounts.length,
            (index) => Positioned(
              left: 28,
              right: 25,
              top: 431 + (index * 97),
              height: 78,
              child: _RecipientRow(
                recipient: ownAccounts[index],
                onTap: () => onSelect(ownAccounts[index]),
              ),
            ),
          ),
        Positioned(
          left: 28,
          top: 461 + recentOffset,
          child: const Text(
            '최근',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Positioned(
          right: 28,
          top: 449 + recentOffset,
          child: const _CountChip('50개', Icons.keyboard_arrow_up_rounded),
        ),
        ...List.generate(
          recipients.length,
          (i) => Positioned(
            left: 28,
            right: 25,
            top: 515 + recentOffset + (i * 97),
            height: 78,
            child: _RecipientRow(
              recipient: recipients[i],
              onTap: () => onSelect(recipients[i]),
              onFavorite: () => onToggleFavorite(recipients[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 34),
    ),
  );
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.text, this.icon, {super.key, this.onTap});
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F1F4)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 17)),
          Icon(icon),
        ],
      ),
    ),
  );
}

class _Recipient {
  const _Recipient(
    this.name,
    this.bank,
    this.account,
    this.logoAsset, {
    this.bankCode,
    this.internalAccountId,
    this.recipientId,
    this.favorite = false,
  });
  final String name, bank, account;
  final String logoAsset;
  final String? bankCode;
  final String? internalAccountId;
  final String? recipientId;
  final bool favorite;
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({
    required this.recipient,
    required this.onTap,
    this.onFavorite,
  });
  final _Recipient recipient;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('recipient-${recipient.name}'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(
            child: Transform.scale(
              scale: BankCatalog.logoScale(
                recipient.bankCode ?? recipient.bank,
              ),
              child: Image.asset(
                recipient.logoAsset,
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipient.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${recipient.bank} ${recipient.account}',
                style: const TextStyle(fontSize: 17, color: _muted),
              ),
            ],
          ),
        ),
        if (onFavorite == null)
          const Icon(
            Icons.star_border_rounded,
            size: 31,
            color: Color(0xFF657084),
          )
        else
          GestureDetector(
            key: Key('recipient-favorite-${recipient.recipientId}'),
            behavior: HitTestBehavior.opaque,
            onTap: onFavorite,
            child: Icon(
              recipient.favorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 31,
              color: recipient.favorite
                  ? const Color(0xFFFFB300)
                  : const Color(0xFF657084),
            ),
          ),
      ],
    ),
  );
}

class _RecipientSearchDelegate extends SearchDelegate<_Recipient?> {
  _RecipientSearchDelegate(this.recipients);

  final List<_Recipient> recipients;

  List<_Recipient> get _matches {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return recipients;
    return recipients.where((recipient) {
      return recipient.name.toLowerCase().contains(normalized) ||
          recipient.bank.toLowerCase().contains(normalized) ||
          recipient.account.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  String get searchFieldLabel => '이름, 은행, 계좌번호 검색';

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        key: const Key('recipient-search-clear'),
        onPressed: () => query = '',
        icon: const Icon(Icons.clear_rounded),
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    key: const Key('recipient-search-back'),
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _buildMatches();

  @override
  Widget buildSuggestions(BuildContext context) => _buildMatches();

  Widget _buildMatches() {
    final matches = _matches;
    if (matches.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }
    return ListView.builder(
      key: const Key('recipient-search-results'),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final recipient = matches[index];
        return ListTile(
          key: Key('recipient-search-${recipient.name}'),
          leading: BankLogo(
            bankCode: recipient.bankCode ?? recipient.bank,
            size: 42,
          ),
          title: Text(recipient.name),
          subtitle: Text('${recipient.bank} ${recipient.account}'),
          onTap: () => close(context, recipient),
        );
      },
    );
  }
}

class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.account,
    required this.bank,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
    required this.onChooseBank,
  });
  final String account;
  final String? bank;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete, onClear, onChooseBank;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(
        left: 28,
        top: 201,
        child: Text(
          '누구에게 보낼까요?',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
      ),
      Positioned(
        left: 28,
        right: 28,
        top: 285,
        height: 110,
        child: _AccountBox(account: account, onClear: onClear),
      ),
      Positioned(
        left: 28,
        right: 28,
        top: 413,
        height: 104,
        child: _BankBox(bank: bank, onTap: onChooseBank),
      ),
      if (bank != null)
        const Positioned(left: 28, top: 535, child: _BankChips()),
      Positioned(
        left: 47,
        right: 47,
        top: 782,
        height: 355,
        child: _NumericPad(
          prefix: 'account',
          showDoubleZero: false,
          onDigit: onDigit,
          onDelete: onDelete,
        ),
      ),
    ],
  );
}

class _AccountBox extends StatelessWidget {
  const _AccountBox({required this.account, required this.onClear});
  final String account;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('transfer-account-input'),
    padding: const EdgeInsets.fromLTRB(22, 18, 16, 12),
    decoration: BoxDecoration(
      border: Border.all(color: _blue, width: 3),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('계좌번호', style: TextStyle(color: _blue, fontSize: 16)),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                account.isEmpty ? '- 없이 숫자만 입력' : account,
                style: TextStyle(
                  fontSize: 23,
                  color: account.isEmpty ? _muted : _ink,
                ),
              ),
            ),
            if (account.isNotEmpty)
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  key: const Key('transfer-clear-account'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                  icon: const Icon(Icons.cancel, color: Color(0xFF949CAA)),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _BankBox extends StatelessWidget {
  const _BankBox({required this.bank, required this.onTap});
  final String? bank;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: const Key('transfer-bank-selector'),
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.centerLeft,
      side: const BorderSide(color: _line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '은행 또는 증권사 선택',
                style: TextStyle(color: _muted, fontSize: 16),
              ),
              Text(
                bank ?? '은행 또는 증권사 선택',
                style: TextStyle(
                  fontSize: bank == null ? 22 : 23,
                  color: bank == null ? _muted : _ink,
                  fontWeight: bank == null ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, color: _ink, size: 35),
      ],
    ),
  );
}

class _BankChips extends StatelessWidget {
  const _BankChips();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _TinyChip('신한', Color(0xFF0759D7)),
      SizedBox(width: 10),
      _TinyChip('케이뱅크', Color(0xFF1C168F)),
      SizedBox(width: 10),
      _TinyChip('토스뱅크', Color(0xFF347CF7)),
    ],
  );
}

class _TinyChip extends StatelessWidget {
  const _TinyChip(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    height: 43,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5FA),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Row(
      children: [
        Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}

class _AmountPage extends StatelessWidget {
  const _AmountPage({
    required this.sourceAccount,
    required this.bank,
    required this.account,
    required this.recipientName,
    required this.amount,
    required this.onDigit,
    required this.onDelete,
    required this.onChooseSourceAccount,
  });
  final _SourceAccount sourceAccount;
  final String bank, account;
  final String? recipientName;
  final int amount;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onChooseSourceAccount;
  @override
  Widget build(BuildContext context) {
    final entered = amount > 0;
    return Stack(
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 202,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                key: const Key('source-account-selector'),
                onTap: onChooseSourceAccount,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${sourceAccount.productName} 계좌에서',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipientName == null ? '아래 계좌로' : '$recipientName 계좌로',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                '$bank $account',
                style: const TextStyle(fontSize: 17, color: _muted),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 338,
          child: Column(
            children: [
              Text(
                entered ? '${_formatted(amount)}원' : '얼마를 보낼까요?',
                style: TextStyle(
                  fontSize: entered ? 42 : 38,
                  fontWeight: FontWeight.w700,
                  color: entered ? _ink : const Color(0xFF8C96A7),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                entered
                    ? '${_formatted(amount)}원'
                    : '출금가능금액 ${_formatted(sourceAccount.availableBalance)}원',
                style: const TextStyle(fontSize: 19, color: _muted),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 29,
          right: 29,
          top: 730,
          child: _AmountShortcuts(),
        ),
        Positioned(
          left: 47,
          right: 47,
          top: 845,
          height: 300,
          child: _NumericPad(
            prefix: 'amount',
            showDoubleZero: true,
            onDigit: onDigit,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }

  static String _formatted(int value) => value.toString().replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+$)'),
    (_) => ',',
  );
}

class _SourceAccount {
  const _SourceAccount({
    required this.id,
    required this.productName,
    required this.bankCode,
    required this.bank,
    required this.accountNumber,
    required this.availableBalance,
  });

  final String id;
  final String productName;
  final String bankCode;
  final String bank;
  final String accountNumber;
  final int availableBalance;

  String get logoAsset => BankCatalog.logoAsset(bankCode);
}

class _SourceAccountSelector extends StatelessWidget {
  const _SourceAccountSelector({
    required this.accounts,
    required this.selectedAccount,
    required this.onSelect,
    required this.onClose,
  });

  final List<_SourceAccount> accounts;
  final _SourceAccount selectedAccount;
  final ValueChanged<_SourceAccount> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('source-account-sheet'),
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('source-account-sheet-barrier'),
            onTap: onClose,
            child: const ColoredBox(color: Color(0x92535A65)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 490,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned(
                  left: 29,
                  top: 31,
                  child: Text(
                    '출금계좌 선택',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 24,
                  child: IconButton(
                    key: const Key('source-account-sheet-close'),
                    onPressed: onClose,
                    icon: const _TransferCloseIcon(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 102,
                  bottom: 0,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: accounts.length,
                    itemExtent: 194,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _SourceAccountOption(
                        account: account,
                        selected: account.id == selectedAccount.id,
                        onTap: () => onSelect(account),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceAccountOption extends StatelessWidget {
  const _SourceAccountOption({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final _SourceAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('source-account-option-${account.bank}-${account.accountNumber}'),
    onTap: onTap,
    child: ColoredBox(
      color: selected ? const Color(0xFFEAF1FF) : Colors.white,
      child: Stack(
        children: [
          Positioned(
            left: 28,
            top: 31,
            width: 54,
            height: 54,
            child: ClipRect(
              child: Transform.scale(
                scale: BankCatalog.logoScale(account.bankCode),
                child: Image.asset(account.logoAsset, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: 91,
            top: 31,
            right: 58,
            child: Text(
              account.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            left: 91,
            top: 67,
            child: Text(
              '${account.bank} ${account.accountNumber}',
              style: const TextStyle(fontSize: 18, color: _muted),
            ),
          ),
          if (selected)
            const Positioned(
              right: 31,
              top: 35,
              child: Icon(
                Icons.check_rounded,
                color: _blue,
                size: 29,
                weight: 700,
              ),
            ),
          Positioned(
            right: 30,
            bottom: 30,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 18, color: _muted),
                children: [
                  const TextSpan(text: '출금가능금액  '),
                  TextSpan(
                    text:
                        '${_AmountPage._formatted(account.availableBalance)}원',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              key: Key(
                'source-account-balance-${account.bank}-${account.accountNumber}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AmountShortcuts extends StatelessWidget {
  const _AmountShortcuts();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _AmountChip('+1만'),
      _AmountChip('+5만'),
      _AmountChip('+10만'),
      _AmountChip('전액'),
    ],
  );
}

class _AmountChip extends StatelessWidget {
  const _AmountChip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: 123,
    height: 47,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4F8),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    ),
  );
}

class _NumericPad extends StatelessWidget {
  const _NumericPad({
    required this.prefix,
    required this.showDoubleZero,
    required this.onDigit,
    required this.onDelete,
  });
  final String prefix;
  final bool showDoubleZero;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final values = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      if (showDoubleZero) '00' else '',
      '0',
    ];
    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: showDoubleZero ? 2.2 : 2,
      children: [
        ...values.map(
          (value) => TextButton(
            key: Key('$prefix-key-$value'),
            onPressed: value.isEmpty ? null : () => onDigit(value),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ),
        ),
        IconButton(
          key: Key('$prefix-delete'),
          onPressed: onDelete,
          icon: const Icon(Icons.backspace_outlined, size: 38),
        ),
      ],
    );
  }
}

class _BankSelectorDialog extends StatefulWidget {
  const _BankSelectorDialog({this.initialBank});
  final String? initialBank;
  @override
  State<_BankSelectorDialog> createState() => _BankSelectorDialogState();
}

class _BankSelectorDialogState extends State<_BankSelectorDialog> {
  bool securities = false;

  @override
  Widget build(BuildContext context) {
    final names = securities
        ? BankCatalog.securitiesCodes
        : BankCatalog.bankCodes;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.pop(context)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 129,
            bottom: 0,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 20, 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '은행 또는 증권사 선택',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('bank-selector-close'),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 35),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _BankTab(
                          label: '은행',
                          selected: !securities,
                          onTap: () => setState(() => securities = false),
                        ),
                        _BankTab(
                          label: '증권사',
                          selected: securities,
                          onTap: () => setState(() => securities = true),
                        ),
                      ],
                    ),
                    Expanded(
                      child: GridView.builder(
                        key: Key(
                          securities
                              ? 'bank-selector-list-securities'
                              : 'bank-selector-list-banks',
                        ),
                        padding: const EdgeInsets.fromLTRB(28, 29, 28, 34),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              // A fixed height makes the label safe at every
                              // device scale. The previous aspect-ratio grid
                              // could shrink each cell enough to overflow on
                              // Android when Korean text metrics were used.
                              mainAxisExtent: 138,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                            ),
                        itemCount: names.length,
                        itemBuilder: (_, i) => _BankTile(
                          name: names[i],
                          index: i,
                          onTap: () => Navigator.pop(context, names[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankTab extends StatelessWidget {
  const _BankTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      key: Key('bank-tab-$label'),
      onTap: onTap,
      child: Container(
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(0xFF667084)
                  : const Color(0xFFE3E5EA),
              width: selected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _ink : _muted,
          ),
        ),
      ),
    ),
  );
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.name,
    required this.index,
    required this.onTap,
  });
  final String name;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final asset = BankCatalog.tryLogoAsset(name);
    const colors = [
      Color(0xFF0959DD),
      Color(0xFF3979D8),
      Color(0xFF655642),
      Color(0xFF1476B4),
      Color(0xFF168653),
      Color(0xFF376C9D),
      Color(0xFF047BB9),
      Color(0xFF22669E),
    ];
    return InkWell(
      key: Key('bank-$name'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const SizedBox(height: 17),
            SizedBox(
              width: 50,
              height: 50,
              child: asset != null
                  ? ClipRect(
                      child: Transform.scale(
                        scale: BankCatalog.logoScale(name),
                        child: Image.asset(
                          asset,
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 11),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferReviewPage extends StatelessWidget {
  const _TransferReviewPage({required this.bank, required this.amount});

  final String bank;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final logoAsset = BankCatalog.tryLogoAsset(bank);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 226,
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8EDF5)),
              ),
              child: logoAsset == null
                  ? const Icon(
                      Icons.account_balance_rounded,
                      color: _blue,
                      size: 46,
                    )
                  : ClipRect(
                      child: Transform.scale(
                        scale: BankCatalog.logoScale(bank),
                        child: Image.asset(
                          logoAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 327,
          child: Text(
            '아래 계좌로\n${_AmountPage._formatted(amount)}원 보낼까요?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 31,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 444,
          child: Text(
            '수수료 무료',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransferConfirmation extends StatelessWidget {
  const _TransferConfirmation({required this.onConfirm});
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: Container(color: const Color(0x8B27303E))),
      Positioned(
        left: 34,
        right: 34,
        top: 503,
        height: 278,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 29,
                top: 47,
                child: Text(
                  'EEF90723',
                  style: TextStyle(fontSize: 20, color: Color(0xFFD6424B)),
                ),
              ),
              const Positioned(
                left: 29,
                right: 29,
                top: 123,
                child: Text(
                  '해당 계좌는 사고신고계좌로 거래가 불가합니다.',
                  style: TextStyle(fontSize: 18, color: Color(0xFF353C48)),
                ),
              ),
              Positioned(
                left: 29,
                right: 29,
                bottom: 28,
                height: 67,
                child: FilledButton(
                  key: const Key('transfer-error-confirm'),
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

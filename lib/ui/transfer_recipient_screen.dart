import 'package:flutter/material.dart';

import 'design_canvas.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF818A99);
const _line = Color(0xFFD9DDE5);
const _blue = Color(0xFF0969F6);

const _bankLogoAssets = <String, String>{
  '신한': 'assets/images/bank_shinhan_mock.png',
  '제주': 'assets/images/bank_jeju_mock.png',
  '국민': 'assets/images/bank_kb_mock.png',
  '기업': 'assets/images/bank_ibk_mock.png',
  '농협': 'assets/images/bank_nh_mock.png',
  '산업': 'assets/images/bank_kdb_mock.png',
  '수협': 'assets/images/bank_suhyup_mock.png',
  '신협': 'assets/images/bank_shinhyup_mock.png',
  '우리': 'assets/images/bank_woori_mock.png',
  '하나': 'assets/images/bank_hana_mock.png',
  '한국씨티': 'assets/images/bank_citi_mock.png',
  '카카오뱅크': 'assets/images/bank_kakao_mock.png',
  '케이뱅크': 'assets/images/bank_kbank_mock.png',
  '토스뱅크': 'assets/images/bank_toss_mock.png',
  '경남': 'assets/images/bank_kyongnam_mock.png',
  '광주': 'assets/images/bank_gwangju_mock.png',
  '아이엠뱅크(대구)': 'assets/images/bank_im_mock.png',
  '부산': 'assets/images/bank_busan_mock.png',
  '전북': 'assets/images/bank_jeonbuk_mock.png',
  '회원수협': 'assets/images/bank_membersuhyup_mock.png',
  '새마을': 'assets/images/bank_saemaul_mock.png',
  '우체국': 'assets/images/bank_post_mock.png',
  '저축은행': 'assets/images/bank_savings_mock.png',
  '지역농·축협': 'assets/images/bank_localnh_mock.png',
  '도이치': 'assets/images/bank_deutsche_mock.png',
  '중국': 'assets/images/bank_china_mock.png',
  '중국건설': 'assets/images/bank_ccb_mock.png',
  '중국공상': 'assets/images/bank_icbc_mock.png',
  'BNP파리바': 'assets/images/bank_bnp_mock.png',
  'BOA': 'assets/images/bank_boa_mock.png',
  'HSBC': 'assets/images/bank_hsbc_mock.png',
  'JP모간': 'assets/images/bank_jpmorgan_mock.png',
  'SC': 'assets/images/bank_sc_mock.png',
  '산림조합': 'assets/images/bank_forestry_mock.png',
  '국세': 'assets/images/bank_nationaltax_mock.png',
  '지방세': 'assets/images/bank_localtax_mock.png',
  '국고': 'assets/images/bank_treasury_mock.png',
  '관세': 'assets/images/bank_customs_mock.png',
};

enum _TransferStage { recipient, amount, confirmation }

class TransferRecipientScreen extends StatefulWidget {
  const TransferRecipientScreen({super.key});

  @override
  State<TransferRecipientScreen> createState() =>
      _TransferRecipientScreenState();
}

class _TransferRecipientScreenState extends State<TransferRecipientScreen> {
  _TransferStage _stage = _TransferStage.recipient;
  bool _manualEntry = false;
  String _account = '';
  String? _bank;
  int _amount = 0;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
  }

  bool get _canContinue => _account.isNotEmpty && _bank != null;

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
    setState(() {
      _bank = recipient.bank;
      _account = recipient.account;
      _stage = _TransferStage.amount;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              if (_stage != _TransferStage.recipient || !_manualEntry)
                _TopControls(onBack: _back),
              if (_stage == _TransferStage.confirmation)
                _TransferReviewPage(bank: _bank ?? '토스뱅크', amount: _amount)
              else if (_stage == _TransferStage.amount)
                _AmountPage(
                  bank: _bank ?? '토스뱅크',
                  account: _account.isEmpty ? '100237698805' : _account,
                  amount: _amount,
                  onDigit: _appendAmount,
                  onDelete: _deleteAmount,
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
                  onManual: () => setState(() => _manualEntry = true),
                  onSelect: _chooseRecipient,
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
                              ? null
                              : _canContinue
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
              if (_stage == _TransferStage.confirmation)
                _TransferConfirmation(
                  onConfirm: () =>
                      setState(() => _stage = _TransferStage.recipient),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 28,
        top: 103,
        child: IconButton(
          key: const Key('transfer-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
        ),
      ),
      Positioned(
        right: 24,
        top: 104,
        child: IconButton(
          key: const Key('transfer-home'),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close_rounded, size: 31),
        ),
      ),
    ],
  );
}

class _RecipientLanding extends StatelessWidget {
  const _RecipientLanding({required this.onManual, required this.onSelect});
  final VoidCallback onManual;
  final ValueChanged<_Recipient> onSelect;
  static const recipients = [
    _Recipient(
      'TRINH TRUN',
      '우리',
      '1002365702814',
      'assets/images/recipient_woori_mock.png',
    ),
    _Recipient(
      '정상희',
      '토스뱅크',
      '100265855542',
      'assets/images/recipient_toss_mock.png',
    ),
    _Recipient(
      '양기석(양화감자탕)',
      '하나',
      '63491065897607',
      'assets/images/recipient_hana_mock.png',
    ),
    _Recipient(
      'Npay',
      '신한',
      '56020228505759',
      'assets/images/recipient_shinhan_mock.png',
    ),
    _Recipient(
      'THANH_한패스',
      '전북',
      '9105205506132',
      'assets/images/recipient_jeonbuk_mock.png',
    ),
    _Recipient(
      'LE KIM CUC',
      '국민',
      '91800101463625',
      'assets/images/recipient_kb_mock.png',
    ),
    _Recipient(
      '황지환',
      '새마을',
      '9002162430854',
      'assets/images/recipient_saemaul_mock.png',
    ),
    _Recipient(
      'BUI PHUONG',
      '토스뱅크',
      '100263424344',
      'assets/images/recipient_toss2_mock.png',
    ),
  ];
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(
        left: 28,
        top: 188,
        child: Text(
          '누구에게 보낼까요?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
      ),
      Positioned(
        right: 26,
        top: 196,
        child: _SquareIcon(icon: Icons.search_rounded, onTap: () {}),
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
          onPressed: () {},
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
      const Positioned(
        right: 28,
        top: 375,
        child: _CountChip('0개', Icons.keyboard_arrow_down_rounded),
      ),
      const Positioned(
        left: 28,
        top: 461,
        child: Text(
          '최근',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      const Positioned(
        right: 28,
        top: 449,
        child: _CountChip('50개', Icons.keyboard_arrow_up_rounded),
      ),
      ...List.generate(
        recipients.length,
        (i) => Positioned(
          left: 28,
          right: 25,
          top: 515 + (i * 97),
          height: 78,
          child: _RecipientRow(
            recipient: recipients[i],
            onTap: () => onSelect(recipients[i]),
          ),
        ),
      ),
    ],
  );
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.onTap});
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
  const _CountChip(this.text, this.icon);
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
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
  );
}

class _Recipient {
  const _Recipient(this.name, this.bank, this.account, this.logoAsset);
  final String name, bank, account;
  final String logoAsset;
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({required this.recipient, required this.onTap});
  final _Recipient recipient;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('recipient-${recipient.name}'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Row(
      children: [
        Image.asset(
          recipient.logoAsset,
          width: 50,
          height: 50,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
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
        const Icon(
          Icons.star_border_rounded,
          size: 31,
          color: Color(0xFF657084),
        ),
      ],
    ),
  );
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
        top: 188,
        child: Text(
          '누구에게 보낼까요?',
          style: TextStyle(
            fontSize: 30,
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
    required this.bank,
    required this.account,
    required this.amount,
    required this.onDigit,
    required this.onDelete,
  });
  final String bank, account;
  final int amount;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
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
              const Text(
                '[금융거래한도계좌2]저축예금 계좌에서⌄',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '아래 계좌로',
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
                entered ? '${_formatted(amount)}원' : '출금가능금액 388,489원',
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
  static const banks = [
    '신한',
    '제주',
    '국민',
    '기업',
    '농협',
    '산업',
    '수협',
    '신협',
    '우리',
    '하나',
    '한국씨티',
    '카카오뱅크',
    '케이뱅크',
    '토스뱅크',
    '경남',
    '광주',
    '아이엠뱅크(대구)',
    '부산',
    '전북',
    '회원수협',
    '새마을',
    '우체국',
    '저축은행',
    '지역농·축협',
    '도이치',
    '중국',
    '중국건설',
    '중국공상',
    'BNP파리바',
    'BOA',
    'HSBC',
    'JP모간',
    'SC',
    '산림조합',
    '국세',
    '지방세',
    '국고',
    '관세',
  ];
  static const securitiesNames = [
    '교보증권',
    '대신증권',
    '미래에셋증권',
    '삼성증권',
    '신한투자증권',
    '키움증권',
  ];

  @override
  Widget build(BuildContext context) {
    final names = securities ? securitiesNames : banks;
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
                        key: const Key('bank-selector-list'),
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
    final asset = _bankLogoAssets[name]?.replaceFirst(
      '_mock.png',
      '_transparent.png',
    );
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
      child: SizedBox(
        height: 138,
        child: Column(
          children: [
            const SizedBox(height: 7),
            SizedBox(
              width: 52,
              height: 52,
              child: asset != null
                  ? Image.asset(
                      asset,
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.contain,
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
            const SizedBox(height: 10),
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
    final logoAsset = _bankLogoAssets[bank]?.replaceFirst(
      '_mock.png',
      '_transparent.png',
    );
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
                  : Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
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

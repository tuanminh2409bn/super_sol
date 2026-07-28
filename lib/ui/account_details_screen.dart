import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import 'design_canvas.dart';
import 'transfer_recipient_screen.dart';

const _detailsInk = Color(0xFF141820);
const _detailsMuted = Color(0xFF717887);
const _detailsBlue = Color(0xFF0068F5);
const _detailsDivider = Color(0xFFF1F4F8);

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({
    super.key,
    required this.auth,
    this.initialScrollOffset = 0,
  });

  final AuthService auth;
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
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    showDeviceStatusBar(
      darkIcons: true,
      backgroundColor: const Color(0xFFF0F3FA),
    );
    super.dispose();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TransferRecipientScreen()),
    );
    if (mounted) {
      showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountLabel = widget.auth.isSignedIn
        ? designDisplayName
        : 'TÀI KHOẢN';
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
                height: 1780,
                child: Stack(
                  children: [
                    _AccountSummary(onTransfer: _openTransferRecipient),
                    _TransactionList(accountName: accountLabel),
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
          _DetailsHeader(onBack: _goHome, onHome: _goHome),
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
  const _DetailsHeader({required this.onBack, required this.onHome});

  final VoidCallback onBack;
  final VoidCallback onHome;

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
          const Positioned(
            right: 85,
            top: 14,
            child: Text(
              '계좌관리',
              style: TextStyle(
                color: _detailsBlue,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -.8,
              ),
            ),
          ),
          Positioned(
            right: 25,
            top: 1,
            width: 50,
            height: 50,
            child: IconButton(
              key: const Key('account-home'),
              onPressed: onHome,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.home_outlined,
                size: 34,
                color: _detailsInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.onTransfer});

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
        const Positioned(
          left: 28,
          top: 245,
          width: 58,
          height: 58,
          child: Image(
            image: AssetImage('assets/images/shinhan_logo.png'),
            fit: BoxFit.fill,
          ),
        ),
        const Positioned(
          left: 91,
          top: 248,
          child: Text(
            '[금융거래한도계좌2]저축예금',
            style: TextStyle(
              color: Color(0xFF2D323C),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
          ),
        ),
        const Positioned(
          left: 91,
          top: 291,
          child: Text(
            '신한 110-628-103680',
            style: TextStyle(
              color: Color(0xFF454B57),
              fontSize: 18,
              letterSpacing: -.5,
            ),
          ),
        ),
        const Positioned(
          right: 29,
          top: 247,
          child: Icon(
            Icons.center_focus_weak_rounded,
            size: 32,
            color: _detailsInk,
          ),
        ),
        const Positioned(
          left: 28,
          top: 339,
          child: Text(
            '388,489원',
            style: TextStyle(
              color: _detailsInk,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const Positioned(
          left: 28,
          top: 389,
          child: Text(
            '출금가능금액 388,489원',
            style: TextStyle(
              color: _detailsMuted,
              fontSize: 18,
              letterSpacing: -.5,
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 432,
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
        const Positioned(
          left: 0,
          right: 0,
          top: 534,
          height: 15,
          child: ColoredBox(color: _detailsDivider),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.accountName});

  final String accountName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _FilterBar(top: 558),
        const Positioned(
          left: 28,
          top: 652,
          child: Text(
            '7월 22일',
            style: TextStyle(
              color: _detailsMuted,
              fontSize: 18,
              letterSpacing: -.6,
            ),
          ),
        ),
        _TransactionRow(
          top: 704,
          title: accountName,
          time: '10:32:08 · 모바일',
          amount: '-1,000원',
          balance: '388,489원',
        ),
        const _TransactionRow(
          top: 814,
          title: '정상희',
          time: '07:00:34 · 모바일',
          amount: '-6,100원',
          balance: '389,489원',
        ),
        const _TransactionRow(
          top: 924,
          title: '양기석(양화감자탕(',
          time: '01:34:45 · 모바일',
          amount: '-40,000원',
          balance: '395,589원',
        ),
        const Positioned(
          left: 28,
          right: 28,
          top: 1048,
          child: Divider(height: 1, color: Color(0xFFE8EBF0)),
        ),
        const Positioned(
          left: 28,
          top: 1090,
          child: Text(
            '7월 21일',
            style: TextStyle(
              color: _detailsMuted,
              fontSize: 18,
              letterSpacing: -.6,
            ),
          ),
        ),
        const _TransactionRow(
          top: 1138,
          title: 'Npay',
          time: '17:58:07 · 모바일',
          amount: '-104,700원',
          balance: '435,589원',
        ),
        const _TransactionRow(
          top: 1248,
          title: 'THANH_한패스',
          time: '16:30:45 · 모바일',
          amount: '-20,000원',
          balance: '540,289원',
        ),
        const _TransactionRow(
          top: 1358,
          title: 'LEKIMCUC',
          time: '01:36:21 · 타행모바일뱅킹',
          amount: '+200,000원',
          balance: '560,289원',
          positive: true,
        ),
        const _TransactionRow(
          top: 1468,
          title: 'LE KIM CUC',
          time: '00:06:10 · 모바일',
          amount: '-200,000원',
          balance: '360,289원',
        ),
        const Positioned(
          left: 28,
          right: 28,
          top: 1587,
          child: Divider(height: 1, color: Color(0xFFE8EBF0)),
        ),
        const Positioned(
          left: 28,
          top: 1626,
          child: Text(
            '7월 20일',
            style: TextStyle(
              color: _detailsMuted,
              fontSize: 18,
              letterSpacing: -.6,
            ),
          ),
        ),
      ],
    );
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
    required this.time,
    required this.amount,
    required this.balance,
    this.positive = false,
  });

  final double top;
  final String title;
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
                color: Color(0xFF333A46),
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
              time,
              style: const TextStyle(
                color: _detailsMuted,
                fontSize: 18,
                letterSpacing: -.5,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 49,
            child: Text(
              balance,
              style: const TextStyle(
                color: _detailsMuted,
                fontSize: 18,
                letterSpacing: -.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

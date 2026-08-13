import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_data.dart';
import '../core/auth_service.dart';
import '../core/data_bootstrap.dart';
import 'account_details_screen.dart';
import 'auth_sheet.dart';
import 'bank_logo.dart';
import 'design_canvas.dart';
import 'pin_screen.dart';
import 'transfer_recipient_screen.dart';

const _homeBackground = Color(0xFFF0F3FA);
const _ink = Color(0xFF151820);
const _muted = Color(0xFF555D69);
const _blue = Color(0xFF075FF7);
const _homeAccountLogoSize = 44.0;

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.auth,
    this.initialScrollOffset = 0,
    AppDataStore? dataStore,
  }) : dataStore = dataStore ?? AppDataStore.shared;

  final AuthService auth;
  final AppDataStore dataStore;
  final double initialScrollOffset;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _homeScroll;
  late double _scrollOffset;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: _homeBackground);
    _scrollOffset = widget.initialScrollOffset;
    _homeScroll = ScrollController(
      initialScrollOffset: widget.initialScrollOffset,
    );
    widget.dataStore.addListener(_handleDataChange);
    _homeScroll.addListener(() {
      final offset = _homeScroll.offset;
      if ((offset - _scrollOffset).abs() > 2 && mounted) {
        setState(() => _scrollOffset = offset);
      }
    });
  }

  @override
  void dispose() {
    widget.dataStore.removeListener(_handleDataChange);
    _homeScroll.dispose();
    super.dispose();
  }

  void _handleDataChange() {
    if (mounted) setState(() {});
  }

  Future<void> _scrollToContinuation() async {
    if (_homeScroll.hasClients) {
      await _homeScroll.animateTo(
        941,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openAccountDetails() async {
    final result = await Navigator.of(context).push<TransferFlowResult>(
      MaterialPageRoute<TransferFlowResult>(
        builder: (_) => AccountDetailsScreen(
          auth: widget.auth,
          dataStore: widget.dataStore,
          accountId: widget.dataStore.accounts.firstOrNull?.id,
        ),
      ),
    );
    if (mounted) {
      showDeviceStatusBar(darkIcons: true, backgroundColor: _homeBackground);
      if (result == TransferFlowResult.failed) {
        await showTransferFailurePopup(context);
      }
    }
  }

  Future<void> _showAccount() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final signedIn = widget.auth.isSignedIn;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DDE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Tài khoản',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  signedIn
                      ? '${widget.auth.displayName}님으로 로그인되어 있습니다.'
                      : 'Bạn đang xem ứng dụng ở chế độ khách.',
                  style: const TextStyle(color: Color(0xFF6F7684)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(signedIn ? 'logout' : 'login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: signedIn ? const Color(0xFF20242D) : _blue,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(signedIn ? 'Đăng xuất' : 'Đăng nhập / Đăng ký'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (action == 'login') {
      final authenticated = await showAuthSheet(context, auth: widget.auth);
      if (authenticated) {
        await initializeUserData(widget.auth, store: widget.dataStore);
      }
      if (mounted) setState(() {});
    } else if (action == 'logout') {
      await _logout();
    }
  }

  Future<void> _openTransferRecipient() async {
    final result = await Navigator.of(context).push<TransferFlowResult>(
      MaterialPageRoute<TransferFlowResult>(
        builder: (_) => TransferRecipientScreen(dataStore: widget.dataStore),
      ),
    );
    if (mounted) {
      showDeviceStatusBar(darkIcons: true, backgroundColor: _homeBackground);
      if (result == TransferFlowResult.failed) {
        await showTransferFailurePopup(context);
      }
    }
  }

  Future<void> _editHomeCardUsage() async {
    final draft = await showDialog<_HomeCardUsageDraft>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (_) => _HomeCardUsageDialog(
        initialMonth: widget.dataStore.homeCardMonth,
        initialAmount: widget.dataStore.homeCardAmount,
      ),
    );
    if (draft == null) return;
    await widget.dataStore.updateHomeCardUsage(
      month: draft.month,
      amount: draft.amount,
    );
  }

  Future<void> _logout() async {
    await widget.auth.signOut();
    await initializeUserData(widget.auth, store: widget.dataStore);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => PinScreen(auth: widget.auth)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = _scrollOffset >= 1000;
    final accountLabel = widget.auth.isSignedIn
        ? widget.auth.displayName
        : 'ĐĂNG NHẬP';
    final primaryAccount = widget.dataStore.accounts.firstOrNull;
    final mediaQuery = MediaQuery.of(context);
    final occupiedBottomInset = math.max(
      mediaQuery.viewPadding.bottom,
      mediaQuery.systemGestureInsets.bottom,
    );
    final canvasScale = math.min(
      mediaQuery.size.width / mockupWidth,
      mediaQuery.size.height / mockupHeight,
    );
    final bottomNavigationLift = occupiedBottomInset > 0
        ? occupiedBottomInset / canvasScale
        : 0.0;
    return DesignCanvas(
      backgroundColor: _homeBackground,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _homeBackground)),
          Positioned.fill(
            child: SingleChildScrollView(
              key: const Key('home-scroll'),
              controller: _homeScroll,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: mockupWidth,
                height: 2540 + bottomNavigationLift,
                child: Stack(
                  children: [
                    _AssetHomeContent(
                      accountName: accountLabel,
                      account: primaryAccount,
                      balance: primaryAccount == null
                          ? 0
                          : widget.dataStore.balanceFor(primaryAccount.id),
                      onOpenDetails: _openAccountDetails,
                      onTransfer: _openTransferRecipient,
                      cardMonth: widget.dataStore.homeCardMonth,
                      cardAmount: widget.dataStore.homeCardAmount,
                      onEditCardUsage: _editHomeCardUsage,
                    ),
                    const Positioned(
                      left: 0,
                      top: 941,
                      width: mockupWidth,
                      height: 1510,
                      child: _ServiceHomeContent(),
                    ),
                    if (widget.auth.isSignedIn)
                      Positioned(
                        right: 27,
                        top: 2310,
                        width: 141,
                        height: 38,
                        child: TextButton.icon(
                          key: const Key('home-logout'),
                          onPressed: _logout,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF555D6B),
                            backgroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                              side: const BorderSide(color: Color(0xFFDDE2EB)),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 17),
                          label: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!collapsed)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 185,
              child: ColoredBox(color: _homeBackground),
            ),
          if (!collapsed)
            _Header(
              accountName: accountLabel,
              onAccountTap: _showAccount,
              onSwitchHome: _scrollToContinuation,
            ),
          if (collapsed)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 181,
              child: ColoredBox(color: _homeBackground),
            ),
          _BottomNavigation(bottomLift: bottomNavigationLift),
        ],
      ),
    );
  }
}

class _AssetHomeContent extends StatelessWidget {
  const _AssetHomeContent({
    required this.accountName,
    required this.account,
    required this.balance,
    required this.onOpenDetails,
    required this.onTransfer,
    required this.cardMonth,
    required this.cardAmount,
    required this.onEditCardUsage,
  });

  final String accountName;
  final BankAccount? account;
  final int balance;
  final VoidCallback onOpenDetails;
  final VoidCallback onTransfer;
  final int cardMonth;
  final int cardAmount;
  final VoidCallback onEditCardUsage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 17,
          top: 185,
          width: 555,
          height: 251,
          child: GestureDetector(
            key: const Key('home-account-card'),
            behavior: HitTestBehavior.opaque,
            onTap: onOpenDetails,
            child: _WhiteCard(
              child: Stack(
                children: [
                  const Positioned(
                    left: 24,
                    top: 29,
                    child: Text(
                      '자산',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 28,
                    top: 37,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 22,
                      color: Color(0xFF818793),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 90,
                    width: _homeAccountLogoSize,
                    height: _homeAccountLogoSize,
                    child: account == null
                        ? const Icon(Icons.account_balance_rounded)
                        : BankLogo(
                            key: const Key('home-account-logo'),
                            bankCode: account!.bankCode,
                            size: _homeAccountLogoSize,
                          ),
                  ),
                  Positioned(
                    left: 75,
                    top: 82,
                    child: Text(
                      key: const Key('home-account-type'),
                      account?.accountType ?? '등록된 계좌가 없습니다',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4A5260),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 75,
                    top: 118,
                    child: Text(
                      key: const Key('home-account-balance'),
                      '${_formatHomeMoney(balance)}원',
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1,
                        color: Color(0xFF222731),
                        fontWeight: FontWeight.w500,
                        fontVariations: [FontVariation('wght', 520)],
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 21,
                    top: 93,
                    width: 66,
                    height: 45,
                    child: GestureDetector(
                      key: const Key('home-transfer'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onTransfer,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '이체',
                            style: TextStyle(
                              color: _blue,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 29,
                    height: 63,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFAFF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          '$accountName님의 금융생활, 슈퍼SOL이 함께합니다.',
                          style: const TextStyle(
                            color: Color(0xFF383E48),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 445,
          width: 555,
          height: 183,
          child: _WhiteCard(
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 3,
                  width: 52,
                  height: 80,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 1.08,
                      child: const Image(
                        key: Key('home-card-logo'),
                        image: AssetImage(
                          'assets/images/home_sol_global_card.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 64,
                  top: 24,
                  right: 24,
                  height: 63,
                  child: GestureDetector(
                    key: const Key('home-card-usage-edit'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onEditCardUsage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOL글로벌 체크(즉발)',
                          style: TextStyle(
                            fontSize: 25,
                            height: 1,
                            color: Color(0xFF303641),
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$cardMonth월 이용 금액 ${_formatHomeMoney(cardAmount)}원',
                          key: const Key('home-card-usage-value'),
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.25,
                            color: Color(0xFF626B7A),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 23,
                  right: 23,
                  bottom: 28,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        '앱카드 가입',
                        style: TextStyle(
                          fontSize: 20,
                          color: _blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 640,
          width: 555,
          height: 243,
          child: _WhiteCard(
            child: Stack(
              children: [
                const Positioned(
                  left: 27,
                  top: 22,
                  child: Text(
                    '땡겨요',
                    style: TextStyle(
                      fontSize: 29,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.3,
                    ),
                  ),
                ),
                const Positioned(
                  right: 29,
                  top: 35,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20,
                    color: Color(0xFF9298A3),
                  ),
                ),
                const Positioned(
                  left: 25,
                  top: 91,
                  width: 58,
                  height: 39,
                  child: Image(
                    image: AssetImage('assets/images/coupon_tight.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                const Positioned(
                  left: 85,
                  top: 77,
                  child: Text(
                    '할인 쿠폰 드려요',
                    style: TextStyle(
                      fontSize: 17,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Positioned(
                  left: 85,
                  top: 107,
                  child: Text(
                    'bhc치킨 최대 9,000원',
                    style: TextStyle(
                      fontSize: 25,
                      color: Color(0xFF2C313B),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 94,
                  width: 99,
                  height: 43,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Center(
                      child: Text(
                        '바로받기',
                        style: TextStyle(
                          fontSize: 17,
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 22,
                  right: 22,
                  bottom: 78,
                  child: Divider(height: 1, color: Color(0xFFF0F1F4)),
                ),
                const Positioned(
                  left: 54,
                  right: 54,
                  bottom: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('이벤트', style: _menuText),
                      Text('쿠폰', style: _menuText),
                      Text('포인트', style: _menuText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 899,
          width: 555,
          height: 179,
          child: _WhiteCard(
            child: Stack(
              children: [
                const Positioned(
                  left: 28,
                  top: 22,
                  child: Row(
                    children: [
                      Text(
                        '7월 소비 0원',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -1.2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.refresh_rounded,
                        size: 26,
                        color: Color(0xFF8A909C),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 27,
                  top: 23,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 21,
                    color: Color(0xFF8B919D),
                  ),
                ),
                const Positioned(
                  left: 28,
                  top: 86,
                  width: 56,
                  height: 61,
                  child: Image(
                    image: AssetImage('assets/images/calendar.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                const Positioned(
                  left: 84,
                  top: 82,
                  child: Text(
                    '오늘 쓴 돈',
                    style: TextStyle(
                      fontSize: 17,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Positioned(
                  left: 84,
                  top: 109,
                  child: Text(
                    '0원',
                    style: TextStyle(
                      fontSize: 27,
                      color: Color(0xFF343A45),
                      fontWeight: FontWeight.w700,
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
}

class _ServiceHomeContent extends StatelessWidget {
  const _ServiceHomeContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 39,
          top: 196,
          child: Text(
            'SOL LINK 계좌개설 이벤트\n(신한은행 X 신한투자증권)',
            style: TextStyle(
              color: Color(0xFF343944),
              fontSize: 24,
              height: 1.55,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),
        ),
        const Positioned(
          left: 40,
          top: 275,
          child: Row(
            children: [
              Text(
                '이벤트 확인하기',
                style: TextStyle(
                  color: _blue,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _blue),
            ],
          ),
        ),
        const Positioned(
          left: 432,
          top: 191,
          width: 128,
          height: 133,
          child: Image(
            image: AssetImage('assets/images/tesla.png'),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned(
          left: 22,
          top: 349,
          width: 545,
          height: 125,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4B86FF), Color(0xFF7192E6)],
              ),
              borderRadius: BorderRadius.circular(34),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 24,
                  top: 30,
                  width: 59,
                  height: 62,
                  child: Image(
                    image: AssetImage('assets/images/point_circle.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                const Positioned(
                  left: 89,
                  top: 27,
                  child: Text(
                    '마이신한포인트',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Positioned(
                  left: 89,
                  top: 61,
                  child: Text(
                    '53P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      height: 1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Positioned(
                  right: 21,
                  top: 39,
                  width: 82,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B6FEB),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .22),
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Center(
                      child: Text(
                        '모으기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 487,
          width: 555,
          height: 357,
          child: _WhiteCard(
            child: Stack(
              children: [
                const Positioned(
                  left: 27,
                  top: 28,
                  child: Text(
                    '추천서비스',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const Positioned(
                  right: 29,
                  top: 32,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20,
                    color: Color(0xFF8A909D),
                  ),
                ),
                const _ServiceRow(
                  top: 83,
                  image: 'assets/images/service_family.png',
                  title: 'SOL패밀리',
                  subtitle: 'NEW · 가족과 함께하는 금융생활',
                  subtitleLeadRed: true,
                ),
                const _ServiceRow(
                  top: 171,
                  image: 'assets/images/service_salary.png',
                  title: '급여클럽+',
                  subtitle: '급여이체 우대 혜택',
                  pinned: true,
                ),
                const _ServiceRow(
                  top: 260,
                  image: 'assets/images/service_card.png',
                  title: '내 카드 승인내역',
                  subtitle: '모든 카드 실시간 승인내역',
                  pinned: true,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 856,
          width: 555,
          height: 345,
          child: _WhiteCard(
            child: Stack(
              children: [
                const Positioned(
                  left: 28,
                  top: 29,
                  child: Text(
                    '신한금융그룹',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const _GroupRow(
                  top: 86,
                  image: 'assets/images/group_card.png',
                  title: '신한카드',
                  subtitle: '나에게 맞는 카드 찾기',
                ),
                const _GroupRow(
                  top: 166,
                  image: 'assets/images/group_invest.png',
                  title: '신한투자증권',
                  subtitle: '지금 뜨는 주식 보러가기',
                ),
                const _GroupRow(
                  top: 246,
                  image: 'assets/images/group_life.png',
                  title: '신한라이프',
                  subtitle: '내게 필요한 보험, 보장분석으로 확인하기',
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 68,
          right: 68,
          top: 1238,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('쉬운홈', style: _footerText),
              SizedBox(
                height: 20,
                child: VerticalDivider(width: 1, color: Color(0xFFDCE0E8)),
              ),
              Text('홈화면 설정', style: _footerText),
              SizedBox(
                height: 20,
                child: VerticalDivider(width: 1, color: Color(0xFFDCE0E8)),
              ),
              Text('금액 숨기기', style: _footerText),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.accountName,
    required this.onAccountTap,
    required this.onSwitchHome,
  });

  final String accountName;
  final VoidCallback onAccountTap;
  final VoidCallback onSwitchHome;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 28,
      right: 25,
      top: 115,
      height: 70,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 2,
            width: 34,
            height: 36,
            child: GestureDetector(
              onTap: onAccountTap,
              child: const Image(
                image: AssetImage('assets/images/profile_badge.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 3,
            width: 285,
            height: 67,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAccountTap,
              child: Text.rich(
                key: const Key('home-account-name'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: accountName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontVariations: [FontVariation('wght', 550)],
                      ),
                    ),
                    if (accountName != 'ĐĂNG NHẬP')
                      const TextSpan(
                        text: '님',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontSize: 23,
                  color: Color(0xFF11141B),
                  letterSpacing: -.3,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 330,
            top: 0,
            width: 39,
            height: 42,
            child: Image(
              image: AssetImage('assets/images/header_chat.png'),
              fit: BoxFit.fill,
            ),
          ),
          const Positioned(
            left: 386,
            top: 0,
            width: 40,
            height: 42,
            child: Image(
              image: AssetImage('assets/images/header_wallet.png'),
              fit: BoxFit.fill,
            ),
          ),
          const Positioned(
            left: 441,
            top: 0,
            width: 40,
            height: 43,
            child: Image(
              image: AssetImage('assets/images/header_bell.png'),
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 498,
            top: 0,
            width: 41,
            height: 43,
            child: GestureDetector(
              key: const Key('home-switch'),
              behavior: HitTestBehavior.opaque,
              onTap: onSwitchHome,
              child: const Image(
                image: AssetImage('assets/images/header_search.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: child,
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.top,
    required this.image,
    required this.title,
    required this.subtitle,
    this.subtitleLeadRed = false,
    this.pinned = false,
  });

  final double top;
  final String image;
  final String title;
  final String subtitle;
  final bool subtitleLeadRed;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 22,
      right: 25,
      top: top,
      height: 78,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 72,
            height: 77,
            child: Image(image: AssetImage(image), fit: BoxFit.fill),
          ),
          Positioned(
            left: 83,
            top: 5,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF343943),
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          Positioned(
            left: 83,
            top: 42,
            child: subtitleLeadRed
                ? const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'NEW',
                          style: TextStyle(color: Color(0xFFFF4455)),
                        ),
                        TextSpan(
                          text: ' · 가족과 함께하는 금융생활',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 17, letterSpacing: -.6),
                  )
                : Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.6,
                    ),
                  ),
          ),
          if (pinned)
            const Positioned(
              right: 0,
              top: 23,
              child: Icon(
                Icons.push_pin_outlined,
                size: 28,
                color: Color(0xFF8A94A4),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.top,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final double top;
  final String image;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 28,
      top: top,
      height: 72,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            width: 48,
            height: 61,
            child: Image(image: AssetImage(image), fit: BoxFit.fill),
          ),
          Positioned(
            left: 60,
            top: 0,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF343943),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          Positioned(
            left: 60,
            top: 36,
            child: Text(
              subtitle,
              style: const TextStyle(
                color: _muted,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -.6,
              ),
            ),
          ),
          const Positioned(
            right: 0,
            top: 18,
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 21,
              color: Color(0xFF8B92A0),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.bottomLift});

  final double bottomLift;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const Key('home-bottom-navigation'),
      left: 27,
      bottom: 42 + bottomLift,
      width: 535,
      height: 90,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: const Color(0xFFE9EDF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4B5568),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavigationItem(
                label: '홈',
                selected: true,
                icon: Icon(Icons.home_rounded),
              ),
              _BottomNavigationItem(label: '금융', icon: _WonIcon()),
              _BottomNavigationItem(
                label: '상품',
                icon: Icon(Icons.shopping_bag_rounded),
              ),
              _BottomNavigationItem(
                label: '혜택',
                icon: Icon(Icons.card_giftcard_rounded),
              ),
              _BottomNavigationItem(
                label: '주식',
                icon: Icon(Icons.insert_chart_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final Widget icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0874EF) : const Color(0xFF646C7A);
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: color, size: 31),
            child: icon,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              height: 1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _WonIcon extends StatelessWidget {
  const _WonIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF8B94A4),
        shape: BoxShape.circle,
      ),
      child: const Text(
        '₩',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const _menuText = TextStyle(
  color: Color(0xFF20242D),
  fontSize: 17,
  fontWeight: FontWeight.w600,
);

const _footerText = TextStyle(
  color: Color(0xFF313641),
  fontSize: 18,
  fontWeight: FontWeight.w600,
);

class _HomeCardUsageDraft {
  const _HomeCardUsageDraft({required this.month, required this.amount});

  final int month;
  final int amount;
}

class _HomeCardUsageDialog extends StatefulWidget {
  const _HomeCardUsageDialog({
    required this.initialMonth,
    required this.initialAmount,
  });

  final int initialMonth;
  final int initialAmount;

  @override
  State<_HomeCardUsageDialog> createState() => _HomeCardUsageDialogState();
}

class _HomeCardUsageDialogState extends State<_HomeCardUsageDialog> {
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController(
      text: widget.initialMonth.toString(),
    );
    _amountController = TextEditingController(
      text: _formatHomeMoney(widget.initialAmount),
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final month = int.tryParse(
      _monthController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (month == null || month < 1 || month > 12) {
      setState(() => _error = 'Tháng phải nằm trong khoảng từ 1 đến 12.');
      return;
    }
    if (amount == null || amount < 0) {
      setState(() => _error = 'Số tiền phải là số hợp lệ từ 0 trở lên.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_HomeCardUsageDraft(month: month, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Chỉnh thông tin thẻ',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('home-card-month-field'),
            controller: _monthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tháng hiển thị',
              suffixText: '월',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('home-card-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền sử dụng',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('home-card-usage-error'),
              style: const TextStyle(color: Color(0xFFD92D45), fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('home-card-usage-save'),
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

String _formatHomeMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?<!^)(?=(\d{3})+$)'),
  (_) => ',',
);

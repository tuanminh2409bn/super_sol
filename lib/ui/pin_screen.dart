import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import '../core/data_bootstrap.dart';
import '../core/pin_security.dart';
import 'auth_sheet.dart';
import 'design_canvas.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

enum _AccessPinMode { loading, legacy, verify, create, confirm }

class _PinScreenState extends State<PinScreen> {
  static const _initialKeypadDigits = <int>[8, 9, 7, 1, 5, 0, 2, 6, 4, 3];
  static const _keypadPositions = <Offset>[
    Offset(52, 10),
    Offset(248, 10),
    Offset(444, 10),
    Offset(52, 100),
    Offset(248, 100),
    Offset(444, 100),
    Offset(52, 190),
    Offset(248, 190),
    Offset(444, 190),
    Offset(248, 280),
  ];

  final List<int> _digits = [];
  final List<int> _keypadDigits = List<int>.of(_initialKeypadDigits);
  bool _navigating = false;
  bool _busy = false;
  _AccessPinMode _mode = _AccessPinMode.loading;
  String? _pendingPin;
  String? _setupError;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
    unawaited(_loadPinState());
  }

  void _addDigit(int digit) {
    if (_digits.length == 6 || _navigating || _busy || _inputLocked) return;
    setState(() => _digits.add(digit));
    if (_digits.length == 6) {
      Future<void>.delayed(const Duration(milliseconds: 150), _submitPin);
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty || _navigating || _busy || _inputLocked) return;
    setState(() => _digits.removeLast());
  }

  void _shuffle() {
    if (_busy || _inputLocked) return;
    setState(() {
      final previousOrder = List<int>.of(_keypadDigits);
      _keypadDigits.shuffle();
      final orderDidNotChange = List.generate(
        _keypadDigits.length,
        (index) => _keypadDigits[index] == previousOrder[index],
      ).every((matches) => matches);
      if (orderDidNotChange) {
        final first = _keypadDigits[0];
        _keypadDigits[0] = _keypadDigits[1];
        _keypadDigits[1] = first;
      }
    });
  }

  bool get _inputLocked =>
      _mode == _AccessPinMode.loading ||
      (_mode == _AccessPinMode.verify &&
          _failedAttempts >= PinSecurityService.maxAttempts);

  String get _enteredPin => _digits.join();

  String get _title => switch (_mode) {
    _AccessPinMode.create => '신한인증서 비밀번호를\n설정해주세요',
    _AccessPinMode.confirm => '비밀번호를 다시\n입력해주세요',
    _ => '신한인증서 비밀번호를\n입력해주세요',
  };

  String? get _errorMessage {
    if (_setupError != null) return _setupError;
    if (_mode != _AccessPinMode.verify || _failedAttempts == 0) return null;
    return '비밀번호가 일치하지 않아요. ($_failedAttempts/${PinSecurityService.maxAttempts})';
  }

  Future<void> _loadPinState() async {
    if (!widget.auth.isSignedIn) {
      if (mounted) setState(() => _mode = _AccessPinMode.legacy);
      return;
    }
    final status = await widget.auth.pinStatus(PinPurpose.appAccess);
    if (!mounted) return;
    setState(() {
      _digits.clear();
      _pendingPin = null;
      _setupError = null;
      _failedAttempts = status.failedAttempts;
      _mode = status.configured ? _AccessPinMode.verify : _AccessPinMode.create;
    });
  }

  Future<void> _submitPin() async {
    if (!mounted || _busy || _digits.length != 6) return;
    final pin = _enteredPin;
    switch (_mode) {
      case _AccessPinMode.loading:
        return;
      case _AccessPinMode.legacy:
        _openHome();
        return;
      case _AccessPinMode.create:
        setState(() {
          _pendingPin = pin;
          _digits.clear();
          _setupError = null;
          _mode = _AccessPinMode.confirm;
        });
        return;
      case _AccessPinMode.confirm:
        if (_pendingPin != pin) {
          setState(() {
            _digits.clear();
            _setupError = '비밀번호가 일치하지 않아요. 다시 입력해주세요.';
          });
          return;
        }
        setState(() => _busy = true);
        await widget.auth.setPin(PinPurpose.appAccess, pin);
        if (!mounted) return;
        _openHome();
        return;
      case _AccessPinMode.verify:
        setState(() => _busy = true);
        final result = await widget.auth.verifyPin(PinPurpose.appAccess, pin);
        if (!mounted) return;
        if (result.matched) {
          _openHome();
          return;
        }
        setState(() {
          _busy = false;
          _digits.clear();
          _failedAttempts = result.failedAttempts;
        });
    }
  }

  Future<void> _resetPin() async {
    if (_busy || !widget.auth.isSignedIn) return;
    final authenticated = await showFirebaseReauthenticationSheet(
      context,
      auth: widget.auth,
    );
    if (!authenticated || !mounted) return;
    setState(() => _busy = true);
    await widget.auth.clearPin(PinPurpose.appAccess);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _digits.clear();
      _pendingPin = null;
      _setupError = null;
      _failedAttempts = 0;
      _mode = _AccessPinMode.create;
    });
  }

  Future<void> _goBack() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // PIN is normally reached through a replacement route from splash, so
    // there may be no previous route to reveal. In that case return to the
    // available login-method picker instead of attempting an invalid pop.
    await _chooseLoginMethod();
  }

  void _openHome() {
    if (!mounted || _navigating) return;
    _navigating = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, secondaryAnimation) =>
            HomeScreen(auth: widget.auth),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _chooseLoginMethod() async {
    final authenticated = await showAuthSheet(context, auth: widget.auth);
    if (authenticated && mounted) {
      await initializeUserData(widget.auth);
      await _loadPinState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // DesignCanvas intentionally keeps the 589 × 1280 artwork inside the
        // Android safe content area. The PIN keypad, however, is a full-bleed
        // panel in the reference app. Paint its blue surface behind the
        // canvas so it reaches both screen edges without covering Android's
        // persistent system navigation bar.
        final scale = math.min(
          constraints.maxWidth / mockupWidth,
          constraints.maxHeight / mockupHeight,
        );
        final canvasHeight = mockupHeight * scale;
        final canvasTop = (constraints.maxHeight - canvasHeight) / 2;
        final keypadTop = canvasTop + (829 * scale);

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            Positioned(
              left: 0,
              right: 0,
              top: keypadTop,
              bottom: 0,
              child: const ColoredBox(color: Color(0xFF005CF9)),
            ),
            DesignCanvas(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: 829,
                    child: ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: 25,
                    top: 104,
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('pin-back'),
                      onPressed: _goBack,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 25,
                        color: Color(0xFF303641),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 100,
                    right: 100,
                    top: 276,
                    height: 110,
                    child: Center(
                      child: Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF11141C),
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          letterSpacing: -1.7,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 139,
                    top: 422,
                    width: 312,
                    height: 34,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final active = index < _digits.length;
                        final focused = index == _digits.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? const Color(0xFF0567F6)
                                : Colors.white,
                            border: Border.all(
                              color: focused
                                  ? const Color(0xFF0071F4)
                                  : const Color(0xFF8B919D),
                              width: focused ? 3 : 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_errorMessage case final message?)
                    Positioned(
                      key: const Key('app-pin-error'),
                      left: 70,
                      right: 70,
                      top: 482,
                      height: 45,
                      child: Center(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFE33232),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            fontVariations: [FontVariation('wght', 500)],
                            letterSpacing: -.7,
                          ),
                        ),
                      ),
                    ),
                  if (_mode == _AccessPinMode.verify && _failedAttempts > 0)
                    Positioned(
                      left: 204,
                      top: 735,
                      width: 181,
                      height: 58,
                      child: FilledButton(
                        key: const Key('app-pin-reset'),
                        onPressed: _busy ? null : _resetPin,
                        style: FilledButton.styleFrom(
                          foregroundColor: const Color(0xFF111827),
                          backgroundColor: const Color(0xFFF3F6FA),
                          disabledBackgroundColor: const Color(0xFFF3F6FA),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          '비밀번호 재설정',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.6,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    top: 829,
                    right: 0,
                    bottom: 0,
                    child: Stack(
                      children: [
                        for (
                          var index = 0;
                          index < _keypadDigits.length;
                          index++
                        )
                          _Key(
                            key: Key('app-pin-key-${_keypadDigits[index]}'),
                            x: _keypadPositions[index].dx,
                            y: _keypadPositions[index].dy,
                            label: '${_keypadDigits[index]}',
                            onTap: () => _addDigit(_keypadDigits[index]),
                          ),
                        Positioned(
                          left: 50,
                          top: 284,
                          width: 96,
                          height: 54,
                          child: TextButton(
                            key: const Key('app-pin-rearrange'),
                            onPressed: _shuffle,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '재배열',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 457,
                          top: 285,
                          width: 67,
                          height: 51,
                          child: IconButton(
                            key: const Key('app-pin-delete'),
                            onPressed: _removeDigit,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.backspace_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 150,
                          top: 357,
                          width: 290,
                          height: 50,
                          child: TextButton(
                            onPressed: _chooseLoginMethod,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '로그인 방법 다시 선택',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -.3,
                                    shadows: _bluePanelTextStroke,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 21,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.x,
    required this.y,
    required this.label,
    required this.onTap,
  });

  final double x;
  final double y;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: 94,
      height: 65,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

const _bluePanelTextStroke = <Shadow>[
  Shadow(color: Colors.white, offset: Offset(.55, 0)),
  Shadow(color: Colors.white, offset: Offset(-.55, 0)),
  Shadow(color: Colors.white, offset: Offset(0, .55)),
  Shadow(color: Colors.white, offset: Offset(0, -.55)),
];

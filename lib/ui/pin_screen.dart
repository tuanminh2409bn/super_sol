import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import 'auth_sheet.dart';
import 'design_canvas.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<int> _digits = [];
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(darkIcons: true, backgroundColor: Colors.white);
  }

  void _addDigit(int digit) {
    if (_digits.length == 6 || _navigating) return;
    setState(() => _digits.add(digit));
    if (_digits.length == 6) {
      Future<void>.delayed(const Duration(milliseconds: 150), _openHome);
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty || _navigating) return;
    setState(() => _digits.removeLast());
  }

  void _shuffle() {
    setState(_digits.clear);
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
      _openHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          const Positioned(
            left: 100,
            right: 100,
            top: 276,
            height: 110,
            child: Center(
              child: Text(
                '신한인증서 비밀번호를\n입력해주세요',
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
                    color: active ? const Color(0xFF0567F6) : Colors.white,
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
          Positioned(
            left: 0,
            top: 829,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: const Color(0xFF005CF9),
              child: Stack(
                children: [
                  _Key(x: 52, y: 10, label: '8', onTap: () => _addDigit(8)),
                  _Key(x: 248, y: 10, label: '9', onTap: () => _addDigit(9)),
                  _Key(x: 444, y: 10, label: '7', onTap: () => _addDigit(7)),
                  _Key(x: 52, y: 100, label: '1', onTap: () => _addDigit(1)),
                  _Key(x: 248, y: 100, label: '5', onTap: () => _addDigit(5)),
                  _Key(x: 444, y: 100, label: '0', onTap: () => _addDigit(0)),
                  _Key(x: 52, y: 190, label: '2', onTap: () => _addDigit(2)),
                  _Key(x: 248, y: 190, label: '6', onTap: () => _addDigit(6)),
                  _Key(x: 444, y: 190, label: '4', onTap: () => _addDigit(4)),
                  _Key(x: 248, y: 280, label: '3', onTap: () => _addDigit(3)),
                  Positioned(
                    left: 50,
                    top: 284,
                    width: 96,
                    height: 54,
                    child: TextButton(
                      onPressed: _shuffle,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        '재배열',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          shadows: _bluePanelTextStroke,
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
                          Icon(Icons.keyboard_arrow_down_rounded, size: 21),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
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
            fontWeight: FontWeight.w500,
            height: 1,
            shadows: _bluePanelTextStroke,
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

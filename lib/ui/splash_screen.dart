import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import 'design_canvas.dart';
import 'pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.auth, this.autoContinue = true});

  final AuthService auth;
  final bool autoContinue;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    showDeviceStatusBar(
      darkIcons: false,
      backgroundColor: const Color(0xFF0046FE),
    );
    if (widget.autoContinue) {
      _timer = Timer(const Duration(milliseconds: 1350), _continue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 230),
        pageBuilder: (_, animation, secondaryAnimation) =>
            PinScreen(auth: widget.auth),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _continue,
      child: const DesignCanvas(
        backgroundColor: Color(0xFF0046FE),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Color(0xFF0046FE))),
            Positioned(
              left: 211,
              top: 560,
              width: 175,
              height: 174,
              child: Image(
                image: AssetImage('assets/images/brand_logo.png'),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
